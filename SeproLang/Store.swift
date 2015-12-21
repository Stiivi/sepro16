//
//  Store.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 25/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

protocol _BasicStore {
    /** Reference of the root object. */
    var rootReference: ObjectRef { get }

    /**
     - Returns: References to all objects in the store.
     */
    var allReferences: ObjectRefSequence { get }

    /**
     - Returns: Object with referenec `ref` or `nil` if such object does not
     exist.
     */
    func objectByReference(ref: ObjectRef) -> Object?
}

/**
Container representing the state of the world.
*/
public class Store: _BasicStore {
    /// The object memory
    var container: [ObjectRef:Object]

    /// Internal sequence for object references
    var refSequence: Int = 1

    /// Reference to the root object in the object memory
    // TODO: make this private
    var root: ObjectRef!
    var rootReference: ObjectRef {
        get { return self.root }
    }

    public init() {
        self.container = [ObjectRef:Object]()
        self.root = nil
    }

    public func removeAll() {
        self.container.removeAll()
    }

    /**
     - Returns: References to all objects in the store.
     */
    public var allReferences: ObjectRefSequence {
        return ObjectRefSequence(self.container.keys)
    }

    /**
    - Returns: Object referenced by reference `ref` or `nil` if no such object
     exists.
    */
    public func objectByReference(ref:ObjectRef) -> Object? {
        return self.container[ref]
    }

    public subscript(ref: ObjectRef) -> Object? {
        return self.objectByReference(ref)
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
        Evaluates the predicate against object.
        - Returns: `true` if the object matches the predicate
    */
    public func predicateMatches(predicate:Predicate, ref: ObjectRef) -> Bool {
        if let object = self.container[ref] {
            return self.predicateMatches(predicate, object: object)
        }
        else {
            return false
        }
    }

    public func predicateMatches(predicate:Predicate, object: Object) -> Bool {
        var target: Object

        // Try to get the target slot
        //
        if predicate.isIndirect {
            if let ref = object.bindings[predicate.inSlot!] {
                target = self.container[ref]!
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
        if let object = self.container[ref] {
            return predicates.all {
                predicate in
                self.predicateMatches(predicate, object: object)
            }
        }
        else {
            return false
        }
    }

    public func select(predicates:[Predicate]?=nil,
        references:ObjectRefSequence?=nil) -> ObjectSelection {
            return ObjectSelection(store: self, predicates: predicates, references: references)
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
                    let match = self.store.predicatesMatch(self.predicates!,
                                                            ref: ref!)
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

