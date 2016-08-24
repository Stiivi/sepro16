//
//  Model.swift
//  Sepro
//
//  Created by Stefan Urbanek on 02/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

/// Model container – holds all model entities needed for execution.
///

import Utility

public struct Model {
    // Core elements
    //
    /// List of available concepts
    public var concepts: [Concept]
    /// List of actuators
    public var actuators: [Actuator]

	public var structures: [Struct]
	public var worlds: [World]
	public var data: [(TagList, String)]

    // Observation
    // 
    /// List of measures
    public var measures: [Measure]

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
        return self.structures.first { $0.name == name }
    }

    /// Get a concept by name
    public func getConcept(name:String) -> Concept? {
        return self.concepts.first { $0.name == name }
    }

    /// Get a world by name
    public func getWorld(name:String) -> World? {
        return self.worlds.first { $0.name == name }
    }

    /// Get data that match the `tags`. If `exact` is `true` then the data
    /// tags and `tags` must be equal sets, otherwise the `tags` is only subset
    /// of the data tags.
    public func getData(tags:TagList, exact: Bool=true) -> [String] {
        if exact {
            return self.data.filter { $0.0 == tags }.map { $0.1 }
        }
        else {
            return self.data.filter { tags.isSubset(of:$0.0) }.map { $0.1 }
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

