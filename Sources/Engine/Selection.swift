//
//  Selection.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 17/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Model

public enum Ordering {
    /// As containerd in the container, might differ between requests
    case natural
    /// Randomized ordering, differs between requests
    case randomized
}

/*
    Note on selections: Selection yields references that are present in the
    simulation at the query time. Therefore if selection contains references
    to objects that are no longer part of the simulation, those objects will
    be skipped.
*/

public typealias ReferenceIterator = AnyIterator<ObjectReference>
public class ObjectSelection: Sequence
{
    let references: [ObjectReference]?
    let container: Container
    let predicates: CompoundPredicate?

    init(container: Container, predicates: CompoundPredicate?=nil,
         references: [ObjectReference]?=nil)
    {

        self.container = container
        self.predicates = predicates
        self.references = references
    }

    public func makeIterator() -> ReferenceIterator {
        // FIXME: THIS IS JUST TO MAKE COMPILER HAPPY, IT DOES NOT WORK!!!
        if predicates != nil {
            return AnyIterator(FilteringSelectionIterator(self))
        }
        else {
            return AnyIterator(ConcreteSelectionIterator(self))
        }
    }

}

public class ConcreteSelectionIterator: IteratorProtocol {
    public typealias Element = ObjectReference

    private let selection: ObjectSelection
    private var iterator: Array<ObjectReference>.Iterator

    public init(_ selection: ObjectSelection){
        precondition(selection.references != nil)
        self.selection = selection
        self.iterator = selection.references!.makeIterator()
    }
    
    public func next() -> Element? {
        while let ref = iterator.next() {
            if selection.container.exists(ref) {
                return ref
            }
        }
        return nil
    }
}


public class FilteringSelectionIterator: IteratorProtocol {
    public typealias Element = ObjectReference

    private let selection: ObjectSelection
    private var iterator: Array<ObjectReference>.Iterator

    public init(_ selection: ObjectSelection){
        precondition(selection.references != nil)
        precondition(selection.predicates != nil)
        self.selection = selection
        self.iterator = selection.references!.makeIterator()
    }
    
    public func next() -> Element? {
        // TODO: we resolve ref but then we pass ref to resolve it again
        while let ref = self.iterator.next() {
            if selection.container.exists(ref)
                    && selection.container.match(ref, predicates:selection.predicates!){
                return ref
            }
        }
        return nil
    }
}
