//
//  Model.swift
//  Sepro
//
//  Created by Stefan Urbanek on 02/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

// Note: The code might be over-modularized and there might be too many
// classes, but that is intentional during the early development phase as it
// helps in the thinking process. Concepts might be merged later in the
// process of conceptual optimization.


public typealias Symbol = String

public typealias SlotList = [String];
public typealias TagList = Set<String>;
public typealias MeasureDict = [String:Int]
public typealias StringDict = [String:String]

/**
    Representation of a concept. Concept is the main model entity.
*/

public class Concept: CustomStringConvertible {
    public var name:String
    /// Dictionary of measures
    public var measures:MeasureDict
    /// Dictionary of slots
    public var slots:SlotList
    /// Dictionary of tags
    public var tags:TagList

    /**
        Initializes the concept.
    
        - Parameters:
            - measures: Dictionary of measures and their initial values.
            - slots: List of slot symbols (unbound on initialization).
            - tags: List of tags present when object is instantiated.

    */
    public init(name:Symbol,
                measures:MeasureDict?=nil,
                slots:SlotList?=nil,
                tags:TagList?=nil){

        self.name = name
        self.measures = measures ?? MeasureDict()
        self.slots = slots ?? SlotList()
        self.tags = tags ?? TagList()
    }

    public func hasMeasure(name:Symbol) -> Bool {
        return self.measures[name] != nil
    }

    /**
    - Returns: measure value
    */
    public func getMeasure(name:Symbol) -> Int? {
        return self.measures[name]
    }

    /// Short description of the concept.
    public var description: String {
        get {
            return "CONCEPT(\(self.name))"
        }
    }

    /**
        Convert the concept to a model string.
    */
    public func asString() -> String {
        var desc = "CONCEPT \(self.name)\n"
        if !self.measures.isEmpty {
            for (measure, value) in measures {
                desc += "    MEASURE \(measure) = \(value)\n"
            }
        }
        if !self.tags.isEmpty {
            let list = tags.joinWithSeparator(", ")
            desc += "    TAG \(list)\n"
        }
        if !self.slots.isEmpty {
            let list = slots.joinWithSeparator(", ")
            desc += "    SLOT \(list)\n"
        }
        return desc
    }
}


/**
    Combines predicates with their respective actions that are triggered
 when the predicate is met.
*/
public class Actuator {
    /// Denother whether the predicates are related to the root object
    public let isRoot: Bool
    /// Predicates that trigger the actuator
    public let predicates: [Predicate]
    /// Actions performed by the actuator in atomic way.
    public let actions: [Action]
    /// Actions performed by the actuator in atomic way.
    public let otherPredicates: [Predicate]?

    public init(predicates: [Predicate], actions: [Action],
        otherPredicates: [Predicate]?=nil, isRoot:Bool=false) {
        self.isRoot = isRoot
        self.predicates = predicates
        self.otherPredicates = otherPredicates
        self.actions = actions
    }

    public func asString() -> String {
        // TODO: Implement string representation of the actuator
        return "# (some actuator)"
    }
}

// MARK: Model
/**
    Binding between a slot and target object represented by symbols.
*/

public class Binding {
    /// Name of the source object within the context of the owning
    /// container
    public var source: Symbol
    /// Slot which will be bound
    public var sourceSlot: Symbol
    /// Target object within the context of the owning container that
    /// the slot refers to
    public var target: Symbol

    public init(source:Symbol, sourceSlot:Symbol, target:Symbol) {
        self.source = source
        self.sourceSlot = sourceSlot
        self.target = target
    }
}

/**
    Descrption of an object container. Contains collection of objects
 that can be referenced by their names and collection of anonymous
 objects with multiple instances of the same concept.
*/
public class StructContents {
    /// Map of objects that have name. Objects with name can be used for
    /// bindings.
    public var namedObjects = [Symbol:Symbol]()
    /// List of anonymous objects.
    public var countedObjects = CountedSet<Symbol>()

    public func addObjectCount(concept:Symbol, count:Int) {
        countedObjects[concept] = count
    }
    public func addObject(concept:Symbol, alias:Symbol?=nil) {
        if alias == nil {
            countedObjects.add(concept)
        }
        else {
            self.namedObjects[alias!] = concept
        }
    }

    public func asString() -> String {
        var out = String()

        for (alias, concept) in namedObjects {
            out += "    OBJECT \(concept) AS \(alias)\n"
        }
        for (concept, count) in countedObjects {
            out += "    OBJECT \(concept) * \(count)\n"
        }

        return out
    }
}

/**
    Extension of an object container that holds information about
 bindings between the named objects within the container.
*/
public class GraphDescription: StructContents {
    public var bindings = [Binding]()

