//
//  Store.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 25/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

/**
Container representing the state of the world.
*/
public class Store {
    /// The object memory
    var container: [ObjectRef:Object]

    /// Internal sequence for object references
    var refSequence: Int = 1

    /// Reference to the root object in the object memory
    // TODO: make this private
    public var root: ObjectRef!

    public init() {
        self.container = [ObjectRef:Object]()
        self.root = nil
    }

    public func removeAll() {
        self.container.removeAll()
    }

    public var allReferences: AnySequence<ObjectRef> {
        return AnySequence(self.container.keys)
    }

    /**
     Adds an `object` to the store container.

     - Returns: object reference of the added object
    */
    public func addObject(object:Object) -> ObjectRef {
        let ref = refSequence

        let internalized = object
        internalized.id = ref
        self.container[ref] = internalized
        self.refSequence += 1

        return ref
    }

    /// Set the root object reference to `ref`
    public func setRootRef(ref:ObjectRef) {
        self.root = ref
    }

    /**
    - Returns: instance of the root object.
    */
    public func getRoot() -> Object {
        // Note: this must be fullfilled
        return self[self.root]!
    }


    /**
    - Returns: sequence of all object references
    */
    public func getObject(ref:ObjectRef) -> Object? {
        return self.container[ref]
    }

    public subscript(ref: ObjectRef) -> Object? {
        return self.getObject(ref)
    }

    /**
     Iterates through all objects matching `predicates`. If no predicates are
     provided then all objects are iterated.

     - Parameters:
        - predicates: optional list of predicates
     - Note: Order is implementation specific and is not guaranteed
       neigher between implementations or even between distinct calls
       of the method even without state change of the store.

     - Returns: a sequence-like object representing the selection of objects
     */
    public func select(predicates:[Predicate]?=nil) -> ObjectSequence {
        return ObjectSequence(store: self, predicates: predicates)
    }

    /**
        Evaluates the predicate against object.
        - Returns: `true` if the object matches the predicate
    */
    public func evaluate(predicate:Predicate,_ ref: ObjectRef) -> Bool {
        if let object = self.container[ref] {
            var target: Object

            // Try to get the target slot
            //
            if predicate.inSlot != nil {
                if let maybeTarget = object.links[predicate.inSlot!] {
                    target = self.container[maybeTarget]!
                }
                else {
                    // TODO: is this OK if the slot is not filled and the condition is
                    // negated?
                    return false
                }
            }
            else {
                target = object
            }
            return predicate.evaluate(target)
        }
        else {
            // TODO: Exception?
            return false
        }
    }
}

public struct ObjectSequence: SequenceType {
    public let predicates: [Predicate]?
    public let store: Store

    public init(store: Store, predicates: [Predicate]?=nil) {
        self.store = store
        self.predicates = predicates
    }

    public class Generator: AnyGenerator<Object> {
        var generator: AnyGenerator<ObjectRef>
        let store: Store
        let predicates: [Predicate]?

        init(sequence: ObjectSequence) {
            self.store = sequence.store
            self.predicates = sequence.predicates
            self.generator = AnySequence(store.container.keys).generate()
            super.init()
        }

        public override func next() -> Object? {
            var ref = self.generator.next()

            if self.predicates != nil {
                while(ref != nil) {
                    let match = self.predicates!.all {
                            predicate in
                            self.store.evaluate(predicate, ref!)
                        }

                    if match {
                        break
                    }

                    ref = self.generator.next()
                }
            }

            if ref != nil {
                return self.store.container[ref!]
            }
            else {
                return nil
            }
        }
    }

    public func generate() -> ObjectSequence.Generator {
        return ObjectSequence.Generator(sequence: self)
    }
}

