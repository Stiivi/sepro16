//
//  Engine.swift
//  AgentFarms
//
//  Created by Stefan Urbanek on 02/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//


/**
    Simulation engine interface
*/
public protocol Engine {

    var model:Model { get }

    /**
     Run simulation for `steps` number of steps.

     If a trap occurs during the execution the delegate will be notified
     and the simulation run will be stopped.
     
     If `HALT` action was encountered, the simulation is terminated and
     can not be resumed unless re-initialized.
     */
    func run(steps:Int)
    var stepCount:Int { get }

    var store:Store { get }

    /** Initialize the store with `world`. If `world` is not specified then
    `main` is used.
    */
    func initialize(world: Symbol) throws

    /** Instantiate concept `name`.
     - Returns: reference to the newly created object
     */
    // TODO: move to engine, change this to add(object)
    func instantiate(name: Symbol) throws -> ObjectRef

}

// MARK: Selection Generator

// TODO: make this a protocol, since we can't expose our internal
// implementation of object

public protocol EngineDelegate {
    func willRun(engine: Engine)
    func didRun(engine: Engine)
    func willStep(engine: Engine)
    func didStep(engine: Engine)

    func handleTrap(engine: Engine, traps: CountedSet<Symbol>)
    func handleHalt(engine: Engine)
}

/**
    SimpleEngine – simple implementation of computational engine. Performs
    computations of simulation steps, captures traps and observes probe values.
*/

public final class SimpleEngine: Engine {
    /// Current step
    public var stepCount = 0

    /// Simulation state instance
    public var store: Store

    /// Traps caught in the last step
    public var traps = CountedSet<Symbol>()

    /// Flag saying whether the simulation is halted or not.
    public var isHalted: Bool = false

    // Probing
    // -------

    /// List of probes
    public var probes: [Probe]

    /// Logging delegate – an object that implements the `Logger`
    /// protocol
    public var logger: Logger? = nil

    /// Delegate for handling traps, halt and other events
    public var delegate: EngineDelegate? = nil


    /// Simulation model
    public let model: Model

    /// Create an object instance from concept
    public init(model:Model, store: Store?=nil){
        self.store = store ?? Store()
        self.model = model

        self.probes = [Probe]()
    }

    /// Runs the simulation for `steps`.
    public func run(steps:Int) {
        if self.logger != nil {
            self.logger!.loggingWillStart(self.model.measures, steps: steps)
            // TODO: this should be called only on first run
            self.probe()
        }
        
        self.delegate?.willRun(self)
        var stepsRun = 0

        for _ in 1...steps {

            self.step()

            if self.isHalted {
                self.delegate?.handleHalt(self)
                break
            }

            stepsRun += 1
        }

        self.logger?.loggingDidEnd(stepsRun)
    }

    /**
        Compute one step of the simulation by evaluating all actuators.
    */
    func step() {
        self.traps.removeAll()

        stepCount += 1

        self.delegate?.willStep(self)

        // >>>
        // The main step...
        self.model.actuators.shuffle().forEach(self.perform)
        // <<<

        self.delegate?.didStep(self)

        if self.logger != nil {
            self.probe()
        }

        if !self.traps.isEmpty {
            self.delegate?.handleTrap(self, traps: self.traps)
        }
    }

    /**
     Probe the simulation and pass the results to the logger. Probing
     is ignored when logger is not provided.

     - Complexity: O(n) – does full scan on all objects
     */
    func probe() {
        var record = ProbeRecord()

        // Nothing to probe if we have no logger
        if self.logger == nil {
            return
        }

        // Create the probes
        let probeList = self.model.measures.map {
            measure in
            (measure, createProbe(measure))
        }

        // TODO: too complex
        self.store.select().forEach {
            object in
            probeList.forEach {
                measure, probe in
                if self.store.predicatesMatch(measure.predicates, ref: object.id) {
                    probe.probe(object)
                }
            }
        }

        // Gather the probe results
        // TODO: replace this with Array<tuple> -> Dictionary
        probeList.forEach {
            measure, probe in
            record[measure.name] = probe.value
        }

        self.logger!.logRecord(self.stepCount, record: record)
    }

