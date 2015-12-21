//
//  ModelCompiler.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 14/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import TopDownParser


public let Keywords = [
    // Model Objects
    "CONCEPT", "TAG", "COUNTER", "SLOT",
    "STRUCT","OBJECT", "BIND", "OUTLET", "AS",
    "MEASURE",
    "WORLD",

    // predicates
    "WHERE", "DO", "RANDOM", "ALL",
    "BOUND",
    "NOT", "AND",
    "IN", "ON",

    // Actions
    "SET", "UNSET", "INC", "DEC", "ZERO",
    // Control actions
    "NOTHING", "TRAP", "NOTIFY",

    // Probes
    "COUNT", "AVG", "MIN", "MAX",

    "BIND", "TO",
    "UNBIND",
    "ROOT", "THIS", "OTHER"
]

func makeGrammar() {
    var g = Grammar()

    g["model"]        = +^"model_object"
    g["model_object"] = ^"concept" | ^"actuator" | ^"measure" | ^"world"
    g["concept"]      = "CONCEPT" .. §"name" .. +^"concept_member"
    g["concept_member"] = ^"tag_member" | ^"slot_member"
    g["tag_member"]   = "TAG" .. ^"symbol_list"
    g["slot_member"]  = "SLOT" .. ^"symbol_list"

    g["actuator"]     = "WHERE" .. ^"selector" ..
                          ??("ON" .. ^"selector") ..
                          "DO" .. ^"modifiers" .. ?^"control"
    g["selector"]     = "ALL" | (??"ROOT" .. ^"predicates")
    g["predicates"]   = ^"predicate" .. +("AND" .. ^"predicate")
    g["predicate"]    = ??"NOT" .. (
                            ^"symbol_list"
                                | "SET" .. ^"symbol_list"
                            | "UNSET" .. ^"symbol_list"
                            | "ZERO" .. §"counter_name"
                            | "BOUND" .. §"slot_name"
                        )
    g["modifiers"]    = ^"modifier" .. +^"modifier"
    g["modifier"]     = ??("IN" .. ^"current") .. (
                            "NOTHING"
                            | "SET" .. ^"tag_list"
                            | "UNSET" .. ^"tag_list"
                            | "BIND" .. §"source" .. "TO" .. ^"current" .. §"target"
                            | "UNBIND" .. §"slot"
                        )
    g["current"]      = ("THIS" | "OTHER" | "ROOT") .. ??("." .. §"slot")
    g["control"]      = ??("NOTIFY" .. ^"symbol_list")
                        .. ??("TRAP" .. ^"symbol_list")
                        .. ??"HALT"
    g["measure"]      = "MEASURE"
    g["world"]        = "WORLD"

    // Small
    g["symbol_list"] = §"symbol" .. +("," .. §"symbol")
}


class ModelCompiler {

}