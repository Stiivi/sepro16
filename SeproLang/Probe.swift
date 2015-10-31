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

public enum ProbeFunction: String {
    case Count = "COUNT"
    case Sum = "SUM"
    case Averag = "AVG"
    case Min = "MIN"
    case Max = "MAX"
}

public enum ProbeType: String {
    case Object = "OBJECT"
    case Aggregate = "AGGREGATE"
}

public typealias ProbeSet = [Probe]

public protocol Probe {
    var name: Symbol { get }
    var type: ProbeType { get }
}

public struct ObjectProbe: Probe {
    public let name: Symbol
    public let type: ProbeType
    public let reference: Symbol
    public let slot: Symbol?
}

public struct AggregateProbe: Probe {
    public let name:Symbol
    public let type: ProbeType
    public let predicates:[Predicate]
    public let function:ProbeFunction
}