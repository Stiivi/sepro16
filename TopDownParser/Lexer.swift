//
//  Lexer.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 12/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public enum Token: CustomStringConvertible, Equatable {
    case Error(String)
    case Empty
    case Integer(Int)
    case Symbol(String)
    case Keyword(String)
    case Description(String)
    case Operator(String)

    public var description: String {
        switch self {
        case Error(let error):
            return "Parser error: \(error)"
        case Empty:
            return "<<EMPTY>>"
        case Integer(let value):
            return "\(value)"
        case Symbol(let symbol):
            return "\"\(symbol)\""
        case Keyword(let keyword):
            return String(keyword)
        case Description( _):
            // TODO: make this happen
            return "<<TODO:description>>"
        case Operator(let op):
            return String(op)
        }
    }
}

public func ==(left: Token, right: Token) -> Bool {
    switch (left, right) {
    case (.Error(let lstr), .Error(let rstr)) where lstr == rstr:
        return true
    case (.Empty, .Empty):
        return true
    case (.Integer(let lint), .Integer(let rint)) where lint == rint:
        return true
    case (.Symbol(let lstr), .Symbol(let rstr)) where lstr == rstr:
        return true
    case (.Keyword(let lstr), .Keyword(let rstr)) where lstr == rstr:
        return true
    case (.Operator(let lstr), .Operator(let rstr)) where lstr == rstr:
        return true
    case (.Description(let lstr), .Description(let rstr)) where lstr == rstr:
        return true
    default:
        return false
    }
}

extension Token: StringLiteralConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias UnicodeScalarLiteralType = String

    public init(stringLiteral value: StringLiteralType){
        self = .Keyword(value)
    }

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType){
        self = .Keyword(value)
    }

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType){
        self = .Keyword(value)
    }
}

extension Token: NilLiteralConvertible {
    public init(nilLiteral: ()) {
        self = .Empty
    }
}

extension Token: IntegerLiteralConvertible {
    public typealias IntegerLiteralType = Int

    public init(integerLiteral value: IntegerLiteralType) {
        self = .Integer(value)
    }
}


// TODO: For testing purposes
prefix func §(right: String) -> Token {
    return .Symbol(right)
}

public protocol Lexer {
    func nextToken() -> Token
    var currentToken: Token { get }
}

public class DummyLexer: Lexer {
    typealias _TokenSequence = [Token]
    var generator: _TokenSequence.Generator

    public var currentToken: Token

    init(tokens: [Token]){
        self.generator = tokens.generate()
        self.currentToken = .Empty
        self.nextToken()
    }

    public func nextToken() -> Token {
        if let token = self.generator.next() {
            self.currentToken = token
        }
        else {
            self.currentToken = .Empty
        }
        return self.currentToken
    }

}
