//
//  Extensions.swift
//  AgentFarms
//
//  Created by Stefan Urbanek on 14/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Darwin

/** Primitive implementation of CountedSet used for counting anonymous
 instances
 */
public class CountedSet<T: Hashable>: Sequence {
    public typealias Index = DictionaryIndex<T, Int>
    public typealias _Element = T

    var objects = Dictionary<T, Int>()

    public init(_ items: T ...)
    {
        for item in items
        {
            self.add(item)
        }
    }

    public var count: Int {
        get { return objects.count }
    }
    public var isEmpty: Bool {
        get { return objects.isEmpty }
    }
    public var first: (T, Int)? {
        get { return objects.first }
    }

    public func removeAll() {
        self.objects.removeAll()
    }

    public func add(_ item: T)
    {
        if let count = objects[item] {
            objects[item] = count + 1
        } else {
            objects[item] = 1
        }
    }

    public func remove(_ item: T) {
        if let count = objects[item]
        {
            if (count > 1) {
                objects[item] = count - 1
            } else {
                objects.removeValue(forKey:item)
            }
        }
    }

    public var description : String {
        return objects.description
    }

    public subscript(item: T) -> Int {
        get {
            if let count = objects[item] {
                return count
            }
            else {
                return 0
            }
        }
        set(count) {
            objects[item] = count
        }
    }

    public func makeIterator() -> DictionaryIterator<T, Int> {
        return objects.makeIterator()
    }
}


/// Return a random 32-bit integer
func randomInt(upperBound:Int) -> Int {
    return Int(arc4random_uniform(UInt32(upperBound)))
}

