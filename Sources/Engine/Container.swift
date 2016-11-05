//
//	Container.swift
//	SeproLang
//
//	Created by Stefan Urbanek on 25/11/15.
//	Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Model

/// Reference to an object within it's owning container.
///
public struct ObjectReference: Hashable, CustomStringConvertible {
    public typealias Sequence
                    = UnfoldSequence<ObjectReference, (ObjectReference?, Bool)>

    private let id: Int

    /// Creates a reference from an integer.
    public init(_ id: Int) { self.id = id }
    public var hashValue: Int { return id }
    public var description: String { return String(id) }

    /// Create a sequence generating object references.
    static func sequence(start: Int=0) -> Sequence {
        let nextValue: (ObjectReference) -> ObjectReference? = {
            ref in ObjectReference(ref.id + 1)
        }
        return Swift.sequence(first: ObjectReference(0), next: nextValue)
    }

    public static func ==(lhs: ObjectReference, rhs: ObjectReference) -> Bool {
        return lhs.id == rhs.id
    }
}


/// Object container.
public protocol Container {
    /// Insert clone of the `object` into the container and return it's new
    /// reference.
    ///
    /// - Note: If the `object` has already assigned a reference it will be
    /// ignored and new object instance with new reference will be created.
    @discardableResult
	func insert(object: Object) -> ObjectReference

    /// Remove an object with given reference.
    ///
    /// - Returns: Removed object.
    /// TODO: What about dependencies?
    // @discardableResult
	// func remove(reference: ObjectReference) -> Object

    /// Remove all objects in the container.
	func removeAll()

    /// Update an object.
    ///
    /// If object reference does not exist in the container, nothing happens.
    ///
    /// - Returns: `true` if object was updated, `false` if object does not
    /// exist in the container.
    @discardableResult
    func update(object: Object) -> Bool

    /// Returns `true` if the object reference is valid and the object exists.
    func exists(_ reference: ObjectReference) -> Bool

    /// Returns object by reference.
	subscript(_ reference: ObjectReference) -> Object? { get }

    /// Returns an object selection representing all objects in the container.
	func selectAll() -> ObjectSelection

    /// Returns object selection where objects are matching `selector`.
	func select(_ selector: Selector) -> ObjectSelection

    /// Returns `true` if the object with reference matches all `predicates`.
    func match(_ reference: ObjectReference, predicates: [Predicate]) -> Bool
}

/// Container representing the state of the world.
///
public final class SimpleContainer: Container {
	
	/// The object memory
	var contents: [ObjectReference:Object]
    // var graph: LabelledDirectedGraph<ObjectReference, String>

	/// Internal sequence for object references
	var referenceSequence: ObjectReference.Sequence

	public init() {
		contents = [:]
        referenceSequence = ObjectReference.sequence()
	}

	/// Remove all objects in the container.
	public func removeAll() {
		contents.removeAll()
	}

	/// - Returns: References to all objects in the container.
	///
	public var allReferences: AnyCollection<ObjectReference> {
		return AnyCollection(contents.keys)
	}

	/// - Returns: Object referenced by reference `ref` or `nil` if no such object
	///   exists.
	///
    public subscript(ref: ObjectReference) -> Object? {
        return contents[ref]
    }

    public func exists(_ reference: ObjectReference) -> Bool {
        return contents[reference] != nil
    }

	/// Inserts object into the container and returns an ID of inserted object.
    ///
	/// - Returns: object reference of the new object
	///
    public func insert(object: Object) -> ObjectReference {
        let ref = referenceSequence.next()!
        let obj = object.copy(id: ref)

		self.contents[ref] = obj

		return ref
	}

    public func update(object: Object) -> Bool {
        guard let ref = object.id, exists(ref) else {
            return false
        }

        self.contents[ref] = object

		return true
	}

	/// Evaluates the predicate against object.
	/// - Returns: `true` if the object matches the predicate
	///
	public func predicateMatches(predicate:Predicate, ref: ObjectReference) -> Bool {
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
    /// Returns `true` if the object with reference matches all predicates.
	public func match(_ ref: ObjectReference, predicates: CompoundPredicate) -> Bool {
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

    public func selectAll() -> ObjectSelection {
        return ObjectSelection(container: self)
    }
    
	/// Creates a selection representing objects described by selecetor `Selector`
	public func select(_ selector: Selector=Selector.all) -> ObjectSelection {
		switch selector {
		case .all:
			return selectAll()
		case .filter(let predicates):
			return ObjectSelection(container: self, predicates: predicates)
		}
	}
	
}
