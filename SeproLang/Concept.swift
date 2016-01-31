//
//  Concept.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 19/01/16.
//  Copyright © 2016 Stefan Urbanek. All rights reserved.
//

// Note: eventhough the counter type is specified as Int, it should be
// unsigned. Use of Int follows the Swift language recommendation. See
// the discussion about UInt unsigned integers in the language
// reference.
public typealias CounterType = Int
public typealias SymbolList = [Symbol]

// FIXME: remove these two
public typealias SlotList = SymbolList
public typealias TagList = Set<Symbol>

public typealias CounterDict = [Symbol:Int]

/// Representation of a concept. Concept is the main model entity.
///
public class Concept: CustomStringConvertible {
    public let name: String
    /// Dictionary of counters
    public let counters: CounterDict
    /// Dictionary of slots
    public let slots: SlotList
    /// Dictionary of tags
    public let tags: TagList

    /// Initializes the concept.
    ///
    /// - Parameters:
    ///     - counters: Dictionary of counters and their initial values.
    ///     - slots: List of slot symbols (unbound on initialization).
    ///     - tags: List of tags present when object is instantiated.
    ///
    public init(name:Symbol,
                 counters:CounterDict?=nil,
                 slots:SlotList?=nil,
                 tags:TagList?=nil){

        self.name = name
        self.counters = counters ?? CounterDict()
        self.slots = slots ?? SlotList()
        self.tags = tags ?? TagList()
    }

    /// Short description of the concept.
    public var description: String {
        get {
            return "CONCEPT(\(self.name))"
        }
    }

    /// Convert the concept to a model string.
    ///
    public func asString() -> String {
        var desc = "CONCEPT \(self.name)\n"
        if !self.counters.isEmpty {
            for (counter, value) in counters {
                desc += "    COUNTER \(counter) = \(value)\n"
            }
        }
        if !self.tags.isEmpty {
            let list = tags.joinWithSeparator(", ")
            desc += "    TAG \(list)\n"
        }
        if !self.slots.isEmpty {
            let list = slots.joinWithSeparator(", ")
            desc += "    SLOT \(list)\n"
        }
        return desc
    }
}

