//
//  ShuffledCollection.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 25/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Foundation

// FIXME: This is OSX Only (used for rng)
import Darwin

/**
Wraps an array and presents it in a shuffled way.

- Complexity: requires O(n) memory and time to store and generate shuffled index
*/

public struct ShuffledCollection <Base:Collection>: Collection
	where Base.IndexDistance == Int, Base.Index == Int
{
    public typealias Iterator = AnyIterator<Base.Iterator.Element>
    public typealias Index = Int

    let base: Base
    var shuffled: [Int]

    init(_ base:Base) {
        self.base = base
        self.shuffled = [Int]()

        var j: Int

        if !base.isEmpty {
            for i in 0...(base.count-1) {
                j = Int(arc4random_uniform(UInt32(i+1)))
                if j == i {
                    self.shuffled.append(i)
                }
                else {
                    self.shuffled.append(self.shuffled[j])
                    self.shuffled[j] = i
                }
            }
        }

    }

    public var count: ShuffledCollection.IndexDistance {
        return self.base.count
    }

	public func index(after i: Int) -> Int {
		return self.base.index(after: i)
	}
    public var startIndex : Int { return base.startIndex }
    public var endIndex : Int { return base.endIndex }

    public func makeIterator() -> Iterator {
        var iterator = self.shuffled.makeIterator()

        return AnyIterator {
            if let index = iterator.next() {
                return self.base[index]
            }
            else {
                return nil
            }
        }
    }

    public subscript(index: Int) -> Base.Iterator.Element {
        get {
            return self.base[shuffled[index]]
        }
    }

    public func shuffle() -> ShuffledCollection<Base> {
        return ShuffledCollection(self.base)
    }
}

extension Array {
    public func shuffle() -> ShuffledCollection<Array> {
        return ShuffledCollection(self)
    }
}
