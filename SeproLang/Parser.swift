//
//  Parser.swift
//  TopDown
//
//  Created by Stefan Urbanek on 12/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

//===----------------------------------------------------------------------===//
//
// Top-down Meta Parser
//
// This file contains top-down meta parser, data types and operators for
// constructing parsing rules.
//
// The following convenience operator are provided:
//
// - conversion from string to rule item
// - § prefix for symbols (identifiers)
// - ^ prefix for rules
// - + prefix for repeats
// - ?? prefix for optional item
// - .. operator for joining rule items into a group
// - | operator for joining rule alternatives
//
// Example
// let rule: Item = "OBJECT" .. §"name" .. ??(^"object_members")
// let size: Item = "SMALL" | "MEDIUM" | "LARGE" | .Error("Expected size")
//
// Note: The non-standard § operator is accessible on most of the keyboards. On
// the US keyboard on OSX it can be typed by Alt + 6.
//
//===----------------------------------------------------------------------===//


/// Errors raised by the parser
public enum SyntaxError: ErrorType {
    case Syntax(message:String)
    // This should not happen
    case Internal(message:String)
}

public indirect enum Item: CustomStringConvertible, CustomDebugStringConvertible {
    /// Matches end of input
    case Empty
    /// Matches a terminal
    case Terminal(Term)
    /// If does not match input results in nil
    case Optional(Item)
    /// Matches another named rule
    case Rule(String)
    /// Matches group of items
    case Group([Item])
    /// Matches one of the items
    case Alternate([Item])
    /// Matches zero or more repetitions of an item
    case Repeat(Item)
    /// When reached an error is raised.
    case Error(String)

    /// Process and transform AST of the item provided
    case Transform(Item, ([AST]) -> AST)

    public init(item: Term) {
        self = .Terminal(item)
    }

    public init(rule: String) {
        self = .Rule(rule)
    }

    public var description: String {
        switch self {
        case Empty:
            return "empty"
        case Terminal(let val):
            return String(val)
        case Rule(let val):
            return "^\(val)"
        case Group(let items):
            let strings = items.map { item in String(item) }
            return "(" + strings.joinWithSeparator(" .. ") + ")"
        case Alternate(let items):
            let strings = items.map { item in String(item) }
            return "(" + strings.joinWithSeparator(" | ") + ")"
        case Optional(let item):
            return "??" + String(item)
        case Repeat(let item):
            return "+" + String(item)
        case Error(let message):
            return "Error(\(message))"
        case Transform(let item, _):
            return "Transform(\(item))"
        }
    }

    public var debugDescription: String {
        return self.description
    }

    /// Traverses the item tree and transforms every node it visits.
    /// - Returns: Collection of transformed items.
    public func visitMap<T>(transform: (Item) -> T) -> [T] {
        var visited = [T]()
        visited.append(transform(self))

        switch self {
        case Group(let items):
            let values = items.reduce([T]()) { a, c in
                a + c.visitMap(transform)
            }
            visited += values
        case Alternate(let items):
            let values = items.reduce([T]()) { a, c in
                a + c.visitMap(transform)
            }
            visited += values
        case Optional(let item):
            visited.append(transform(item))
        case Repeat(let item):
            visited.append(transform(item))
        default:
            // We already did our job
            break
        }
        return visited
    }

    /// - Returns: set of all rules that the item and it's potential children
    /// reference
    public func rules() -> Set<String> {
        let rules:[String?] = self.visitMap {
            item in
            if case let .Rule(rule) = item {
                return rule
            }
            else {
                return nil
            }
        }
        return Set(rules.flatMap { $0 })
    }
}

/// Terminal items (symbols).
///
/// The values for `Symbol` and `Integer` are human readable labels
/// of those terminals – displayed to the user on error, when they are expected.
/// For example a variable name symbol is represented as
/// `.Symbol("variable name")`
public indirect enum Term: CustomStringConvertible {
    /// Matches a symbol (identifier).
    case Symbol(String)
    /// Matches an integer
    case Integer(String)
    /// Matches a keyword – special symbol.
    case Keyword(String)
    /// Matches an operator – sequence of operator characters.
    case Operator(String)

    public var description: String {
        switch self {
        case Keyword(let s): return s
        case Symbol(let s): return "§\(s)"
        case Operator(let s): return String(s)
        case Integer(let val): return String(val)
        }
    }

}

