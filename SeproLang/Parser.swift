//
//  Parser.swift
//  AgentFarms
//
//  Created by Stefan Urbanek on 10/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public enum SyntaxError: ErrorType {
    case ParserError(String)
}

// Parser
// ========================================================================

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
    "ROOT", "THIS", "OTHER",

    // Data
    "DATA"
]

public func parseModel(source: String) throws -> Model {
    let lexer = Lexer(source: source, keywords: Keywords)
    let tokens = lexer.parse()

    let result = model.parse(tokens.stream())

    switch(result) {
    case .OK(let value, _): return value
    case let .Fail(error, token): print("ERROR (fail) \(token): \(error)"); throw SyntaxError.ParserError(error)
    case let .Error(error, token): print("ERROR \(token): \(error)"); throw SyntaxError.ParserError(error)
    }
}