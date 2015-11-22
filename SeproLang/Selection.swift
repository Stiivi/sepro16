//
//  Selection.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 17/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public typealias ObjectSelection = AnySequence<Object>
public typealias ObjectRefSelection = AnySequence<ObjectRef>

public enum Ordering {
    /// As stored in the store, might differ between requests
    case Natural

    /// Randomized ordering, differs between requests
    case Randomized
}

public struct Selection: SequenceType {
    public let predicates: [Predicate]?
    public let store: Store

    public init(store: Store, predicates: [Predicate]?=nil) {
        self.store = store
        self.predicates = predicates
    }

    public class Generator: AnyGenerator<Object> {
        var generator: AnyGenerator<Object>
        let store: Store
        let selection: Selection

        init(selection: Selection) {
            self.selection = selection
            self.store = selection.store
            self.generator = selection.store.objects.generate()
            super.init()
        }
        public override func next() -> Object? {
            var object: Object!

            object = self.generator.next()

            if self.selection.predicates != nil {
                while(object != nil) {
                    let match = self.selection.predicates!.all {
                            predicate in
                            self.store.evaluate(predicate, object.id)
                        }

                    if match {
                        break
                    }

                    object = self.generator.next()
                }
            }

            return object
        }
    }

    public func generate() -> Selection.Generator {
        return Selection.Generator(selection: self)
    }
}