    /**
        Dispatch an `actuator` – unary vs. combined
     */
    func perform(actuator:Actuator){
        // TODO: take into account Actuator.isRoot as cartesian
        if actuator.isCombined {
            self.performCombined(actuator.selector,
                otherSelector: actuator.combinedSelector!,
                actuator: actuator)
        }
        else {
            self.performUnary(actuator.selector, actuator: actuator)
        }

        // TODO: This is not good, this should be in "perform"
        if actuator.traps != nil {
            actuator.traps!.forEach {
                trap in
                self.traps.add(trap)
            }
        }

        // TODO: handle 'ONCE'
        // TODO: maybe handle similar way as traps
        if actuator.notifications != nil {
            actuator.notifications!.forEach {
                notification in
                self.notify(notification)
            }
        }

        self.isHalted = actuator.doesHalt
    }

    /**
    Interactive actuator execution.

    Algorithm:

    1. Find objects matching conditions for `this`
    2. Find objects matching conditions for `other`
    3. If any of the sets is empty, don't perform anything – there is
       no reaction
    4. Perform reactive action on the objects.

    - Complexity: O(n) - performs full scan
    */
    func performUnary(selector: Selector, actuator: Actuator) {
        let objects = self.store.select(selector)

        for this in objects {
            // Check for required slots
            if !actuator.modifiers.all({ self.canApply($0, this: this) }) {
                continue
            }

            actuator.modifiers.forEach {
                modifier in
                self.applyModifier(modifier, this: this)
            }
        }

    }

    /**
    - Complexity: O(n^2) - performs cartesian product on two full scans
    */

    func performCombined(thisSelector: Selector, otherSelector: Selector,
        actuator: Actuator) {

        let thisObjects = self.store.select(thisSelector)
        let otherObjects = self.store.select(otherSelector)

        var match: Bool

        // Cartesian product: everything 'this' interacts with everything
        // 'other'
        // Note: We can't use forEach, as there is no way to break from the loop
        for this in thisObjects {
            // Check for required slots
            for other in otherObjects {
                // Check for required slots
                if !actuator.modifiers.all({ self.canApply($0, this: this, other: other) }) {
                    continue
                }
                if this.id == other.id {
                    continue
                }

                actuator.modifiers.forEach {
                    modifier in
                    self.applyModifier(modifier, this: this, other: other)
                }

                // Check whether 'this' still matches the predicates
                match = thisSelector == Selector.All ||
                        store.predicatesMatch(thisSelector.predicates, ref: this.id)
                // ... predicates don't match the object, therefore we
                // skip to the next one
                if !match {
                    break
                }
            }
        }

    }

    /**
        Get "current" object – choose between ROOT, THIS and OTHER then
    optionally apply dereference to a slot, if specified.
    */
    func getCurrent(ref: ModifierTarget, this: Object, other: Object?=nil) -> Object? {
        let current: Object

        switch ref.type {
        case .Root:
            // Is guaranteed to exist by specification
            current = self.store.getRoot()
        case .This:
            // Is guaranteed to exist by argument
            current = this
        case .Other:
            // Exists only in combined selectors
            assert(other != nil, "Required `other` for .Other target reference")
            current = other!
        }

        if ref.slot == nil {
            return current
        }
        else {
            assert(current.slots.contains(ref.slot!), "Target sohuld contain slot '\(ref.slot!)'")
            if let indirect = current.bindings[ref.slot!] {
                return self.store[indirect]!
            }
            else {
                // Nothing bound at the slot
                return nil
            }

        }
    }

    /// - Returns: `true` if the `modifier` can be applied, otherwise `false`
    func canApply(modifier:Modifier, this:Object, other:Object!=nil) -> Bool {
        let current = self.getCurrent(modifier.target, this: this, other: other)

        switch modifier.action {
        case .Inc(let counter):
            return current?.counters.keys.contains(counter) ?? false

        case .Dec(let counter):
            return current?.counters.keys.contains(counter) ?? false

        case .Clear(let counter):
            return current?.counters.keys.contains(counter) ?? false

        case .Bind(let slot, let targetRef):
            let target = self.getCurrent(targetRef, this: this, other: other)

            if current == nil || target == nil {
                // There is nothing to bind
                // TODO: Should be consider assigning nil as 'unbind' or as failure?
                return false
            }

            return current?.slots.contains(slot) ?? false

        case .Unbind(let slot):
            return current?.slots.contains(slot) ?? false
        default:
            return true
        }
    }

