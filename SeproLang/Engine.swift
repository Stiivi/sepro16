//
//  Engine.swift
//  AgentFarms
//
//  Created by Stefan Urbanek on 02/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//


// Note: The code might be over-modularized and there might be too many
// classes, but that is intentional during the early development phase as it
// helps in the thinking process. Concepts might be merged later in the
// process of conceptual optimizaiion.


public typealias ObjectSelection = AnySequence<ObjectRef>

public protocol Store {
    /** Initialize the store with `world`. If `world` is not specified then
    `main` is used.
    */
    func initialize(world: Symbol) throws

    /** Instantiate concept `name`.
     - Returns: reference to the newly created object
     */
    func instantiate(name: Symbol) throws -> ObjectRef

    /**
     Iterator through all objects.
     
     - Note: Order is implementation specific and is not guaranteed
       neigher between implementations or even between distinct calls
       of the method even without state change of the store.
     - Returns: sequence of all object references
    */
    var objects: AnySequence<ObjectRef> { get }

    /**
        - Returns: sequence of all object references
    */
    func getObject(ref: ObjectRef) -> Object?

    /**
     Iterates through all objects mathing `predicates`. Similar to
     `objects` the order in which the objects are iterated over is
     engine specific.
     */
    func select(predicates:[Predicate]) -> ObjectSelection

    func evaluate(predicate:Predicate,_ ref:ObjectRef) -> Bool
}

/**
    Simulation engine interface
*/
public protocol Engine {

    /**
     Perform one simulation step. Increase step counter. If a trap
     was encountered during execution, causes the trap handler to be
     invoked with a collection of captured traps.
     
     If `HALT` action was encountered, the simulation is terminated and
     can not be resumed unless re-initialized.
     */
    func step()
}

// MARK: Selection Generator

// TODO: make this a protocol, since we can't expose our internal
// implementation of object

/**
Container representing the state of the world.
*/
public class SimpleStore: Store {
    // TODO: Merge this with engine, make distinction between public methods
    // with IDs and private methods with direct object references

    public var model: Model
    public var stepCount: Int

    /// The object memory
    public var objectMap: [ObjectRef:Object]
    public var objectCounter: Int = 1

    /// Reference to the root object in the object memory
    public var root: ObjectRef!
    public var actuators: [Actuator]

    public init(model:Model) {
        self.model = model
        self.objectMap = [ObjectRef:Object]()
        self.root = nil
        self.stepCount = 0

        self.actuators = [Actuator](model.actuators)
    }

    public var objects: AnySequence<ObjectRef> {
        get { return AnySequence(self.objectMap.keys) }
    }

    public func getObject(ref:ObjectRef) -> Object? {
        return self.objectMap[ref]
    }