/// Grammar rules container.
/// - Note: Guarantees that all referenced rules exist. Otherwise raises an error
/// during initialization.
public struct Grammar {
    public let rules: [String: Item]

    init(rules: [String:Item]) throws {
        self.rules = rules

        // Validate the grammar
        let names = rules.reduce(Set<String>()) {
            acc, pair in
            let (_, item) = pair
            return acc.union(item.rules())
        }
        let missing = names.subtract(rules.keys).sort()
        if !missing.isEmpty {
            let message = "Missing grammar rules: \(missing)"
            throw SeproError.InternalError(message)
        }
    }
    subscript(name:String) -> Item {
        get {
            return self.rules[name]!
        }
    }
}

/// Top-down meta-parser. Matches tokens from provided lexer to associated
/// grammar rules and produces abstract syntax tree (AST) structure.
///
public class Parser {
    var lexer: Lexer! = nil
    let grammar: Grammar

    /// - Note: returns nil when grammar is missing rules.
    public init(grammar: Grammar) {
        self.grammar = grammar
    }

    /// Parse tokens from `lexer` with starting rule `start`
    /// - Parameters:
    ///     - lexer: a `Lexer` object
    ///     - start: name of a rule to be used for parsing
    /// - Returns: parsed AST
    /// - Throws: SyntaxError
    public func parse(lexer:Lexer, start: String) throws -> AST? {
        self.lexer = lexer
        // Advance to the the first token
        self.lexer.nextToken()
        return try self.parseRule(start, isExpected: true)
    }


    /// Parse a rule with name `name`.
    /// - Parameters:
    ///     - name: rule name
    ///     - isExpected: if `true` the rule must be parsed
    /// - Returns: AST
    /// - Precondition: Grammar must contain the rule `name`
    func parseRule(name: String, isExpected: Bool=false) throws -> AST? {
        let item = self.grammar[name]
        if let children = try self.parseRuleItem(item, isExpected: isExpected) {
            return .ASTNode(name, children)
        }
        else {
            return nil
        }
    }

    /// Parse a grammar rule and return AST if the source matches the rule.
    /// - Parameters:
    ///     - rule: grammar rule item
    ///     - isExpected: whether the rule is required or not
    /// - Returns: AST representation of the source
    func parseRuleItem(rule: Item, isExpected: Bool=false) throws -> [AST]? {
        rule: switch rule {
        case .Empty:
            if case .Empty = self.lexer.currentToken.kind {
                return []
            }
            else if isExpected {
                throw SyntaxError.Syntax(message: "Expected end, got: \(self.lexer.currentToken)")
            }

        case .Terminal(let term):
            if let node = try self.parseTerminal(term, isExpected: isExpected) {
                return [node]
            }

        case .Error(let message):
            throw SyntaxError.Syntax(message: message)

        case .Rule(let ruleName):
            if let node = try self.parseRule(ruleName, isExpected: isExpected) {
                return [node]
            }

        case .Group(let items):
            var children = [AST]()

            // There has to be at least one item in the group
            guard let firstItem = items.first else {
                break rule
            }

            let tail = items.dropFirst()

            // If we don't match the head, there is no point of matching further
            guard let head = try self.parseRuleItem(firstItem, isExpected: isExpected) else {
                return nil
            }

            children += head
            // The rest must be expected
            for item in tail {
                if let nodes = try self.parseRuleItem(item, isExpected: true) {
                    children += nodes
                }
                else {
                    break rule
                }
            }
            return children

        case .Alternate(let items):
            guard let last = items.last else {
                // TODO: is this ok?
                return nil
            }

            let head = items.dropLast()

            for item in head {
                if let accepted = try self.parseRuleItem(item, isExpected: false) {
                    return accepted
                }
            }

            // The last must be expected
            if let expected = try self.parseRuleItem(last, isExpected: isExpected) {
                return expected
            }

            // Match zero or more times
        case .Repeat(let item):
            var children = [AST]()

            while(true){
                if let accepted = try self.parseRuleItem(item, isExpected: false) {
                    children += accepted
                }
                else {
                    break
                }
            }
            return children

        case .Optional(let item):
            if let accepted = try self.parseRuleItem(item, isExpected: false) {
                return accepted
            }
            else {
                return [.ASTNil]
            }
        case .Transform(let item, let transform):
            if let inner = try self.parseRuleItem(item, isExpected: isExpected) {
                return [transform(inner)]
            }
        }

        return nil
    }


