//
//  Parser.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 12/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public enum SyntaxError: ErrorType {
    case Parser(message:String)
    case Syntax(message:String)
    case Internal(message:String)
}


public indirect enum Item: CustomStringConvertible {
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
        }
    }
}

/// Terminal items (symbols).
///
/// The values for `Symbol` and `Integer` are human readable labels
/// of those terminals – displayed to the user on error, when they are expected.
/// For example a variable name symbol is represented as
/// `.Symbol("variable name")`
public indirect enum Term: CustomStringConvertible {
    case Symbol(String)
    case Integer(String)

    case Keyword(String)
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

public typealias Grammar = [String:Item]


public class Parser {
    var lexer: Lexer! = nil
    let grammar: Grammar

    init(grammar: Grammar) {
        self.grammar = grammar
    }

    func parse(lexer:Lexer, rule: String) throws -> AST? {
        self.lexer = lexer
        return try self.parseRule(rule, isExpected: true)
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

        switch (item, token) {
        case (.Keyword(let expected), .Keyword(let keyword)) where keyword == expected:
            self.lexer.nextToken()
            return .ASTString(keyword)

        case (.Keyword(let expected), _):
            expectation = "keyword \(expected)"

        case (.Symbol, .Symbol(let symbol)):
            self.lexer.nextToken()
            return .ASTString(symbol)

        case (.Symbol(let expected), _):
            expectation = "symbol: \(expected)"

        case (.Integer, .Integer(let value)):
            self.lexer.nextToken()
            return .ASTInteger(value)

        case (.Integer(let expected), _):
            expectation = "integer: \(expected)"

        case (.Operator, .Operator(let value)):
            self.lexer.nextToken()
            return .ASTOperator(value)

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

    func parseRule(name: String, isExpected: Bool=false) throws -> AST? {
        // TODO: make sure that the ruleName exists in the grammar -> need grammar validation
        if let item = self.grammar[name] {
            if let children = try self.parseRuleItem(item, isExpected: isExpected) {
                return .ASTNode(name, children)
            }
            else {
                return nil
            }
        }
        else {
            // TODO: This should be checked before parsing, we should have
            // all the rules available
            throw SyntaxError.Internal(message: "Unknown rule '\(name)'")
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
            if case .Empty = self.lexer.currentToken {
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

            guard let firstItem = items.first else {
                break rule
            }

            let tail = items.dropFirst()

            if let head = try self.parseRuleItem(firstItem, isExpected: isExpected) {
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

        case .Repeat(let item):
            var children = [AST]()

            while(true){
                if let accepted = try self.parseRuleItem(item, isExpected: isExpected) {
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
        }

        return nil
    }
}

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

func |(left: Item, right: Item) -> Item{
    switch left {
    case .Alternate(let items):
        return .Alternate(items + [right])
    default:
        return .Alternate([left, right])
    }
}

infix operator .. { associativity left }

func ..(left: Item, right: Item) -> Item{
    switch left {
    case .Group(let items):
        return .Group(items + [right])
    default:
        return .Group([left, right])
    }
}

// Operators:
// ^"rule" §"symbol" %"integer"

prefix operator ^ { }
prefix operator ?? { }

prefix func ^(value: String) -> Item {
    return .Rule(value)
}

prefix func §(value: String) -> Item {
    return .Terminal(.Symbol(value))
}

prefix operator % { }
prefix func %(value: String) -> Item {
    return .Terminal(.Integer(value))
}


prefix func +(right: Item) -> Item{
    return .Repeat(right)
}

prefix func ??(right: Item) -> Item{
    return .Optional(right)
}