    /**
        Initialize the store according to the model. All existing objects will
    be discarded.
    */
    public func initialize(worldName: Symbol="main") throws {
        let world = self.model.getWorld(worldName)!

        // Clean-up the objects container
        self.objectMap.removeAll()
        self.objectCounter = 1

        if let rootConcept = world.root {
            self.root = try self.instantiate(rootConcept)
        }
        else {
            self.root = self.create()
        }

        try self.instantiateStructContents(world.contents)
    }
    /**
     Creates instances of objects in the GraphDescription and returns a
     dictionary of created named objects.
     */
    func instantiateStructContents(contents: StructContents) throws -> ObjectMap {
        var map = ObjectMap()

        for (alias, conceptName) in contents.namedObjects {
            map[alias] = try self.instantiate(conceptName)
        }

        for (conceptName, count) in contents.countedObjects {
            for _ in 1...count {
                try self.instantiate(conceptName)
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
        let ref = self.objectCounter
        let obj = Object(ref)

        if concept != nil {
            obj.tags = concept.tags
            obj.counters = concept.counters
            for slot in concept.slots {
                obj.links[slot] = nil
            }

            // Concept name is one of the tags
            obj.tags.insert(concept.name)
        }

        self.objectMap[ref] = obj
        self.objectCounter += 1

        return ref
    }

    public subscript(ref: ObjectRef) -> Object? {
        return self.objectMap[ref]
    }

    /**
    - Returns: instance of the root object.
    */
    public func getRoot() -> Object {
        // Note: this must be fullfilled
        return self[self.root]!
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



    /**
        Matches objects of the simulation against `conditions`.
    
        - Returns: Generator of matching objects.
        - Note: If selection matches an object first, then object
          changes state so that it does not match the predicate,
          the object will not be included in the result.
    */


    public func select(predicates:[Predicate]) -> ObjectSelection {
        let selection = self.filterObjects(predicates).lazy.map {
            ref, _ in ref
        }

        return ObjectSelection(selection)
    }

    func selectObjects(predicates:[Predicate]) -> AnySequence<Object> {
        let selection = self.filterObjects(predicates).lazy.map {
            _, object in object
        }

        return AnySequence(selection)
    }

    public func filterObjects(predicates:[Predicate]) -> AnySequence<(ObjectRef, Object)> {
        let filtered = self.objectMap.lazy.filter {ref, object in

            // Find at least one predicate that the inspected object
            // does not satisfy (!evaluate). If such predicate is found
            // (index != nil), then filter out the inspected object.

            predicates.indexOf {
                predicate in
                !self.evaluateObject(predicate, object)
            } == nil
        }

        return AnySequence(filtered)
    }
    /**
        Evaluates the predicate against object.
        - Returns: `true` if the object matches the predicate
    */
    public func evaluate(predicate:Predicate, _ ref: ObjectRef) -> Bool {
        if let obj = self.objectMap[ref] {
            return self.evaluateObject(predicate, obj)
        }
        else {
            // TODO: Exception?
            return false
        }
    }

    /**
        Evaluate predicate.
    
        - Returns: `true` if the object matches condition.
    */
    func evaluateObject(predicate:Predicate, _ obj: Object) -> Bool {
        var target: Object

        // Try to get the target slot
        //
        if predicate.inSlot != nil {
            if let maybeTarget = obj.links[predicate.inSlot!] {
                target = self.objectMap[maybeTarget]!
            }
            else {
                // TODO: is this OK if the slot is not filled and the condition is
                // negated?
                return false
            }
        }
        else {
            target = obj
        }

        return predicate.evaluate(target)
    }

}

public typealias TrapHandler = (Engine, CountedSet<Symbol>) -> Void
public typealias HaltHandler = (Engine) -> Void

/**
    SimpleEngine – simple implementation of computational engine. Performs
    computations of simulation steps, captures traps and observes probe values.
*/

public class SimpleEngine: Engine {
    /// Current step
    public var stepCount = 0

    /// Simulation state instance
    public var store: SimpleStore

    /// Traps caught in the last step
    public var traps = CountedSet<Symbol>()

    /// Handler for traps
    public var onTrap:TrapHandler?
    public var onHalt:HaltHandler?

    /// Flag saying whether the simulation is halted or not.
    public var isHalted: Bool

    // Probing
    // -------

    /// List of probes
    public var probes: [Probe]

    /// Logging delegate – an object that implements the `Logger`
    /// protocol
    public var logger: Logger?

    /// Simulation model
    public var model: Model {
        return self.store.model
    }

    /**
        Create an object instance from concept
    */
    public init(_ store:SimpleStore){
        self.store = store
        self.isHalted = false
        self.logger = nil
        self.probes = [Probe]()
    }

    convenience public init(model:Model){
        let store = SimpleStore(model: model)
        self.init(store)
    }

    /**
        Runs the simulation for `steps`.
    */
    public func run(steps:Int) {
        if self.logger != nil {
            self.logger!.loggingWillStart(self.model.measures)
            self.probe()
        }

        for _ in 1...steps {

            self.step()

            if self.isHalted {
                if self.onHalt != nil {
                    self.onHalt!(self)
                }
                break
            }
        }

        if self.logger != nil {
            self.logger!.loggingDidEnd()
        }
    }

    /**
        Compute one step of the simulation by evaluating all actuators.
    */
    public func step() {
        self.traps.removeAll()

        stepCount += 1

        store.actuators.forEach {
            actuator in self.perform(actuator)
        }

        if self.logger != nil {
            self.probe()
        }

        if !self.traps.isEmpty && self.onTrap != nil {
            self.onTrap!(self, self.traps)
        }
    }

    func probe() {
        let measures: [AggregateMeasure]
        let record: ProbeRecord

        if self.logger == nil {
            return
        }

        // TODO: We do only aggregate probes here for now
        measures = self.model.measures.filter { $0.type == MeasureType.Aggregate }
            . map { $0 as! AggregateMeasure }

        record = self.probeAggregates(measures)

        self.logger!.logRecord(self.stepCount, record: record)
    }

    func probeAggregates(measures: [AggregateMeasure]) -> ProbeRecord {
        var record = ProbeRecord()
        let probeList = measures.map {
            measure in
            (measure, createAggregateProbe(measure))
        }

        self.store.objectMap.forEach {
            ref, object in
            probeList.forEach {
                measure, probe in
                if measure.predicates.all({ $0.evaluate(object) }) {
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

        return record
    }

    /**
        Dispatch an `actuator` – reactive vs. interactive.
     */
    func perform(actuator:Actuator){
        if actuator.otherPredicates != nil {
            self.performCartesian(actuator)
        }
        else
        {
            self.performSingle(actuator)
        }
    }

    /**
        Interactive actuator execution.
    
        Algorithm:
    
        1. Find objects matching conditions for `this`
        2. Find objects matching conditions for `other`
        3. If any of the sets is empty, don't perform anything – there is
           no reaction
        4. Perform reactive action on the objects.
    */
    func performSingle(actuator:Actuator) {
        let thisObjects = self.store.selectObjects(actuator.predicates)

        var counter = 0
        for this in thisObjects {
            counter += 1
            for instruction in actuator.instructions {
                self.execute(instruction, this: this)
            }
        }

    }

    func performCartesian(actuator:Actuator) {
        let thisObjects = self.store.selectObjects(actuator.predicates)
        let otherObjects = self.store.selectObjects(actuator.otherPredicates!)
        var counter = 0

        // Cartesian product: everything 'this' interacts with everything
        // 'other'
        for this in thisObjects {
            for other in otherObjects{
                counter += 1
                for instruction in actuator.instructions {
                    self.execute(instruction, this: this, other: other)
                }

                // Break if `this` has been modified in the previous
                // action
                // Reversed logic: detect first predicate that matches
                let match = actuator.predicates.indexOf {
                    predicate in
                    self.store.evaluateObject(predicate, this)
                }

                // if there is a failed predicate found, then advance
                // to the next `this` object
                if match != nil {
                    break
                }
            }
        }

    }

    /**
        Get "current" object – choose between ROOT, THIS and OTHER then
    optionally apply dereference to a slot, if specified.
    */
    func getCurrent(ref: CurrentRef, this: Object, other: Object!) -> Object! {
            let current: Object!

            switch ref.type {
            case .Root:
                current = self.store.getRoot()
            case .This:
                current = this
            case .Other:
                current = other
            }

            if current == nil {
                return nil
            }

            if ref.slot != nil {
                return self.store.objectMap[current.links[ref.slot!]!]
            }
            else {
                return current
            }
    }

    /**
    Execute instruction
    */

    func execute(instruction:Instruction, this:Object, other:Object!=nil) {
        // Note: Similar to the Predicate code, we are not using language
        // polymorphysm here. This is not proper way of doing it, but
        // untill the action objects are refined and their executable
        // counterparts defined, this should remain as it is.

        switch instruction {
        case .Nothing:
            // Do nothing
            break

        case .Halt:
            self.isHalted = true

        case .Trap(let symbol):
            self.traps.add(symbol)

        case .Notify(let symbol):
            self.notify(symbol)

        case .Modify(let currentRef, let modifier):
            let current = self.getCurrent(currentRef, this: this, other: other)

            switch modifier {
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

            case .Zero(let counter):
                current.counters[counter] = 0

            case .Bind(let targetRef, let slot):
                let target = self.getCurrent(targetRef, this: this, other: other)
                if current != nil && target != nil {
                    current.links[slot] = target.id
                }
                else {
                    // TODO: isn't this an error or invalid state?
                }

            case .Unbind(let slot):
                if current != nil {
                    this.links[slot] = nil
                }
                else {
                    // TODO: isn't this an error or invalid state?
                }
            }
        }
    }

    func notify(symbol: Symbol) {
        if self.logger != nil {
            self.logger?.logNotification(self.stepCount, notification: symbol)
        }
    }

    public func debugDump() {
        print("ENGINE DUMP START\n")
        print("STEP \(self.stepCount)")
        let keys = self.store.objectMap.keys.sort()
        for key in keys {
            let obj = self.store.objectMap[key]
            print("\(key): \(obj!.debugString)")
        }
        print("END OF DUMP\n")
    }
}
