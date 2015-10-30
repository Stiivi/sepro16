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


/**
    References an object in the store.
*/
public typealias ObjectRef = Int
public typealias ObjectList = [Int]
public typealias ObjectMap = [Symbol:Int]

// TODO: Rename to stage
public protocol Store {
    /** Initialize the store with `world`. If `world` is not specified then
    `main` is used.
    */
    func initialize(world: Symbol?)
    func instantiateConcept(concept: Symbol) -> ObjectRef
    func instantiateStruct(structure: Symbol) -> ObjectMap

    func select(predicates:[Predicate]) -> ObjectSelection
    func evaluate(predicate:Predicate, object:Object) -> Bool
}

public protocol Engine {
    func step()
}

// FIXME: Make this [String:Int]
public typealias LinkDict = [String:Object?]

/**
    Simulation object – concrete instance of a concept.

    When concept is instantiated in the simulation environment, the physical
    connection between the

*/
public class Object: CustomStringConvertible {
    /// Measure values
    public var measures = MeasureDict()
    /// Tags that are set
    public var tags = TagList()
    /// References to other objects
    public var links = LinkDict()

    public var description: String {
        get {
            let links = self.links.map(){ (key, value) in key }
            return "tags: \(self.tags) links: \(links)"
        }
    }

    public var debugString: String {
        return self.description
    }
}

public struct Comparator {
    public let isNegated: Bool
    public let slot: Symbol?
    public let properties: [Symbol]
}

// MARK: Selection Generator

// TODO: make this a protocol, since we can't expose our internal
// implementation of object

/**
    Represents product of objects matching `thisPredicate` ⨯
    `otherPredicate`

*/
public class ObjectProductSelection: SequenceType {
    let store: SimpleStore
    let thisPredicates: [Predicate]
    let otherPredicates: [Predicate]

    init(store: SimpleStore, thisPredicates: [Predicate], otherPredicates:[Predicate]) {
        self.thisPredicates = thisPredicates
        self.otherPredicates = otherPredicates
        self.store = store
    }

    public func generate() -> ObjectProductSelectionGenerator {
        return ObjectProductSelectionGenerator(selection: self)

    }
}

/**
    Iterator of interacting objects. Iterates through all objects
    matching predicates, but is state change aware.
*/
public struct ObjectProductSelectionGenerator: GeneratorType {
    public typealias Element = Object
    let selection: ObjectProductSelection
    var generator: DictionaryGenerator<Int, Object>

    init(selection: ObjectProductSelection) {
        self.selection = selection
        self.generator = selection.store.objects.generate()
    }

    public mutating func next() -> Element? {
        var object: Object

        objectLoop: while let item = self.generator.next() {
            (_, object) = item

            for predicate in self.selection.thisPredicates {
                if !self.selection.store.evaluate(predicate, object) {
                    continue objectLoop
                }
            }
            return object
        }
        return nil

    }
}

public class ObjectSelection: SequenceType {
    let store: SimpleStore
    let predicates: [Predicate]

    init(store: SimpleStore, predicates: [Predicate]) {
        self.predicates = predicates
        self.store = store
    }

    public func generate() -> ObjectSelectionGenerator {
        return ObjectSelectionGenerator(selection: self)

    }
}

public struct ObjectSelectionGenerator: GeneratorType {
    public typealias Element = Object
    let selection: ObjectSelection
    var generator: DictionaryGenerator<Int, Object>

    init(selection: ObjectSelection) {
        self.selection = selection
        self.generator = selection.store.objects.generate()
    }

    public mutating func next() -> Element? {
        var object: Object

        objectLoop: while let item = self.generator.next() {
            (_, object) = item

            for predicate in self.selection.predicates {
                if !self.selection.store.evaluate(predicate, object) {
                    continue objectLoop
                }
            }
            return object
        }
        return nil

    }
}


/**
Container representing the state of the world.
*/
public class SimpleStore {
    // TODO: Merge this with engine, make distinction between public methods
    // with IDs and private methods with direct object references

    public var model: Model
    public var stepCount: Int

    /// The object memory
    public var objects: [Int:Object]
    public var objectCounter: Int = 1

    /// Reference to the root object in the object memory
    public var root: ObjectRef!
    public var actuators: [Actuator]

    public init(model:Model) {
        self.model = model
        self.objects = [Int:Object]()
        self.root = nil
        self.stepCount = 0

        self.actuators = [Actuator](model.actuators)
    }

