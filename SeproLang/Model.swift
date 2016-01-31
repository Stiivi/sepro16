//
//  Model.swift
//  Sepro
//
//  Created by Stefan Urbanek on 02/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

// Note: The code might be over-modularized and there might be too many
// classes, but that is intentional during the early development phase as it
// helps in the thinking process. Concepts might be merged later in the
// process of conceptual optimization.


public typealias Symbol = String
// TODO: Add SymbolInfo: symbol, type, firstOccurence

// MARK: Model

/// Structure of concepts. Describes concept instances forming a linked structure.
///
public struct Struct {
    public var name: Symbol
    public let graph: InstanceGraph
    /// Names of outlets – instances from the graph that are exposed
    public let outlets: [PropertyReference:Symbol]

    /// Creates a concept structure.
    ///
    /// - Parameters:
    ///     - name: Structure name
    ///     - contents: Graph contents
    ///     - outlets: Named objects to be exposed to the outside
    ///
    public init(name: Symbol, graph: InstanceGraph, outlets: [PropertyReference:Symbol]?=nil) {
        self.name = name
        self.outlets = outlets ?? Dictionary<PropertyReference,Symbol>()
        self.graph = graph
    }

}


/// Describes initial contents of a simulation.
///
public struct World {
    public var name: Symbol
    /// Contents
    public var graph: InstanceGraph
    /// Root object – referenced to as `ROOT`.
    public var root: Symbol? = nil

    public init(name: Symbol, graph: InstanceGraph, root: Symbol?=nil) {
        self.name = name
        self.graph = graph
        self.root = root
    }

    public func asString() -> String {
        var out = ""

        out += "WORLD \(name)"
        if self.root != nil {
            out += " ROOT \(root)"
        }
        out += "\n"
        out += graph.asString()

        return out
    }

}

/// Model container – holds all model entities needed for execution.
///
public struct Model {
    /// Dictionary of concepts
    public var concepts: [Concept]
    /// Dictionary of structures
    public var structures: [Struct]
    /// Dictionary of worlds
    public var worlds: [World]
    /// List of actuators
    public var actuators: [Actuator]

    /// List of measures
    public var measures: [Measure]

    /// List of measures
    public var data: [(TagList, String)]

    public init(concepts: [Concept]?=nil, actuators: [Actuator]?=nil,
        measures: [Measure]?=nil, worlds: [World]?=nil,
        structures: [Struct]?=nil, data: [(TagList, String)]?=nil) {
            self.concepts = concepts ?? [Concept]()
            self.actuators = actuators ?? [Actuator]()
            self.measures = measures ?? [Measure]()
            self.worlds = worlds ?? [World]()
            self.structures = structures ?? [Struct]()
            self.data = data ?? [(TagList, String)]()
    }

    /// Get a structure by name
    public func getStruct(name:String) -> Struct? {
        return self.structures.findFirst { $0.name == name }
    }

    /// Get a concept by name
    public func getConcept(name:String) -> Concept? {
        return self.concepts.findFirst { $0.name == name }
    }

    /// Get a world by name
    public func getWorld(name:String) -> World? {
        return self.worlds.findFirst { $0.name == name }
    }

    /// Get data that match the `tags`. If `exact` is `true` then the data
    /// tags and `tags` must be equal sets, otherwise the `tags` is only subset
    /// of the data tags.
    public func getData(tags:TagList, exact: Bool=true) -> [String] {
        if exact {
            return self.data.filter { $0.0 == tags }.map { $0.1 }
        }
        else {
            return self.data.filter { tags.isSubsetOf($0.0) }.map { $0.1 }
        }
    }

    public func asString() -> String {
        var out: String = ""

        for (concept) in self.concepts {
            out += concept.asString()
            out += "\n"
        }
        for actuator in self.actuators {
            out += actuator.asString()
            out += "\n"
        }
        for (world) in self.worlds {
            out += world.asString()
            out += "\n"
        }
        return out
    }

}

