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

public struct ShuffledCollection<Base:CollectionType where Base.Index == Int>: CollectionType {
    public typealias Generator = AnyGenerator<Base.Generator.Element>
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

    public var count: ShuffledCollection.Index.Distance {
        return self.base.count
    }

    public var startIndex : Int { return base.startIndex }
    public var endIndex : Int { return base.endIndex }

    public func generate() -> Generator {
        var generator = self.shuffled.generate()

        return AnyGenerator {
            if let index = generator.next() {
                return self.base[index]
            }
            else {
                return nil
            }
        }
    }

    public subscript(index: Int) -> Base.Generator.Element {
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
