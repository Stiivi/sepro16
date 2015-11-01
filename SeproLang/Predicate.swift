//
//  Predicate.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 29/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public protocol Predicate {
    /**
     Evaluate predicate on `object`.
     
     - Returns: `true` if `object` matches predicate, otherwise `false`
     */
    func evaluate(object: Object) -> Bool
}

/// Triggers every time the engine encounters it
public class AllPredicate: Predicate, CustomStringConvertible {
    public var description:String {
        return "ALL"
    }

    public func evaluate(object: Object) -> Bool {
        return true
    }
}

/// Abstract base class for conditions by object state
public class ObjectPredicate: Predicate {
    public let isNegated:Bool
    public let inSlot:Symbol?

    init(inSlot: Symbol?=nil, isNegated:Bool=false) {
        self.inSlot = inSlot
        self.isNegated = isNegated
    }

    public func evaluate(object: Object) -> Bool {
        return false
    }
}

/// Checks whether a slot is bound
public class IsBoundPredicate: ObjectPredicate {
    public let slot:Symbol

    init(slot: Symbol, inSlot: Symbol?=nil, isNegated:Bool=false) {
        self.slot = slot
        super.init(inSlot: inSlot, isNegated: isNegated)
    }

    public override func evaluate(object: Object) -> Bool {
        let result = object.links[self.slot] != nil
        return !self.isNegated && result || self.isNegated && !result
    }

}

/**
    Condition that is satisfied when examined object has all of the tags from
    the `tagList` set.
*/
public class TagPredicate: ObjectPredicate {
    public let tags:TagList

    init(tags: TagList, inSlot: Symbol?=nil, isNegated:Bool=false) {
        self.tags = tags
        super.init(inSlot: inSlot, isNegated: isNegated)
    }

}

public class TagSetPredicate: TagPredicate, CustomStringConvertible {
    public var description:String {
        return "SET " + tags.joinWithSeparator(", ")
    }

    public override func evaluate(object: Object) -> Bool {
        let result = self.tags.isSubsetOf(object.tags)
        return !self.isNegated && result || self.isNegated && !result
    }
}

public class TagUnsetPredicate: TagPredicate, CustomStringConvertible {
    public var description:String {
        return "UNSET " + tags.joinWithSeparator(", ")
    }

    public override func evaluate(object: Object) -> Bool {
        let result = self.tags.isDisjointWith(object.tags)
        return !self.isNegated && result || self.isNegated && !result
    }
}

/**
    Condition that is satisfied when a measure of tested object is greater or
    less than a value or when a measure is zero. There is no other equality
    comparison condition than zero.

*/
public enum ComparisonType:Int {
    case Less = 0
    case Greater
}

public class ComparisonPredicate: ObjectPredicate {
    public let counter: Symbol
    public let value: Int
    public let comparisonType: ComparisonType

    init(counter: Symbol, value:Int, inSlot: Symbol?,
        comparisonType: ComparisonType, isNegated:Bool=false) {
            self.counter = counter
            self.value = value
            self.comparisonType = comparisonType
            super.init(inSlot: inSlot, isNegated: isNegated)
    }

    public override func evaluate(object: Object) -> Bool {
        let result: Bool
        if let value = object.counters[self.counter] {
            switch self.comparisonType {
                case .Less: result = value < self.value
                case .Greater: result = value > self.value
            }
            return !self.isNegated && result || self.isNegated && !result
        }
        else {
            return false
        }

    }
}

public class ZeroPredicate: ObjectPredicate {
    public let counter: Symbol

    init(counter: Symbol, value:Int, inSlot: Symbol?, isNegated:Bool=false) {
        self.counter = counter
        super.init(inSlot: inSlot, isNegated: isNegated)
    }

    public override func evaluate(object: Object) -> Bool {
        if let value = object.counters[self.counter] {
            let result = value == 0
            return !self.isNegated && result || self.isNegated && !result
        }
        else {
            // TODO: Should we assume that absence of a measure is zero?
            return false
        }

    }
}

