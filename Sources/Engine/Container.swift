//
//	Container.swift
//	SeproLang
//
//	Created by Stefan Urbanek on 25/11/15.
//	Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Model

/// Container representing the state of the world.
///
public final class Container {
	/// The object memory
	var contents: [ObjectRef:Object]

	/// Internal sequence for object references
	var refSequence: Int = 1

	/// Reference to the root object in the object memory
	// TODO: make this private
	public var root: ObjectRef

	public init() {
		self.contents = [ObjectRef:Object]()
		self.root = 0
	}

	/// Remove all objects in the container.
	public func removeAll() {
		self.contents.removeAll()
	}

	/// - Returns: References to all objects in the container.
	///
	public var allReferences: ObjectRefSequence {
		return ObjectRefSequence(self.contents.keys)
	}

	/// - Returns: Object referenced by reference `ref` or `nil` if no such object
	///   exists.
	///
	public func getObject(_ ref:ObjectRef) -> Object? {
		return self.contents[ref]
	}

	public subscript(ref: ObjectRef) -> Object? {
		return self.getObject(ref)
	}


	/// Creates an object in the container.
	/// - Returns: object reference of the new object
	///
    public func createObject(tags: TagList=[], counters: CounterDict=[:],
			slots: SlotList=[]) -> ObjectRef {
		let obj = Object(refSequence)

		obj.tags = tags
		obj.counters = counters
		obj.slots = slots

		self.contents[obj.id] = obj

		refSequence += 1

		return obj.id
	}

	/// Evaluates the predicate against object.
	/// - Returns: `true` if the object matches the predicate
	///
	public func predicateMatches(predicate:Predicate, ref: ObjectRef) -> Bool {
		if let object = self.contents[ref] {
			return self.predicateMatches(predicate: predicate, object: object)
		}
		else {
			return false
		}
	}

	// TODO: remove, all Object methods
	public func predicateMatches(predicate:Predicate, object: Object) -> Bool {
		var target: Object

		// Try to get the target slot
		//
		if predicate.isIndirect {
			if let ref = object.bindings[predicate.inSlot!] {
				target = self.contents[ref]!
			}
			else {
				return false
			}
		}
		else {
			target = object
		}
		return predicate.matchesObject(object: target)
	}

	// TODO: weird name
	public func predicatesMatch(predicates: CompoundPredicate, ref: ObjectRef) -> Bool {
		if let object = self.contents[ref] {
			return predicates.all {
				predicate in
				self.predicateMatches(predicate: predicate, object: object)
			}
		}
		else {
			return false
		}
	}

	/// Creates a selection representing objects described by selecetor `Selector`
	public func select(_ selector: Selector=Selector.All) -> ObjectSelection {
		switch selector {
		case .All:
			return ObjectSelection(container: self)
		case .Filter(let predicates):
			return ObjectSelection(container: self, predicates: predicates)
		case .Root(let predicates):
			let references = AnySequence([self.root])
			return ObjectSelection(container: self, predicates: predicates, references: references)
		}
	}
	
}
