//
//  Lexer.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 12/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

//===----------------------------------------------------------------------===//
//
// Lexer interface and simple lexer
//
//===----------------------------------------------------------------------===//

import Foundation

/// Parser Token

public enum TokenKind: Equatable {
    case Empty

    case Error(String)

    /// Identifier: first character + rest of identifier characters
    case Identifier

    /// Reserved word - same as identifier
    case Keyword

    /// Integer
    case IntLiteral

    /// Multi-line string containing a piece of documentation
    case StringLiteral

    /// From a list of operators
    case Operator

    public var description: String {
        switch self {
        case Error: return "unknown"
        case Empty: return "empty"
        case Identifier: return "identifier"
        case Keyword: return "keyword"
        case IntLiteral: return "int"
        case StringLiteral: return "string"
        case Operator: return "operator"
        }
    }
}

public func ==(left:TokenKind, right:TokenKind) -> Bool {
    switch(left, right){
    case (.Empty, .Empty): return true
    case (.Error(let l), .Error(let r)) where l == r: return true
    case (.Keyword, .Keyword): return true
    case (.Identifier, .Identifier): return true
    case (.IntLiteral, .IntLiteral): return true
    case (.StringLiteral, .StringLiteral): return true
    case (.Operator, .Operator): return true
    default:
        return false
    }
}

public struct Token: CustomStringConvertible, CustomDebugStringConvertible, Equatable  {
    public let kind: TokenKind
    public let text: String

    public init(_ kind: TokenKind, _ text: String="") {
        self.kind = kind
        self.text = text
    }

    public var description: String {
        switch self.kind {
        case .Empty: return "(empty)"
        case .StringLiteral: return "\"\(self.text)\""
        default:
            return self.text
        }
    }

    public var debugDescription: String {
        return "\(self.kind)(\(self.description))"
    }
}

public func ==(token: Token, kind: TokenKind) -> Bool {
    return token.kind == kind
}

public func ==(left: Token, right: Token) -> Bool {
    return left.kind == right.kind && left.text == right.text
}

public func ==(left: Token, right: String) -> Bool {
    return left.text == right
}

extension Token: StringLiteralConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias UnicodeScalarLiteralType = String

    public init(stringLiteral value: StringLiteralType){
        self.kind = .Keyword
        self.text = value
    }

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType){
        self.kind = .Keyword
        self.text = value
    }

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType){
        self.kind = .Keyword
        self.text = value
    }
}

extension Token: NilLiteralConvertible {
    public init(nilLiteral: ()) {
        self.kind = .Empty
        self.text = ""
    }
}

extension Token: IntegerLiteralConvertible {
    public typealias IntegerLiteralType = Int

    public init(integerLiteral value: IntegerLiteralType) {
        self.kind = .IntLiteral
        self.text = String(value)
    }
}


// Character sets
var IdentifierStart = LetterCharacterSet | "_"
var IdentifierCharacters = AlphanumericCharacterSet | "_"
var OperatorCharacters =  CharacterSet(string: ".,*=")

// Single quote: Symbol, Triple quote: Docstring
var CommentStart: Character = "#"
var Numbers = DecimalDigitCharacterSet


public struct TextPos {
    var line: Int = 0
    var column: Int = 0

    mutating func advance(newLine:Bool=false) {
        if newLine {
            self.column = 1
            self.line += 1
        }
        else {
            self.column += 1
        }
    }
}

/**
 Simple lexer that produces symbols, keywords, integers, operators and
 docstrings. Symbols can be quoted with a back-quote character.
 */

public class Lexer {
    let keywords: [String]

    let source: String
    let characters: String.CharacterView
    var index: String.CharacterView.Index
    var currentChar: Character? = nil

    var pos: TextPos
    var error: String? = nil
    public var currentToken: Token

    /**
     Initialize the lexer with model source.

     - Parameters:
     - source: source string
     - keywords: list of unquoted symbols to be treated as keywords
     - operators: list of operators composed of operator characters
     */
    public init(source:String, keywords: [String]?=nil) {
        self.source = source
        self.characters = source.characters
        self.index = self.characters.startIndex
        if source.isEmpty {
            self.currentChar = nil
        }
        else {
            self.currentChar = self.characters[self.index]
        }

        self.pos = TextPos()
        self.keywords = keywords ?? []

        self.currentToken = nil
    }

    public func parse() -> [Token]{
        var tokens = [Token]()

        loop: while(true) {
            let token = self.nextToken()

            tokens.append(token)

            // FIXME: weird construction, but compiler does not allow more
            // conditions on the `if` line with `case`
            if case .Empty = token.kind {
                break loop
            }
            else if self.error != nil {
                break loop
            }
        }

        return tokens
    }