    public func bind(source: Symbol, sourceSlot: Symbol, target: Symbol) {
        let binding = Binding(source: source, sourceSlot: sourceSlot, target: target)

        // TODO: check for binding existence
        self.bindings.append(binding)
    }

    public override func asString() -> String {
        var out = super.asString()

        for b in self.bindings {
            out += "    BIND \(b.source).\(b.sourceSlot) TO \(b.target)\n"
        }
        return out
    }
}

/**
    Describes initial contents of a simulation.
*/
public class World {
    public var name: Symbol
    /// Contents
    public var contents: GraphDescription
    /// Root object – referenced to as `ROOT`.
    public var root: Symbol? = nil

    public init(name: Symbol, contents: GraphDescription, root: Symbol?=nil) {
        self.name = name
        self.contents = contents
        self.root = root
    }

    public func asString() -> String {
        var out = ""

        out += "WORLD \(name)"
        if self.root != nil {
            out += " ROOT \(root)"
        }
        out += "\n"
        out += contents.asString()

        return out
    }

}

/// Reference for a concept's property
public struct PropertyRef:Hashable {
    /// Name of the owning concept
    public let owner: String
    /// Property symbol
    public let property: String

    public var hashValue: Int {
        return owner.hashValue ^ property.hashValue
    }

    /**
        Initializes the property reference.

        - Parameters:
            - owner: name of the owning concept
            - property: symbol of the concept's property
    */
    public init(_ owner: String, _ property: String) {
        self.owner = owner
        self.property = property
    }
}
public func ==(left: PropertyRef, right:PropertyRef) -> Bool {
    return left.owner == right.owner && left.property == right.property
}

public typealias LinkReferenceDict = [PropertyRef:String]

/**
    Structure of concepts. Describes concept instances forming a linked structure.
*/

public class Struct: GraphDescription {
    public var name: Symbol
    /// Contents
    public var contents: GraphDescription
    /// Names of outlets
    public let outlets:LinkReferenceDict

    /**
        Creates a concept structure.

        - Parameters:
            - name: Structure name
            - contents: Graph contents
            - outlets: Named objects to be exposed to the outside
    */
    public init(name: Symbol, contents: GraphDescription,
        outlets: LinkReferenceDict?=nil) {
            self.name = name
            self.contents = contents
            self.outlets = outlets ?? LinkReferenceDict()
    }
}

/**
    Model container – holds all model entities needed for execution.
*/

public class Model {
    /// Dictionary of concepts
    public let concepts: [Symbol:Concept]
    /// Dictionary of structures
    public var structures = [Symbol:Struct]()
    /// Dictionary of worlds
    public var worlds = [Symbol:World]()
    /// List of actuators
    public var actuators = [Actuator]()

    public init(concepts: [Symbol:Concept]?=nil, actuators: [Actuator]?=nil,
        worlds: [World]?=nil) {
            self.concepts = concepts ?? [Symbol:Concept]()
            self.actuators = actuators ?? [Actuator]()

            if worlds != nil {
                for world in worlds! {
                    self.worlds[world.name] = world
                }
            }
    }

    /// Get a structure by name
    public func getStruct(name:String) -> Struct? {
        return self.structures[name]
    }

    /// Get a concept by name
    public func getConcept(name:String) -> Concept? {
        return self.concepts[name]
    }

    /// Get a world by name
    public func getWorld(name:String) -> World? {
        return self.worlds[name]
    }

    public func asString() -> String {
        var out: String = ""

        for (_, concept) in self.concepts {
            out += concept.asString()
            out += "\n"
        }
        for actuator in self.actuators {
            out += actuator.asString()
            out += "\n"
        }
        for (_, world) in self.worlds {
            out += world.asString()
            out += "\n"
        }
        return out
    }
}

public class ModelValidator {
    public let model: Model
    public var issues: [String]

    public init(model: Model) {
        self.model = model
        self.issues = [String]()
    }

    /**
    Validate the model.
    
    Returns: `true` when model is valid, `false` when model has issues.
    */
    public func validate() -> Bool {
        for (name, str) in self.model.structures {
            self.validateStruct(name, str: str)
        }

        return !self.issues.isEmpty
    }
    public func validateStruct(name:String, str:Struct) {

//        for (sourceRef, targetRef) in str.links {
//
//            if str.concepts[sourceRef.owner] == nil {
//                self.issues.append("Unknown source concept \(sourceRef.owner) in structure \(name)")
//            }
//            if str.concepts[targetRef] == nil {
//                self.issues.append("Unknown target concept \(targetRef) in structure \(name)")
//            }
//        }
    }

}
