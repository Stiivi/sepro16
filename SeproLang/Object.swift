//
//  Object.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 30/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//


/** References an object in the store. */
public typealias ObjectRef = Int
/** List of object references */
public typealias ObjectList = [Int]
/** Named object references */
public typealias ObjectMap = [Symbol:ObjectRef]

/**
    Simulation object.

    - Note: This structure serves only as an interface between the
      engine and it's external environment. Since the structure might
      not be memory or time efficient, it recommended to consider
      different internal representation of an object or collection
      of objects in custom engine implementation.

*/

public class Object: CustomStringConvertible {
    // TODO: Change this to Struct
    /// Object identifier
    public var id: ObjectRef = 0
    /// Measure values
    public var counters = CounterDict()
    /// Tags that are set
    public var tags = TagList()
    /// References to other objects
    public var links = ObjectMap()

    public init(_ id: ObjectRef) {
        self.id = id
    }

    public var description: String {
        get {
            let links = self.links.map(){ (key, value) in "\(key)->\(value)" }
                            . joinWithSeparator(", ")
            let tagsStr = self.tags.map { String($0)} . joinWithSeparator(", ")
            return "\(id)[\(tagsStr);\(links)]"
        }
    }

    public var debugString: String {
        return self.description
    }
}
