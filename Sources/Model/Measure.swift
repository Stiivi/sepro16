//
//  Probe.swift
//  Sepro
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

public enum AggregateFunction {
    case count(TagList)
    case sum(Symbol)
    case min(Symbol)
    case max(Symbol)
}

public enum MeasureType {
    case counterByName(Symbol, Symbol)
    case aggregate(AggregateFunction, [Predicate])
}

public struct Measure {
    public let name: Symbol
    public let type: MeasureType

    public var predicates: [Predicate] {
        switch type {
        case let .aggregate(_, predicates):
            return predicates
        default:
            return []
        }
    }

    init(name: Symbol, type: MeasureType) {
        self.name = name
        self.type = type
    }

}

