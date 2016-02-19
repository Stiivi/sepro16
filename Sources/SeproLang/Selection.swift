//
//  Selection.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 17/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public enum Ordering {
    /// As stored in the store, might differ between requests
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

    init(store: Store, predicates: CompoundPredicate?=nil,
         references: ObjectRefSequence?=nil) {
        let actualReferences: ObjectRefSequence

        actualReferences = references ?? store.allReferences

        if predicates == nil {
            self._actualSelection = AnySequence(ConcreteSelection(store: store,
                                     references: actualReferences))
        }
        else {
            self._actualSelection = AnySequence(FilteredSelection(store: store,
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

    let store: Store
    let references: ObjectRefSequence

    public init(store: Store, references: ObjectRefSequence) {
        self.store = store
        self.references = references
    }

    public func generate() -> Generator {
        return Generator(store: self.store, generator: references.generate())
    }
}

public class ConcreteSelectionGenerator: GeneratorType {
    public typealias Element = Object

    private let store: Store
    private var generator: ObjectRefSequence.Generator

    public init(store: Store, generator: ObjectRefSequence.Generator) {
        self.store = store
        self.generator = generator
    }
    
    public func next() -> Element? {
        while let ref = self.generator.next() {
            // See description of selection why we ignore dead
            // references
            if let object = self.store[ref]{
                return object
            }
        }
        return nil
    }
}

/** Selection of all objects in the store */
public struct FilteredSelection: SequenceType {
    public typealias Generator = FilteredSelectionGenerator

    public let store: Store
    public let predicates: CompoundPredicate
    let references: ObjectRefSequence

    init(store:Store, predicates: CompoundPredicate, references: ObjectRefSequence?=nil) {
        self.store = store
        self.predicates = predicates
        let references = references ?? store.allReferences
        // FIXME: this is temporary
        self.references = AnySequence(Array(references).shuffle())
    }

    public func generate() -> Generator {
        return FilteredSelectionGenerator(store: self.store,
            generator: self.references.generate(),
            predicates: self.predicates)
    }
}

public class FilteredSelectionGenerator: GeneratorType {
    public typealias Element = Object

    private let store: Store
    private var generator: ObjectRefSequence.Generator
    private let predicates: CompoundPredicate

    public init(store: Store, generator: ObjectRefSequence.Generator,
        predicates: CompoundPredicate) {
            self.store = store
            self.generator = generator
            self.predicates = predicates
    }
    
    public func next() -> Element? {
        // TODO: we resolve ref but then we pass ref to resolve it again
        while let ref = self.generator.next() {
            if let object = self.store[ref]
                where self.store.predicatesMatch(self.predicates, ref: ref){
                    return object
            }
        }
        return nil
    }

}


