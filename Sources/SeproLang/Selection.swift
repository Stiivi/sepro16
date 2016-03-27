//
//	Selection.swift
//	SeproLang
//
//	Created by Stefan Urbanek on 17/11/15.
//	Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public enum Ordering {
	/// As containerd in the container, might differ between requests
	case Natural

	/// Randomized ordering, differs between requests
	case Randomized
}

/*
	Note on selections: Selection yields objects that are present in the
	computation at the query time. Therefore if selection contains references
	to objects that are no longer part of the simulation, those objects will
	be skipped.
*/

public typealias _ObjectSequence = AnySequence<Object>
public typealias _RefSequence = AnySequence<ObjectRef>

public struct ObjectSelection: Sequence {
	public typealias Iterator = AnyIterator<Object>

	let _actualSelection: AnySequence<Object>

	init(container: Container, predicates: CompoundPredicate?=nil,
		 references: ObjectRefSequence?=nil) {
		let actualReferences: ObjectRefSequence

		actualReferences = references ?? container.allReferences

		if predicates == nil {
			self._actualSelection = AnySequence(ConcreteSelection(container: container,
									 references: actualReferences))
		}
		else {
			self._actualSelection = AnySequence(FilteredSelection(container: container,
									 predicates: predicates!,
									 references: actualReferences))
		}
	}

	public func makeIterator() -> Iterator {
		return AnyIterator(self._actualSelection.makeIterator())
	}

}

/** Selection of concrete or all objects */
public class ConcreteSelection: Sequence {
	public typealias Iterator = ConcreteSelectionIterator

	let container: Container
	let references: ObjectRefSequence

	public init(container: Container, references: ObjectRefSequence) {
		self.container = container
		self.references = references
	}

	public func makeIterator() -> Iterator {
		return ConcreteSelectionIterator(container: self.container, iterator: references.makeIterator())
	}
}

public class ConcreteSelectionIterator: IteratorProtocol {
	public typealias Element = Object

	private let container: Container
	private var iterator: ObjectRefSequence.Iterator

	public init(container: Container, iterator: ObjectRefSequence.Iterator) {
		self.container = container
		self.iterator = iterator
	}
	
	public func next() -> Element? {
		while let ref = self.iterator.next() {
			// See description of selection why we ignore dead
			// references
			if let object = self.container[ref]{
				return object
			}
		}
		return nil
	}
}

/** Selection of all objects in the container */
public struct FilteredSelection: Sequence {
	public typealias Iterator = FilteredSelectionIterator

	public let container: Container
	public let predicates: CompoundPredicate
	let references: ObjectRefSequence

	init(container: Container, predicates: CompoundPredicate, references: ObjectRefSequence?=nil) {
		self.container = container
		self.predicates = predicates
		let references = references ?? container.allReferences
		// FIXME: this is temporary
		self.references = AnySequence(Array(references).shuffle())
	}

	public func makeIterator() -> Iterator {
		return FilteredSelectionIterator(container: self.container,
			iterator: self.references.makeIterator(),
			predicates: self.predicates)
	}
}

public class FilteredSelectionIterator: IteratorProtocol {
	public typealias Element = Object

	private let container: Container
	private var iterator: ObjectRefSequence.Iterator
	private let predicates: CompoundPredicate

	public init(container: Container, iterator: ObjectRefSequence.Iterator,
		predicates: CompoundPredicate) {
			self.container = container
			self.iterator = iterator
			self.predicates = predicates
	}
	
	public func next() -> Element? {
		// TODO: we resolve ref but then we pass ref to resolve it again
		while let ref = self.iterator.next() {
			if let object = self.container[ref]
				where self.container.predicatesMatch(self.predicates, ref: ref){
					return object
			}
		}
		return nil
	}
}


