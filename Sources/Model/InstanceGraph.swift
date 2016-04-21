//
//  Struct.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 26/01/16.
//  Copyright © 2016 Stefan Urbanek. All rights reserved.
//

/// Binding between a slot and target object represented by symbols.
///
public struct Binding {
    /// Name of the source object within the context of the owning
    /// container
    public let source: Symbol
    /// Slot which will be bound
    public let sourceSlot: Symbol
    /// Target object within the context of the owning container that
    /// the slot refers to
    public let target: Symbol

    public init(source:Symbol, sourceSlot:Symbol, target:Symbol) {
        self.source = source
        self.sourceSlot = sourceSlot
        self.target = target
    }
}


public struct InstanceInitialization: CustomStringConvertible {
	let tags: TagList
	let counters: [Symbol:Int]

	init(tags: TagList, counters: [Symbol:Int]) {
		self.tags = tags
		self.counters = counters
	}

	public var description: String {
		return "()"
	}
}


/// Specification of an object instance in instance graph.
public enum InstanceType: CustomStringConvertible {
    /// Single instance that can be referred to by name
    case Named(Symbol)
    /// Multiple instances, but can't be referenced
    case Counted(Int)

    public var description: String {
        switch self {
        case let .Named(name):    return "AS \(name)"
        case let .Counted(count): return "* \(count)"
        }
    }
}

/// Initial value of an instance
public enum Initializer {
	case Tag(Symbol)
	case Counter(Symbol, Int)
}


public struct Instance {
	public let concept: Symbol
	public let initializers: [Initializer]
	public let type: InstanceType

	public init(concept: Symbol, initializers: [Initializer], type: InstanceType) {
		self.concept = concept
		self.initializers = initializers
		self.type = type
	}
}


/// Reference for a concept's property
public struct PropertyReference:Hashable {
    /// Name of the owning concept
    public let owner: Symbol
    /// Property symbol
    public let property: Symbol

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

public func ==(left: PropertyReference, right:PropertyReference) -> Bool {
    return left.owner == right.owner && left.property == right.property
}

/// Contains collection of objects
/// that can be referenced by their names and collection of anonymous
/// objects with multiple instances of the same concept.
public struct InstanceGraph {

    /// List of all content object
    public var instances: [Instance]
    public var bindings: [Binding]

    /// Map of objects that have name. Objects with name can be used for
    /// bindings.
    public var namedObjects = [Symbol:Symbol]()


    public init(instances: [Instance]? = nil, bindings: [Binding]?) {
        self.instances = instances ?? [Instance]()
        self.bindings = bindings ?? [Binding]()

        let named:[(Symbol, Symbol)] = self.instances.flatMap {
            instance in
            switch instance.type {
            case let .Named(name): return (name, instance.concept)
            default: return nil
            }
        }

        self.namedObjects = [Symbol:Symbol](items: named)
    }

    /// Adds a instance specification `obj` to the graph
    mutating public func addInstance(obj: Instance) {
        switch obj.type {
        case let .Named(name):
            self.namedObjects[name] = obj.concept
        case .Counted:
            break
        }

        self.instances.append(obj)
    }

    mutating public func bind(source: Symbol, sourceSlot: Symbol, target: Symbol) {
        let binding = Binding(source: source, sourceSlot: sourceSlot, target: target)

        // TODO: check for binding existence
        self.bindings.append(binding)
    }

    public func asString() -> String {
        let lines = self.instances.map() { obj in
            return "    OBJECT \(obj)"
        }

        var out = lines.joined(separator:"\n")

        for b in self.bindings {
            out += "    BIND \(b.source).\(b.sourceSlot) TO \(b.target)\n"
        }
        return out
    }
}

