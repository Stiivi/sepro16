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

public struct ObjectSelection: SequenceType {
	public typealias Generator = AnyGenerator<Object>

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

	public func generate() -> Generator {
		return AnyGenerator(self._actualSelection.generate())
	}

}

/** Selection of concrete or all objects */
public class ConcreteSelection: SequenceType {
	public typealias Generator = ConcreteSelectionGenerator

	let container: Container
	let references: ObjectRefSequence

	public init(container: Container, references: ObjectRefSequence) {
		self.container = container
		self.references = references
	}

	public func generate() -> Generator {
		return Generator(container: self.container, generator: references.generate())
	}
}

public class ConcreteSelectionGenerator: GeneratorType {
	public typealias Element = Object

	private let container: Container
	private var generator: ObjectRefSequence.Generator

	public init(container: Container, generator: ObjectRefSequence.Generator) {
		self.container = container
		self.generator = generator
	}
	
	public func next() -> Element? {
		while let ref = self.generator.next() {
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
public struct FilteredSelection: SequenceType {
	public typealias Generator = FilteredSelectionGenerator

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

	public func generate() -> Generator {
		return FilteredSelectionGenerator(container: self.container,
			generator: self.references.generate(),
			predicates: self.predicates)
	}
}

public class FilteredSelectionGenerator: GeneratorType {
	public typealias Element = Object

	private let container: Container
	private var generator: ObjectRefSequence.Generator
	private let predicates: CompoundPredicate

	public init(container: Container, generator: ObjectRefSequence.Generator,
		predicates: CompoundPredicate) {
			self.container = container
			self.generator = generator
			self.predicates = predicates
	}
	
	public func next() -> Element? {
		// TODO: we resolve ref but then we pass ref to resolve it again
		while let ref = self.generator.next() {
			if let object = self.container[ref]
				where self.container.predicatesMatch(self.predicates, ref: ref){
					return object
			}
		}
		return nil
	}

}