    /**
        Initialize the store according to the model. All existing objects will
    be discarded.
    */
    public func initialize(worldName: Symbol="main") throws {
        let world = self.model.getWorld(worldName)!

        // Clean-up the objects container
        self.objects.removeAll()
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
        let ref: ObjectRef
        let obj = Object()

        if concept != nil {
            obj.tags = concept.tags
            obj.measures = concept.measures
            for slot in concept.slots {
                obj.links[slot] = nil
            }

            // Concept name is one of the tags
            obj.tags.insert(concept.name)
        }

        ref = self.objectCounter
        self.objects[ref] = obj
        self.objectCounter += 1

        return ref
    }

    public subscript(ref: ObjectRef) -> Object? {
        return self.objects[ref]
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


    func select(predicates:[Predicate]) -> ObjectSelection {

        return ObjectSelection(store: self, predicates: predicates)
    }

    /**
        Evaluates the predicate against object.
        - Returns: `true` if the object matches the predicate
    */
    func evaluate(predicate:Predicate, _ obj: Object) -> Bool{
        if predicate is AllPredicate {
            return true
        }
        else if let objPred = predicate as? ObjectPredicate {
            return evaluateObjectPredicate(objPred, obj)
        }

        return false
    }

    func evaluate(predicates:[Predicate], _ obj: Object) -> Bool{
        for predicate in predicates {
            if !evaluate(predicate, obj) {
                return false
            }
        }
        return true
    }

    /**
        Dispatch object conditions
    
        - Returns: `true` if the object matches condition.
    */
    func evaluateObjectPredicate(predicate: ObjectPredicate, _ obj:Object) -> Bool {
        var result: Bool = false
        var target: Object

        // Try to get the target slot
        //
        if predicate.slot != nil {
            if let maybeTarget = obj.links[predicate.slot!] {
                target = maybeTarget!
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

        // Note: The reason we do it here in a branched IF statement instead
        // of using language class polymorphism is that we want to keep the
        // example engine code close to the engine and the model free of
        // computation logic.
        //
        // Compare the target object with conditions
        //
        if let cond = predicate as? TagSetPredicate {
            result = cond.tags.isSubsetOf(obj.tags)
        }
        else if let cond = predicate as? TagUnsetPredicate {
            result = cond.tags.isDisjointWith(obj.tags)
        }
        else if let cond = predicate as? ComparisonPredicate {
            let value = target.measures[cond.measure]
            switch cond.comparisonType {
                case .Less: result = value < cond.value
                case .Greater: result = value > cond.value
            }
        }
        else if let cond = predicate as? ZeroPredicate {
            let value = target.measures[cond.measure]
            // Note: zero is not the same nil neither in the simulation
            result = value == 0
        }

        // Optionally negate the result condition
        //
        return !predicate.isNegated && result
                || predicate.isNegated && !result
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
    /// Simulation instance
    // TODO: change this to Store
    public var store: SimpleStore

    /// Traps caught in the last step
    public var traps = CountedSet<Symbol>()

    /// Handler for traps
    public var onTrap:TrapHandler?

    /// Flag saying whether the simulation is halted or not.
    public var isHalted: Bool
    // TODO: Make one trap that would require restart of the simulation,
    // something like a dead-end

    /// Handler for halt
    public var onHalt:HaltHandler?

    /**
        Create an object instance from concept
    */
    public init(_ store:SimpleStore){
        self.store = store
        self.isHalted = false
    }

    convenience public init(model:Model){
        let store = SimpleStore(model: model)
        self.init(store)
    }

    /**
        Runs the simulation for `steps`.
    */
    public func run(steps:Int) {
        for _ in 1...steps {

            self.step()

            if !self.traps.isEmpty && self.onTrap != nil {
                self.onTrap!(self, self.traps)
            }

            if self.isHalted {
                if self.onHalt != nil {
                    self.onHalt!(self)
                }
                break
            }

        }
    }

    /**
        Compute one step of the simulation by evaluating all actuators.
    */
    public func step() {
        self.traps.removeAll()

        debugPrint("=== step \(stepCount) with \(store.actuators.count) actuators")

        for actuator in store.actuators {
            self.perform(actuator)
        }
        stepCount += 1
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
        let thisObjects = self.store.select(actuator.predicates)

        var counter = 0
        for this in thisObjects {
            counter += 1
            for action in actuator.actions {
                self.apply(action, this: this)
            }
        }

    }

    func performCartesian(actuator:Actuator) {
        let thisObjects = self.store.select(actuator.predicates)
        let otherObjects = self.store.select(actuator.otherPredicates!)
        var counter = 0

        // Cartesian product: everything 'this' interacts with everything
        // 'other'
        for this in thisObjects {
            for other in otherObjects{
                counter += 1
                for action in actuator.actions {
                    self.apply(action, this: this, other: other)
                }

                // Break if `this` has been modified in the previous
                // action
                if !self.store.evaluate(actuator.predicates, this) {
                    break
                }
            }
        }

    }

    /**
        First action abstraction dispatcher: Catches system actions.
    */
    func getContext(contextType: ObjectContextType, slot: Symbol?,
        this: Object, other: Object!) -> Object! {
            let receiver: Object!

            switch contextType {
            case .Root:
                receiver = self.store.getRoot()
            case .This:
                receiver = this
            case .Other:
                receiver = other
            }

            if receiver == nil {
                return nil
            }

            if slot != nil {
                return receiver.links[slot!]!
            }
            else {
                return receiver
            }
    }

    /**
        Apply action
    */

    func apply(genericAction:Action, this:Object, other:Object!=nil) {
        // Note: Similar to the Predicate code, we are not using language
        // polymorphysm here. This is not proper way of doing it, but
        // untill the action objects are refined and their executable
        // counterparts defined, this should remain as it is.

        if let action = genericAction as? TrapAction {
            // TODO: anonymous action
            self.traps.add(action.type!)
        }
        else if let action = genericAction as? NotifyAction {
            // TODO: anonymous action
            self.notify(action.symbol)
        }
        else if genericAction is HaltAction {
            self.isHalted = true
        }
        else if let action = genericAction as? UnbindAction {
            let receiver = getContext(action.inContext, slot: action.inSlot,
                                        this: this, other: other)

            if receiver != nil {
                this.links[action.slot] = nil
            }
        }
        else if let action = genericAction as? BindAction {
            let receiver = getContext(action.inContext, slot: action.inSlot,
                                        this: this, other: other)
            let target = getContext(action.targetContext, slot: action.targetSlot,
                                        this: this, other: other)

            if receiver == nil || target == nil {
                // TODO: isn't this an error?
                return
            }

            receiver.links[action.slot] = target
        }
        else if let action = genericAction as? ObjectAction {
            let receiver = getContext(action.inContext, slot: action.inSlot,
                                        this: this, other: other)
            if receiver != nil {
                self.performObjectAction(action, obj: receiver!)
            }
        }
        else {
            print("ERROR!!! UNKNOWN ACTION \(genericAction)")
            // pass
        }

    }

    func notify(symbol: Symbol?) {
        let str: String
        if symbol == nil {
            str = "(anonymous)"
        }
        else {
            str = symbol!
        }
        print("NOTIFICATION \(str)")
    }

    /**
        Second action abstraction dispatcher: Catches object actions.
    */
    func performObjectAction(objectAction:ObjectAction, obj:Object) {
        let target: Object
        // Try to get the target slot
        //

        if objectAction.inSlot != nil {
            if let maybeTarget = obj.links[objectAction.inSlot!] {
                target = maybeTarget!
            }
            else {
                // TODO: is this OK if the slot is not filled?
                return
            }
        }
        else {
            target = obj
        }

        if let action = objectAction as? SetTagsAction {
            target.tags = target.tags.union(action.tags)
        }
        else if let action = objectAction as? UnsetTagsAction {
            target.tags = target.tags.subtract(action.tags)
        }
        else if let action = objectAction as? IncMeasureAction {
            let value = target.measures[action.measure]!
            target.measures[action.measure] = value + 1
        }
        else if let action = objectAction as? DecMeasureAction {
            let value = target.measures[action.measure]!
            target.measures[action.measure] = value - 1
        }
        else if let action = objectAction as? ZeroMeasureAction {
            target.measures[action.measure] = 0
        }
        else {
            // pass
        }

    }

    public func debugDump() {
        print("ENGINE DUMP START\n")
        print("STEP \(self.stepCount)")
        let keys = self.store.objects.keys.sort()
        for key in keys {
            let obj = self.store.objects[key]
            print("\(key): \(obj!.debugString)")
        }
        print("END OF DUMP\n")
    }
}
