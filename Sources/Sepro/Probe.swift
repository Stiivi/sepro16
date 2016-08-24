//
//  Measure.swift
//  Sepro
//
//  Created by Stefan Urbanek on 30/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Model

public protocol Probe {
    var value: Int { get }
    func probe(object:Object)
}

// TODO: not nice aggregate measures are supported for now
public func createProbe(measure: Measure) -> Probe {
    let probe: Probe

    switch measure.type {
    case .CounterByName(_, _):
        return NullProbe()
    case let .Aggregate(function, _):
        switch function {
        case .Count: probe = CountProbe()
        case .Sum(let counter): probe = SumProbe(counter)
        case .Min(let counter): probe = MinProbe(counter)
        case .Max(let counter): probe = MaxProbe(counter)
        }
    }
    return probe
}

/// Dummy proble during development, does nothing, returns 0
public class NullProbe: Probe {
    public var value: Int = 0

    public func probe(object: Object) {
        // Do nothing
    }
}

public class CountProbe: Probe {
    public var value: Int = 0

    public func probe(object:Object) {
        self.value += 1
    }

}

public class SumProbe: Probe {
    public let counter: Symbol
    var sum: Int = 0

    public init(_ counter: Symbol) {
        self.counter = counter
    }

    public func probe(object:Object) {
        if let value = object.counters[self.counter] {
            self.sum += value
        }
    }

    public var value: Int {
        return sum
    }
}

public class MaxProbe: Probe {
    public let counter: Symbol
    var current: Int = 0

    public init(_ counter: Symbol) {
        self.counter = counter
    }

    public func probe(object:Object) {
        if let value = object.counters[self.counter] {
            if value > current {
                current = value
            }
        }
    }

    public var value: Int { return current }
}

public class MinProbe: Probe {
    public let counter: Symbol
    var current: Int = 0

    public init(_ counter: Symbol) {
        self.counter = counter
    }

    public func probe(object:Object) {
        if let value = object.bindings[self.counter] {
            if value < current {
                current = value
            }
        }
    }

    public var value: Int { return current }
}

