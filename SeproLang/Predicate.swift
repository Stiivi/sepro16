//
//  Predicate.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 29/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//


public enum PredicateType: CustomStringConvertible {
    /// Triggers every time the engine encounters it
    case All
    /**
     Condition that is satisfied when examined object has all of the
     tags from the `tagList` set.
     */
    case TagSet(TagList)
    /**
     Condition that is satisfied when examined object has none of the
     tags from the `tagList` set.
     */
    case TagUnset(TagList)
    /**
     Condition that is satisfied when a measure of tested object is
     less or than a given value.
     */
    case CounterLess(Symbol, CounterType)
    /**
     Condition that is satisfied when a measure of tested object is
     greater or than a given value.
     */
    case CounterGreater(Symbol, CounterType)
    /**
     Condition that is satisfied when a measure of tested object is
     zero.
     */
    case CounterZero(Symbol)
    /// Checks whether a slot is bound
    case IsBound(Symbol)

    public var description: String {
        switch self {
        case .All:
            return "ALL"

        case .TagSet(let tags):
            return "SET " + tags.joinWithSeparator(", ")

        case .TagUnset(let tags):
            return "UNSET " + tags.joinWithSeparator(", ")

        case .CounterLess(let counter, let value):
            return "\(counter) < \(value)"

        case .CounterGreater(let counter, let value):
            return "\(counter) > \(value)"

        case .CounterZero(let counter):
            return "ZERO \(counter)"

        case .IsBound(let slot):
            return "BOUND \(slot)"
        }
    }

}

public struct Predicate {
    public let type: PredicateType
    public let isNegated: Bool
    public let inSlot: Symbol?

    public init(_ type: PredicateType, _ isNegated:Bool=false, inSlot:Symbol?=nil) {
        self.type = type
        self.isNegated = isNegated
        self.inSlot = inSlot
    }

    /**
     Evaluate predicate on `object`.
     
     - Returns: `true` if `object` matches predicate, otherwise `false`
     */
    public func evaluate(object: Object) -> Bool {
        let result: Bool

        switch self.type {
        case .All:
            result = true

        case .TagSet(let tags):
            result = tags.isSubsetOf(object.tags)

        case .TagUnset(let tags):
            result = tags.isDisjointWith(object.tags)

        case .CounterLess(let counter, let value):
            if let counterValue = object.counters[counter] {
                result = counterValue < value
            }
            else {
                // TODO: Shouldn't we return false or have invalid state?
                result = false
            }

        case .CounterGreater(let counter, let value):
            if let counterValue = object.counters[counter] {
                result = counterValue > value
            }
            else {
                // TODO: Shouldn't we return false or have invalid state?
                result = false
            }

        case .CounterZero(let counter):
            if let counterValue = object.counters[counter] {
                result = counterValue == 0
            }
            else {
                // TODO: Shouldn't we return false or have invalid state?
                result = false
            }

        case .IsBound(let slot):
            result = object.links[slot] != nil
        }

        // Apply the negation
        return !self.isNegated && result || self.isNegated && !result
    }
}

