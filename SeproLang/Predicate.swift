//
//  Predicate.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 29/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public class Predicate { }

/// Triggers every time the engine encounters it
public class AllPredicate: Predicate, CustomStringConvertible {
    public var description:String {
        return "ALL"
    }
}

/// Triggers randomly – discrete uniform distribution.
public class RandomPredicate: Predicate, CustomStringConvertible {
    public var description:String {
        return "RANDOM"
    }
}

/// Abstract base class for conditions by object state
public class ObjectPredicate: Predicate {
    public let isNegated:Bool
    public let slot:Symbol?

    init(slot: Symbol?=nil, isNegated:Bool=false) {
        self.slot = slot
        self.isNegated = isNegated
    }
}

/**
    Condition that is satisfied when examined object has all of the tags from
    the `tagList` set.
*/
public class TagPredicate: ObjectPredicate {
    public let tags:TagList

    init(tags: TagList, slot: Symbol?=nil, isNegated:Bool=false) {
        self.tags = tags
        super.init(slot: slot, isNegated: isNegated)
    }

}

public class TagSetPredicate: TagPredicate, CustomStringConvertible {
    public var description:String {
        return "SET " + tags.joinWithSeparator(", ")
    }
}

public class TagUnsetPredicate: TagPredicate, CustomStringConvertible {
    public var description:String {
        return "UNSET " + tags.joinWithSeparator(", ")
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
    public let measure: Symbol
    public let value: Int
    public let comparisonType: ComparisonType

    init(measure: Symbol, value:Int, slot: Symbol?,
        comparisonType: ComparisonType, isNegated:Bool=false) {
            self.measure = measure
            self.value = value
            self.comparisonType = comparisonType
            super.init(slot: slot, isNegated: isNegated)
    }
}

public class ZeroPredicate: ObjectPredicate {
    public let measure: Symbol

    init(measure: Symbol, value:Int, slot: Symbol?, isNegated:Bool=false) {
        self.measure = measure
        super.init(slot: slot, isNegated: isNegated)
    }
}