    /// Parse a terminal item.
    /// - Parameters:
    ///     - item: Terminal item
    ///     - isExpected: `true` if the terminal item is expected
    /// - Returns: AST of the item if matches current token, otherwise nil
    /// - Throws: `SyntaxError` when item is expected and does not match current
    ///   token
    func parseTerminal(item: Term, isExpected: Bool) throws -> AST? {
        var expectation: String
        let token = self.lexer.currentToken

        switch (item, token.kind) {
        case (.Keyword(let expected), .Keyword) where token.text == expected:
            self.lexer.nextToken()
            return .ASTString(token.text)

        case (.Keyword(let expected), _):
            expectation = "keyword \(expected)"

        case (.Symbol, .Identifier):
            self.lexer.nextToken()
            return .ASTString(token.text)

        case (.Symbol(let expected), _):
            expectation = "symbol: \(expected)"

        case (.Integer, .IntLiteral):
            self.lexer.nextToken()
            // TODO: handle conversion error
            return .ASTInteger(Int(token.text)!)

        case (.Integer(let expected), _):
            expectation = "integer: \(expected)"

        case (.Operator, .Operator):
            self.lexer.nextToken()
            return .ASTOperator(token.text)

        case (.Operator(let expected), _):
            expectation = "operator \(expected)"
        }

        if isExpected {
            let message = "Expected \(expectation), got: \(token)"
            throw SyntaxError.Syntax(message: message)
        }
        else {
            return nil
        }
    }

}


//===----------------------------------------------------------------------===//
//
// Swift syntax conveniences for grammar construction
//
//===----------------------------------------------------------------------===//

extension Item: StringLiteralConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias UnicodeScalarLiteralType = String

    public init(stringLiteral value: StringLiteralType){
        self = .Terminal(.Keyword(value))
    }

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType){
        self = .Terminal(.Keyword(value))
    }

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType){
        self = .Terminal(.Keyword(value))
    }
}

extension Item: NilLiteralConvertible {
    public init(nilLiteral: ()) {
        self = .Empty
    }
}

public func |(left: Item, right: Item) -> Item{
    switch left {
    case .Alternate(let items):
        return .Alternate(items + [right])
    default:
        return .Alternate([left, right])
    }
}

public func ..(left: Item, right: Item) -> Item{
    switch left {
    case .Group(let items):
        return .Group(items + [right])
    default:
        return .Group([left, right])
    }
}

// Operators:
// ^"rule" §"symbol" %"integer"

public prefix func ^(value: String) -> Item {
    return .Rule(value)
}

public prefix func §(value: String) -> Item {
    return .Terminal(.Symbol(value))
}

public prefix func %(value: String) -> Item {
    return .Terminal(.Integer(value))
}


public prefix func +(right: Item) -> Item{
    return .Repeat(right)
}

public prefix func ??(right: Item) -> Item{
    return .Optional(right)
}

public prefix func ?^(right: String) -> Item{
    return .Optional(.Rule(right))
}

public prefix func +^(right: String) -> Item{
    return .Repeat(.Rule(right))
}

public func =>(left: Item, right: ([AST])->AST) -> Item {
    return .Transform(left, right)
}

// US keyboard: Alt + 6
prefix operator § { }
infix operator .. { associativity left }
infix operator => { associativity left }

prefix operator ^ { }
prefix operator ?^ { }

prefix operator +^ { }
prefix operator ?? { }

prefix operator % { }