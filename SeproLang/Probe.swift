//
//  Probe.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 30/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

/*

PROBESET main
PROBE counter IN ROOT
PROBE open_jars COUNT WHERE jar AND open
PROBE closed_jars COUNT WHERE jar AND closed
PROBE all_jars COUNT WHERE jar
PROBE free_lids COUNT WHERE lid AND free
PROBE all_lids COUNT WHERE lid OR open

PROBE unlinked SUM counter WHERE

*/

public enum AggregateFunction: String {
    case Count = "COUNT"
    case Sum = "SUM"
    case Min = "MIN"
    case Max = "MAX"
}

public enum MeasureType: String {
    case Object = "OBJECT"
    case Aggregate = "AGGREGATE"
}

public protocol Measure {
    var name: Symbol { get }
    var type: MeasureType { get }
}


public struct CounterMeasure: Measure {
    public let name: Symbol
    public let type: MeasureType
    public let counter: Symbol
}


public struct AggregateMeasure: Measure {
    public let name:Symbol
    public let type: MeasureType
    public let counter: Symbol!
    public let function: AggregateFunction
    public let predicates: [Predicate]
}

// MARK: Probes

public protocol Probe {
    var value: Int { get }
    func probe(object:Object)
}


// TODO: not nice aggregate measures are supported for now
public func createAggregateProbe(measure: AggregateMeasure) -> Probe {
    let probe: Probe
    switch measure.function {
    case .Count: probe = CountProbe(measure:measure)
    case .Sum: probe = SumProbe(measure:measure)
    case .Min: probe = MinProbe(measure:measure)
    case .Max: probe = MaxProbe(measure:measure)
    }
    return probe
}

public class CountProbe: Probe {
    public let measure: AggregateMeasure
    var count: Int = 0

    public init(measure: AggregateMeasure) {
        self.measure = measure
    }

    public func probe(object:Object) {
        self.count += 1
    }

    public var value: Int {
        return count
    }
}

public class SumProbe: Probe {
    public let measure: AggregateMeasure
    var sum: Int = 0

    public init(measure: AggregateMeasure) {
        self.measure = measure
    }

    public func probe(object:Object) {
        if let value = object.links[self.measure.counter] {
            self.sum += value
        }
    }

    public var value: Int {
        return sum
    }
}

public class MaxProbe: Probe {
    public let measure: AggregateMeasure
    var current: Int = 0

    public init(measure: AggregateMeasure) {
        self.measure = measure
    }

    public func probe(object:Object) {
        if let value = object.links[self.measure.counter] {
            if value > current {
                current = value
            }
        }
    }

    public var value: Int { return current }
}

public class MinProbe: Probe {
    public let measure: AggregateMeasure
    var current: Int = 0

    public init(measure: AggregateMeasure) {
        self.measure = measure
    }

    public func probe(object:Object) {
        if let value = object.links[self.measure.counter] {
            if value < current {
                current = value
            }
        }
    }

    public var value: Int { return current }
}

