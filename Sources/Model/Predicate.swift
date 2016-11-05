//
//  Predicate.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 29/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//


public enum PredicateType: CustomStringConvertible, Equatable {
    /// Triggers every time the engine encounters it
    case all
    /**
     Condition that is satisfied when examined object has all of the
     tags from the `tagList` set.
     */
    case tagSet(TagList)
//    /**
//     Condition that is satisfied when a measure of tested object is
//     less or than a given value.
//     */
//    case CounterLess(Symbol, CounterType)
//    /**
//     Condition that is satisfied when a measure of tested object is
//     greater or than a given value.
//     */
//    case CounterGreater(Symbol, CounterType)
    /**
     Condition that is satisfied when a measure of tested object is
     zero.
     */
    case counterZero(Symbol)
    /// Checks whether a slot is bound
    case isBound(Symbol)

    public var description: String {
        switch self {
        case .all:
            return "ALL"

        case .tagSet(let tags):
            // We can ommit the SET
            return tags.joined(separator:", ")

        case .counterZero(let counter):
            return "ZERO \(counter)"

        case .isBound(let slot):
            return "BOUND \(slot)"
        }
    }

}

public func ==(left: PredicateType, right: PredicateType) -> Bool {
    switch (left, right) {
    case (.all, .all): return true
    case (.tagSet(let ltags), .tagSet(let rtags)) where ltags == rtags:
            return true
    case (.counterZero(let lcount), .counterZero(let rcount)) where lcount == rcount:
            return true
    case (.isBound(let lslot), .isBound(let rslot)) where lslot == rslot:
            return true
    default:
        return false
    }
}


public struct Predicate: Equatable {
    public let type: PredicateType
    public let isNegated: Bool
    public let inSlot: Symbol?

    public var isIndirect: Bool {
        get { return inSlot != nil }
    }

    public init(_ type: PredicateType, _ isNegated:Bool=false, inSlot:Symbol?=nil) {
        self.type = type
        self.isNegated = isNegated
        self.inSlot = inSlot
    }

}

extension Predicate: CustomStringConvertible {
    public var description: String {
        var desc = ""
        if self.isNegated {
            desc += "NOT "
        }
        if let slot = self.inSlot {
            desc += "IN \(slot)"
        }
        return desc + self.type.description
    }
}


public func ==(left: Predicate, right: Predicate) -> Bool {
    return left.type == right.type
            && left.isNegated == right.isNegated
            && left.inSlot == right.inSlot
}

public typealias CompoundPredicate = [Predicate]
