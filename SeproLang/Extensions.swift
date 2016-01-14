//
//  Extensions.swift
//  AgentFarms
//
//  Created by Stefan Urbanek on 14/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

/** Primitive implementation of CountedSet used for counting anonymous
 instances
 */
public class CountedSet<T: Hashable>: SequenceType {
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

    public func add(item: T)
    {
        if let count = objects[item] {
            objects[item] = count + 1
        } else {
            objects[item] = 1
        }
    }

    public func remove(item: T) {
        if let count = objects[item]
        {
            if (count > 1) {
                objects[item] = count - 1
            } else {
                objects.removeValueForKey(item)
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

    public func generate() -> CountedSetGenerator<T> {
        return CountedSetGenerator(self.objects)
    }
}


public struct CountedSetGenerator<T:Hashable> : GeneratorType {
    var dictGenerator : DictionaryGenerator<T, Int>

    init(_ dictGenerator : Dictionary<T, Int>) {
        self.dictGenerator = dictGenerator.generate()
    }

    public typealias Element = (T, Int)

    mutating public func next() -> Element? {
        return dictGenerator.next()
    }
}

/// Return a random 32-bit integer
func randomInt(upperBound:Int) -> Int {
    return Int(arc4random_uniform(UInt32(upperBound)))
}

// MARK: CLib basics (no Cocoa)

// Few very basic methods, since we don't want to use Cocoa here

public func isspace(char:Character?) -> Bool{
    if char == nil {
        return false
    }
    else {
        return " \t\n\r".characters.contains(char!)
    }
}
public func isnumber(char:Character?) -> Bool{
    let numbers = Character("0")...Character("9")
    if char == nil {
        return false
    }
    else {
        return numbers.contains(char!)
    }
}
public func isalpha(char:Character?) -> Bool{
    let lower = Character("A")...Character("Z")
    let upper = Character("a")...Character("z")
    if char == nil {
        return false
    }
    else {
        return lower.contains(char!) || upper.contains(char!)
    }
}
public func isalnum(char:Character?) -> Bool{
    return isnumber(char) || isalpha(char)
}

public func isidentifier(char:Character?) -> Bool{
    return isnumber(char) || isalpha(char) || char == "_"
}

