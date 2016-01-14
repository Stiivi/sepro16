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
// TODO: Add SymbolInfo: symbol, type, firstOccurence

// Note: eventhough the counter type is specified as Int, it should be
// unsigned. Use of Int follows the Swift language recommendation. See
// the discussion about UInt unsigned integers in the language
// reference.
public typealias CounterType = Int
public typealias SymbolList = [Symbol]

// FIXME: remove these two
public typealias SlotList = SymbolList
public typealias TagList = Set<Symbol>

public typealias CounterDict = [Symbol:Int]

/**
    Representation of a concept. Concept is the main model entity.
*/

public class Concept: CustomStringConvertible {
    public var name:String
    /// Dictionary of counters
    public var counters:CounterDict
    /// Dictionary of slots
    public var slots:SlotList
    /// Dictionary of tags
    public var tags:TagList

    /**
        Initializes the concept.
    
        - Parameters:
            - counters: Dictionary of counters and their initial values.
            - slots: List of slot symbols (unbound on initialization).
            - tags: List of tags present when object is instantiated.

    */
    public init(name:Symbol,
                 counters:CounterDict?=nil,
                 slots:SlotList?=nil,
                 tags:TagList?=nil){

        self.name = name
        self.counters = counters ?? CounterDict()
        self.slots = slots ?? SlotList()
        self.tags = tags ?? TagList()
    }

    public func hasCounter(name:Symbol) -> Bool {
        return self.counters[name] != nil
    }

    /**
    - Returns: counter value
    */
    public func getCounter(name:Symbol) -> Int? {
        return self.counters[name]
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
        if !self.counters.isEmpty {
            for (counter, value) in counters {
                desc += "    COUNTER \(counter) = \(value)\n"
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

public enum InstanceSpecification: CustomStringConvertible {
    case Named(Symbol, Symbol)
    case Counted(Symbol, Int)

    public var description: String {
        switch self {
        case let .Named(concept, name):
            return "\(concept) AS \(name)"
        case let .Counted(concept, count):
            return "\(concept) * \(count)"
        }
    }
}

/**
    Descrption of an object container. Contains collection of objects
 that can be referenced by their names and collection of anonymous
 objects with multiple instances of the same concept.
*/
public class GraphDescription {
    /// List of all content object
    public var instances: [InstanceSpecification]
    public var bindings: [Binding]

    /// Map of objects that have name. Objects with name can be used for
    /// bindings.
    public var namedObjects = [Symbol:Symbol]()


    public init(instances: [InstanceSpecification]? = nil, bindings: [Binding]?) {
        self.instances = instances ?? [InstanceSpecification]()
        self.bindings = bindings ?? [Binding]()

        let named:[(Symbol, Symbol)] = self.instances.flatMap {
            instance in
            switch instance {
            case let .Named(concept, name): return (concept, name)
            default: return nil
            }
        }

        self.namedObjects = [Symbol:Symbol](items: named)
    }

    /// Adds a instance specification `obj` to the graph
    public func addObject(obj: InstanceSpecification) {
        switch obj {
        case let .Named(concept, name):
            self.namedObjects[name] = concept
        case .Counted:
            break
        }

        self.instances.append(obj)
    }

    public func bind(source: Symbol, sourceSlot: Symbol, target: Symbol) {
        let binding = Binding(source: source, sourceSlot: sourceSlot, target: target)

        // TODO: check for binding existence
        self.bindings.append(binding)
    }

    public func asString() -> String {
        let lines = self.instances.map() { obj in
            return "    OBJECT \(obj)"
        }

        var out = lines.joinWithSeparator("\n")

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
    public var graph: GraphDescription
    /// Root object – referenced to as `ROOT`.
    public var root: Symbol? = nil

    public init(name: Symbol, graph: GraphDescription, root: Symbol?=nil) {
        self.name = name
        self.graph = graph
        self.root = root
    }

    public func asString() -> String {
        var out = ""

        out += "WORLD \(name)"
        if self.root != nil {
            out += " ROOT \(root)"
        }
        out += "\n"
        out += graph.asString()

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
    /// Names of outlets
    public let outlets:LinkReferenceDict

    /**
        Creates a concept structure.

        - Parameters:
            - name: Structure name
            - contents: Graph contents
            - outlets: Named objects to be exposed to the outside
    */
    public init(name: Symbol, instances: [InstanceSpecification]? = nil,
           bindings: [Binding]?, outlets: LinkReferenceDict?=nil) {
            self.name = name
            self.outlets = outlets ?? LinkReferenceDict()
            super.init(instances: instances, bindings:bindings)
    }

}

/**
    Model container – holds all model entities needed for execution.
*/

public class Model {
    /// Dictionary of concepts
    public var concepts: [Concept]
    /// Dictionary of structures
    public var structures: [Struct]
    /// Dictionary of worlds
    public var worlds: [World]
    /// List of actuators
    public var actuators: [Actuator]

    /// List of measures
    public var measures: [Measure]

    public init(concepts: [Concept]?=nil, actuators: [Actuator]?=nil,
        measures: [Measure]?=nil, worlds: [World]?=nil,
        structures: [Struct]?=nil) {
            self.concepts = concepts ?? [Concept]()
            self.actuators = actuators ?? [Actuator]()
            self.measures = measures ?? [Measure]()
            self.worlds = worlds ?? [World]()
            self.structures = structures ?? [Struct]()
    }

    /// Get a structure by name
    public func getStruct(name:String) -> Struct? {
        return self.structures.findFirst { $0.name == name }
    }

    /// Get a concept by name
    public func getConcept(name:String) -> Concept? {
        return self.concepts.findFirst { $0.name == name }
    }

    /// Get a world by name
    public func getWorld(name:String) -> World? {
        return self.worlds.findFirst { $0.name == name }
    }

    public func asString() -> String {
        var out: String = ""

        for (concept) in self.concepts {
            out += concept.asString()
            out += "\n"
        }
        for actuator in self.actuators {
            out += actuator.asString()
            out += "\n"
        }
        for (world) in self.worlds {
            out += world.asString()
            out += "\n"
        }
        return out
    }

}