    /**
     Advance to the next character and set current character.
     */
    func advance() -> Character! {
        if self.index < self.characters.endIndex {
            self.index = self.index.successor()

            if self.index >= self.characters.endIndex {
                self.currentChar = nil
            }
            else {
                self.currentChar = self.characters[self.index]

                self.pos.advance(NewLineCharacterSet ~= self.currentChar!)
            }
        }
        else {
            self.currentChar = nil
        }

        return self.currentChar
    }

    /** Accept characters that are equal to the `char` character */
    private func accept(c: Character) -> Bool {
        if self.currentChar == c {
            self.advance()
            return true
        }
        else {
            return false
        }
    }

    /// Accept characters from a character set `set`
    private func accept(set: CharacterSet) -> Bool {
        if self.currentChar != nil && set ~= self.currentChar! {
            self.advance()
            return true
        }
        else {
            return false
        }
    }

    private func scanWhile(set: CharacterSet) {
        while(self.currentChar != nil) {
            if !(set ~= self.currentChar!) {
                break
            }
            self.advance()
        }
    }

    private func scanUntil(set: CharacterSet) -> Bool {
        while(self.currentChar != nil) {
            if set ~= self.currentChar! {
                return true
            }
            self.advance()
        }
        return false
    }

    private func scanUntil(char: Character, allowNewline: Bool=true) -> Bool {
        while(self.currentChar != nil) {
            if self.currentChar! == char {
                return true
            }
            else if NewLineCharacterSet ~= self.currentChar! && !allowNewline {
                return false
            }
            self.advance()
        }
        return false
    }

    /// Advance to the next non-whitespace character
    public func skipWhitespace() {
        while(true){
            if self.accept(CommentStart) {
                self.scanUntil(NewLineCharacterSet)
            }
            else if !self.accept(WhitespaceCharacterSet) {
                break
            }
        }
    }

    /**
     - Returns: `true` if the parser is at end
     */
    public func atEnd() -> Bool {
        return self.currentChar == nil
    }

    func tokenFrom(start: String.CharacterView.Index) -> String {
        let end: String.CharacterView.Index
        if self.index > self.characters.startIndex {
            end = max(self.index.predecessor(), start)
        }
        else {
            end = max(self.index, start)
        }
        return self.source.substringWithRange(start...end)
    }

    /**
     Parse next token.

     - Returns: currently parsed SourceToken
     */
    public func nextToken() -> Token {
        let tokenKind: TokenKind
        var value: String? = nil

        self.skipWhitespace()

        guard !self.atEnd() else {
            return nil
        }

        let start = self.index

        if DecimalDigitCharacterSet ~= self {
            self.scanWhile(DecimalDigitCharacterSet)

            if IdentifierStart ~= self {
                let invalid = self.currentChar == nil ? "(nil)" : String(self.currentChar!)
                self.error = "Invalid character \(invalid) in number"
                tokenKind = .Error(self.error!)
            }
            else {
                tokenKind = .IntLiteral
            }
        }
        else if IdentifierStart ~= self {
            self.scanWhile(IdentifierCharacters)

            value = self.tokenFrom(start)
            let upvalue = value!.uppercaseString

            // Case insensitive compare
            if self.keywords.contains(upvalue) {
                tokenKind = .Keyword
                value = upvalue
            }
            else {
                tokenKind = .Identifier
            }
        }
        else if "\"" ~= self {
            tokenKind = self.scanString()
        }
        else if OperatorCharacters ~= self {
            tokenKind = .Operator
        }
        else{
            var message: String
            let value = self.tokenFrom(start)

            if self.currentChar != nil {
                message = "Unexpected character '\(self.currentChar!)'"
            }
            else {
                message = "Unexpected end"
            }
            
            self.error = message + " around \(value)'"
            tokenKind = .Error(self.error!)
        }

        self.currentToken = Token(tokenKind, value ?? self.tokenFrom(start))

        return self.currentToken
    }

    func scanString() -> TokenKind {
        // Second quote
        if self.accept("\"") {
            // If not third quote, then we have empty string
            if !self.accept("\"") {
                return .StringLiteral
            }
            else {
                while(self.scanUntil("\"")){
                    if self.accept("\"") && self.accept("\"") {
                        return .StringLiteral
                    }
                }
            }
        }
        else {
            // Parse normal string here
            while(!self.atEnd()) {
                if self.accept("\\") {
                    self.advance()
                }
                else if self.accept("\""){
                    return .StringLiteral
                }
            }
        }
        self.error = "Unexpected end of input in a string"
        return .Error(self.error!)

    }
}

infix operator ~ { }


public func ~=(left:CharacterSet, lexer: Lexer) -> Bool {
    return lexer.accept(left)
}

public func ~=(left:Character, lexer: Lexer) -> Bool {
    return lexer.accept(left)
}
