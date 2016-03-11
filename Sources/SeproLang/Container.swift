//
//	Container.swift
//	SeproLang
//
//	Created by Stefan Urbanek on 25/11/15.
//	Copyright © 2015 Stefan Urbanek. All rights reserved.
//

/// Container representing the state of the world.
///
public final class Container {
	/// The object memory
	var contents: [ObjectRef:Object]

	/// Internal sequence for object references
	var refSequence: Int = 1

	/// Reference to the root object in the object memory
	// TODO: make this private
	var root: ObjectRef

	public var rootReference: ObjectRef {
		return self.root
	}

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
	public func objectByReference(ref:ObjectRef) -> Object? {
		return self.contents[ref]
	}

	public subscript(ref: ObjectRef) -> Object? {
		return self.objectByReference(ref)
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

	/// Set the root object reference to `ref`
	public func setRootRef(ref:ObjectRef) {
		self.root = ref
	}

	/**
	- Returns: instance of the root object.
	TODO: Remove
	*/
	public func getRoot() -> Object {
		// Note: this must be fullfilled
		return self[self.root]!
	}

	/**
		Evaluates the predicate against object.
		- Returns: `true` if the object matches the predicate
	*/
	public func predicateMatches(predicate:Predicate, ref: ObjectRef) -> Bool {
		if let object = self.contents[ref] {
			return self.predicateMatches(predicate, object: object)
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
		return predicate.matchesObject(target)
	}

	public func predicatesMatch(predicates: CompoundPredicate, ref: ObjectRef) -> Bool {
		if let object = self.contents[ref] {
			return predicates.all {
				predicate in
				self.predicateMatches(predicate, object: object)
			}
		}
		else {
			return false
		}
	}

	/// Creates a selection representing objects described by selecetor `Selector`
	public func select(selector: Selector=Selector.All) -> ObjectSelection {
		switch selector {
		case .All:
			return ObjectSelection(container: self)
		case .Filter(let predicates):
			return ObjectSelection(container: self, predicates: predicates)
		case .Root(let predicates):
			let references = AnySequence([self.rootReference])
			return ObjectSelection(container: self, predicates: predicates, references: references)
		}
	}
	
}
