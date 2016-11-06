//
//  Selection.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 17/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Model

/*
    Note on selections: Selection yields references that are present in the
    simulation at the query time. Therefore if selection contains references
    to objects that are no longer part of the simulation, those objects will
    be skipped.
*/

public enum SelectionType {
    case concrete([ObjectReference])
    case filter([Predicate])
}

public class ObjectSelection: Sequence
{
    /// Container that owns the selection
    let container: Container

    let type: SelectionType

    /// Creates a new object selection.
    ///
    /// - Parameter container: container owning the selection
    /// - Parameter predicates: list of predicates that the objects in the
    /// selection satisfy. If not provided, then all objects are considered.
    /// - Parameter: references: iterator of object references from the owning
    /// container. If not provided, then all objects within the container are
    /// assumed.
    public init(container: Container, type: SelectionType)
    {
        self.container = container
        self.type = type
    }
    public convenience init(container: Container, predicates: [Predicate] = []) {
        self.init(container: container, type: .filter(predicates))
    }

    public func makeIterator() -> ReferenceIterator {
        switch type {
        case let .concrete(references):
            let existing = references.lazy.filter {
                self.container.exists($0)
            }
            return AnyIterator(existing.makeIterator())

        case let .filter(predicates):
            let references = self.container.allReferences.lazy
            // 
            if predicates.isEmpty {
                let existing = references.lazy.filter {
                    self.container.exists($0)
                }
                return AnyIterator(existing.makeIterator())
            }
            else {
                let filtered = references.filter {
                    self.container.exists($0)
                        && self.container.match($0, predicates:predicates)
                }
                return AnyIterator(filtered.makeIterator())
            }
        }
    }

}

