//
//  Object.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 30/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Model

/** List of object references */
public typealias ObjectReferenceSequence = AnySequence<ObjectReference>
/** Named object references */
public typealias ObjectMap = [Symbol:ObjectReference]

/// Simulation object.
///
/// - Note: This structure serves only as an interface between the
///   engine and it's external environment. Since the structure might
///   not be memory or time efficient, it recommended to consider
///   different internal representation of an object or collection
///   of objects in custom engine implementation.

public class Object: CustomStringConvertible, CustomDebugStringConvertible {
    /// Object identifier
    public let id: ObjectReference?
    /// Tags that are set
    public let tags: TagList
    /// Counter values
    public let counters: CounterDict
    /// References to other objects
    public let bindings: [Symbol:ObjectReference]
    public let slots: SlotList

    // TODO: isDead

    public init(_ id: ObjectReference?=nil, tags: TagList=[], counters:
        CounterDict=[:], bindings: [Symbol:ObjectReference]=[:], slots:
            SlotList=[]) {
        self.id = id
        self.tags = tags
        self.counters = counters
        self.bindings = bindings
        self.slots = slots
    }

    /// Create a copy of the object and allow override of object's properties.
    public func copy(id: ObjectReference?=nil, tags: TagList?=nil,
            counters: CounterDict?=nil, bindings: [Symbol:ObjectReference]?=nil,
            slots: SlotList?=nil) -> Object {

        return Object(id ?? self.id,
            tags: tags ?? self.tags,
            counters: counters ?? self.counters,
            bindings: bindings ?? self.bindings,
            slots: slots ?? self.slots
        )

    }

    public var description: String {
        get {
            let links = self.bindings.map(){ (key, value) in "\(key)->\(value)" }
                            .joined(separator:", ")
            let tagsStr = self.tags.map { String($0)}.joined(separator:", ")
            let idString = id.map { String(describing:$0) } ?? "NOID"
            return "\(idString)[\(tagsStr);\(links)]"
        }
    }

    public var debugDescription: String {
        return self.description
    }
}