    /// Applies `modifier` on either `this` or `other` depending on the modifier's
    /// target
    func applyModifier(modifier:Modifier, this:Object, other:Object?=nil) {
        guard let current = self.getCurrent(modifier.target, this: this, other: other) else {
            preconditionFailure("Current object for modifier should not be nil (apllication should be guarded)")
        }

        switch modifier.action {
        case .Nothing:
            // Do nothing
            break

        case .SetTags(let tags):
            current.tags = current.tags.union(tags)

        case .UnsetTags(let tags):
            current.tags = current.tags.subtract(tags)

        case .Inc(let counter):
            let value = current.counters[counter]!
            current.counters[counter] = value + 1

        case .Dec(let counter):
            let value = current.counters[counter]!
            current.counters[counter] = value + 1

        case .Clear(let counter):
            current.counters[counter] = 0

        case .Bind(let slot, let targetRef):
            guard let target = self.getCurrent(targetRef, this: this, other: other) else {
                preconditionFailure("Target sohuld not be nil (application should be guarded)")
            }

            current.bindings[slot] = target.id

        case .Unbind(let slot):
            this.bindings[slot] = nil
        }
    }

    func notify(symbol: Symbol) {
        self.logger?.logNotification(self.stepCount, notification: symbol)
    }

    // MARK: Instantiation

    /**
        Initialize the store according to the model. All existing objects will
    be discarded.
    */
    public func initialize(worldName: Symbol="main") throws {
        // FIXME: handle non-existing world
        let world = self.model.getWorld(worldName)!

        // Clean-up the objects container
        self.store.removeAll()

        if let rootConcept = world.root {
            self.store.setRootRef(try self.instantiate(rootConcept))
        }
        else {
            self.store.setRootRef(self.create())
        }

        try self.instantiateGraph(world.graph)
    }
    /**
     Creates instances of objects in the GraphDescription and returns a
     dictionary of created named objects.
     */
    func instantiateGraph(graph: InstanceGraph) throws -> ObjectMap {
        var map = ObjectMap()

        try graph.instances.forEach() { obj in
            switch obj {
            case let .Named(concept, name):
                map[name] = try self.instantiate(concept)
            case let .Counted(concept, count):
                for _ in 1...count {
                    try self.instantiate(concept)
                }
            }
        }

        return map
    }

    public func instantiate(name:Symbol) throws -> ObjectRef {
        let concept = self.model.getConcept(name)
        return self.create(concept!)
    }

    /**
     Create an object instance from `concept`. If concept is not provided,
     then creates an empty object.
     
     - Returns: reference to the newly created object
    */
    public func create(concept: Concept!=nil) -> ObjectRef {
        let obj = Object()

        if concept != nil {
            obj.tags = concept.tags
            obj.counters = concept.counters
            for slot in concept.slots {
                obj.bindings[slot] = nil
            }
            obj.slots = concept.slots

            // Concept name is one of the tags
            obj.tags.insert(concept.name)
        }

        return self.store.addObject(obj)
    }

    /**
        Create a structure of conceptual objects
    */
    public func createStruct(str:Struct) throws {
        // var instances = [String:Object]()

        // Create concept instances
//        for (name, concept) in str.concepts {
//            let obj = self.createObject(concept)
//            instances[name] = obj
//        }
//
//
//        for (sourceRef, targetRef) in str.links {
//
//            guard let source = instances[sourceRef.owner] else {
//                throw SimulationError.UnknownObject(name:sourceRef.owner)
//            }
//            guard let target = instances[targetRef] else  {
//                throw SimulationError.UnknownObject(name:targetRef)
//            }
//
//
//            source.links[sourceRef.property] = target
//        }
    }

    public func debugDump() {
        print("ENGINE DUMP START\n")
        print("STEP \(self.stepCount)")
        self.store.select().forEach {
            obj in
            print("\(obj.debugDescription)")
        }
        print("END OF DUMP\n")
    }
}
