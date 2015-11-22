//
//  Parser.swift
//  AgentFarms
//
//  Created by Stefan Urbanek on 10/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public enum Token: CustomStringConvertible, Equatable {
    case Error(String)
    case End
    case Integer(Int)
    case Symbol(String)
    case Keyword(String)
    case Description(String)
    case Comma
    case Arrow
    case Dot
    case Less
    case Greater
    case Times

    public var description: String {
        switch self {
        case Error(let error):
            return "parser error: \(error)"
        case End:
            return "end"
        case Integer(let value):
            return "integer \(value)"
        case Symbol(let symbol):
            return "symbol \"\(symbol)\""
        case Keyword(let keyword):
            return "\(keyword)"
        case Description( _):
            return "description"
        case Comma:
            return "comma ','"
        case Arrow:
            return "arrow '->'"
        case Dot:
            return "dot '.'"
        case Less:
            return "less '<'"
        case Greater:
            return "greater '>'"
        case Times:
            return "times '*'"
        }
    }
}

public func ==(left: Token, right: Token) -> Bool {
    switch (left, right) {
    case (.Error(let lstr), .Error(let rstr)) where lstr == rstr:
        return true
    case (.End, .End):
        return true
    case (.Integer(let lint), .Integer(let rint)) where lint == rint:
        return true
    case (.Symbol(let lstr), .Symbol(let rstr)) where lstr == rstr:
        return true
    case (.Keyword(let lstr), .Keyword(let rstr)) where lstr == rstr:
        return true
    case (.Description(let lstr), .Description(let rstr)) where lstr == rstr:
        return true
    case (.Comma, .Comma):
        return true
    case (.Arrow, .Arrow):
        return true
    case (.Dot, .Dot):
        return true
    case (.Less, .Less):
        return true
    case (.Greater, .Greater):
        return true
    case (.Times, .Times):
        return true
    default:
        return false
    }
}

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


/**
    Tokenize the model source into lexical units.
*/

public class Lexer {
    let source: String
    var currentChar: Character?
    var currentLine: Int
    var chars: String.CharacterView
    var pos: String.CharacterView.Index!

    public var currentToken: Token!

    /**
        Initialize the lexer with model source.
    */
    public init(source:String) {
        self.source = source
        self.chars = self.source.characters

        self.currentChar = nil
        self.currentLine = 1
        self.pos = nil

        self.nextChar()
    }

    public func parse() -> [Token]{
        var tokens = [Token]()

        loop: while(true) {
            let token = self.next()
            
            tokens.append(token)

            switch token {
            case .Error: break loop
            case .End: break loop
            default: break // switch
            }
        }

        return tokens
    }

    /**
        Advance to the next character and set current character.
    */
    func nextChar() -> Character! {
        if self.pos == nil {
            self.pos = self.chars.startIndex
        }
        else if self.pos < self.chars.endIndex {
            self.pos = self.pos.successor()
        }

        if self.pos >= self.chars.endIndex {
            self.currentChar = nil
            return nil
        }

        self.currentChar = self.chars[self.pos]
        self.currentChar = self.chars[self.pos]
        if self.currentChar == "\n" {
            self.currentLine += 1
        }

        return self.currentChar
    }

    /// Advance to the next non-whitespace character
    public func skipWhitespace() {
        while(!self.atEnd()){
            if self.currentChar == "#" {
                while(self.currentChar != "\n" && !self.atEnd()) {
                    self.nextChar()
                }
            }
            else if isspace(self.currentChar) {
                self.nextChar()
            }
            else {
                break
            }
        }
    }

    /**
        - Returns: `true` if the parser is at end
    */
    public func atEnd() -> Bool {
        return self.pos >= self.chars.endIndex
    }

    func tokenFrom(start: String.CharacterView.Index) -> String {
        let end = self.pos.predecessor()
        return self.source.substringWithRange(start...end)
    }

    /** Accept characters that are equal to the `char` character */
    private func accept(char: Character) -> Bool {
        if self.currentChar == char {
            self.nextChar()
            return true
        }
        else {
            return false
        }
    }

    /** Accept characters that match `test` predicate */
    private func accept(test: Character -> Bool) -> Bool {
        if self.currentChar != nil && test(self.currentChar!) {
            self.nextChar()
            return true
        }
        else {
            return false
        }
    }

    /**
        Parse next token.
    
        - Returns: currently parsed SourceToken
    */
    public func next() -> Token {
        let start: String.CharacterView.Index
        var token: Token

        self.skipWhitespace()

        start = self.pos

        if self.atEnd() {
            token = Token.End
        }
        else if self << isnumber {
            self <<* isnumber

            if isalpha(self.currentChar) || self.currentChar == "_" {
                token = Token.Error("Invalid character \(self.currentChar) in number")
            }
            else {
                let value = self.tokenFrom(start)
                if let ivalue = Int(value) {
                    token = Token.Integer(ivalue)

                }
                else {
                    token = Token.Error("Can't convert '\(value)' to integer")
                }
            }
        }
        else if self << isalpha {
            self <<* isidentifier

            let value = self.tokenFrom(start)
            let upvalue = value.uppercaseString

            if Keywords.contains(upvalue) {
                token = Token.Keyword(upvalue)
            }
            else {
                token = Token.Symbol(value)
            }
        }
        else if self << "." {
            token = Token.Dot
        }
        else if self << "," {
            token = Token.Comma
        }
        else if self << "*" {
            token = Token.Times
        }
        else if self << "<" {
            token = Token.Less
        }
        else if self << ">" {
            token = Token.Greater
        }
        else if self << "-" {
            if self << ">" {
                token = Token.Arrow
            }
            else {
                token = Token.Error("Invalid character '-'. Did you mean '->'?")
            }
        }
        else {
            token = Token.Error("Invalid character '\(self.currentChar)'")
        }

        self.currentToken = token

        return token
    }
}

public func <<(lexer: Lexer, char: Character) -> Bool {
    return lexer.accept(char)
}

public func <<(lexer: Lexer, test: Character -> Bool) -> Bool {
    return lexer.accept(test)
}

/// Accept zero or more times
infix operator <<* {}
public func <<*(lexer: Lexer, test: Character -> Bool) -> Bool {
    while(lexer << test) { /* just skip */ }
    return true
}

// MARK: Parser

public enum SyntaxError: ErrorType {
    case Parser(message:String)
    case Syntax(message:String)
    case Internal(message:String)
}

/**
    Model source parser.
*/
public class Parser {
    public let lexer: Lexer
    public var error: String?
    public var offendingToken: String?

    // TODO: Add the following
    // * symbol location
    // * symbol type

    /**
        Creates a model parser from a source string.
    */
    public init(source:String) {
        self.lexer = Lexer(source:source)
        self.lexer.next()
    }


    public var currentLine: Int {
        return lexer.currentLine
    }

    func accept(token: Token) -> Bool {
        if token == self.lexer.currentToken {
            self.lexer.next()
            return true
        }
        else {
            return false
        }
    }

    func acceptKeyword(keyword: String) -> Bool {
        if self.lexer.currentToken == nil {
            return false
        }

        switch self.lexer.currentToken! {
        case .Keyword(let value) where value == keyword:
            self.lexer.next()
            return true
        default:
            return false
        }
    }

    private func makeUnexpected(expected: String) -> SyntaxError {
        let unexpected: String
        if self.lexer.currentToken == nil {
            unexpected = "nothing"
        }
        else {
            unexpected = String(self.lexer.currentToken)
        }

        let error = "Expected \(expected), got \(unexpected)"

        return SyntaxError.Syntax(message: error)
    }

    /**
        Expects the next token to be a symbol. Human readable description
        of the expected symbol can be provided as `expected` – it will be 
        displayed to the user on compilation error.
    */
    func expectSymbol(expected:String?=nil) throws -> Symbol {
        let alias = expected ?? "symbol"

        if self.lexer.currentToken != nil {
            switch self.lexer.currentToken! {
            case .Symbol(let value):
                self.lexer.next()
                return value
            default: break
            }
        }

        throw self.makeUnexpected(alias)
    }


    // TODO: do we need the -> Bool here?
    func expectKeyword(keyword: String, expected: String?=nil) throws -> Bool {
        if self.acceptKeyword(keyword) {
            return true
        }
        else {
            if expected != nil {
                throw self.makeUnexpected(expected!)
            }
            else {
                throw self.makeUnexpected("keyword \(keyword)")
            }
        }
    }

    func expectInteger(expectation: String) throws -> Int {
        if self.lexer.currentToken != nil {
            switch self.lexer.currentToken! {
            case .Integer(let value):
                self.lexer.next()
                return value
            default: break
            }
        }
        throw self.makeUnexpected(expectation)
    }



    /** Expects a token */
    func expect(token:Token) throws -> Bool {

        if self.accept(token) {
            return true
        }

        throw self.makeUnexpected(String(token))
    }

    /**
        Compile the source code
    
        - Returns: Compiled `Model`
    */
    public func compile() -> Model? {
        do {
            let model = try self._model()
            return model
        }
        catch SyntaxError.Syntax(let message) {
            // TODO: nicer error summary here
            self.error = message
            return nil
        }
        catch SyntaxError.Parser(let message) {
            // TODO: nicer error summary here
            self.error = message
            return nil
        }
        catch {
            self.error = "Unknown error"
            return nil
        }
    }


    /*
        model := concept
    */
    func _model() throws -> Model? {
        var concepts = [Symbol:Concept]()
        var actuators = [Actuator]()
        var worlds = [World]()
        var measures = [Measure]()

        while(true) {

            if self << "CONCEPT" {
                let concept = try self._concept()
                concepts[concept.name] = concept
            }
            else if self << "WHERE" {
                let actuator = try self._actuator()
                actuators.append(actuator)
            }
            else if self << "WORLD" {
                let world = try self._world()
                worlds.append(world)
            }
            else if self << "MEASURE" {
                let measure = try self._measure()
                measures.append(measure)
            }
            else if self << .End {
                break
            }
            else {
                throw self.makeUnexpected("model object")
            }
        }

        let model = Model(concepts:concepts, actuators:actuators,
            measures:measures, worlds:worlds)

        return model
    }

    /**
        Parse concept description:
    
            concept := CONCEPT name [TAGS tags] [SLOTS slots] [COUNTERS counters]
    */
    func _concept() throws -> Concept {
        var tags = TagList()
        var slots = SlotList()

        let name = try self.expectSymbol("concept name")

        while(true) {
            if self << "TAG" {
                // TODO: check for multiple tag redefinition
                let newTags = TagList(try self.parseSymbolList())
                tags.unionInPlace(newTags)
            }
            else if self << "SLOT" {
                // TODO: check for multiple slot redefinition
                let newSlots = SlotList(try self.parseSymbolList())
                slots.appendContentsOf(newSlots)
            }
            else {
                break
            }

        }

        let concept = Concept(name: name, tags: tags, slots: slots)
        return concept
    }

    func _world() throws -> World {
        var root: Symbol? = nil
        var name: Symbol
        let graph = GraphDescription()

        name = try self.expectSymbol("world name")

        if self << "ROOT" {
            root = try self.expectSymbol("root concept")
        }

        while true {
            if self << "OBJECT" {
                while true {
                    let obj = try self._instanceSpec()
                    graph.addObject(obj)

                    if !self.accept(.Comma) {
                        break
                    }
                }

            }
            else if self << "BIND" {
                var source: Symbol
                var sourceSlot: Symbol
                var target: Symbol

                while true {
                    source = try self.expectSymbol("source object")
                    try self.expect(.Dot)
                    sourceSlot = try self.expectSymbol("source slot")
                    try self.expectKeyword("TO")
                    target = try self.expectSymbol("target object")

                    graph.bind(source, sourceSlot: sourceSlot, target: target)

                    if !self.accept(.Comma) {
                        break
                    }
                }
            }
            else {
                break
            }
        }
        return World(name:name, contents: graph, root:root)
    }

    /** Parse instance specification

    Examples:
    
        link AS first


     */
    func _instanceSpec() throws -> ContentObject {
        let concept: Symbol

        concept = try self.expectSymbol("concept name")

        if self << "AS" {
            let alias = try self.expectSymbol("object alias")
            return .Named(concept, alias)
        }
        else if self << .Times {
            let count = try self.expectInteger("instance count")
            return .Many(concept, count)
        }
        else {
            return .Many(concept, 1)
        }

    }

    /** Parse actuator:
     
    Examples:

        WHERE predicates DO actions
        WHERE predicates ON predicates DO actions
    
    Rule:

        actuator := WHERE selector DO actions

     */
    func _actuator() throws -> Actuator {
        var modifiers = [Modifier]()
        let selector: Selector
        var notifications = [Symbol]()
        var traps = [Symbol]()
        let doesHalt: Bool

        selector = try self._selector()

        try self.expectKeyword("DO")

        modifiers = try self._modifiers()

        if self << "NOTIFY" {
            let symbols = try self.parseSymbolList()
            notifications.appendContentsOf(symbols)
        }

        if self << "TRAP" {
            let symbols = try self.parseSymbolList()
            traps.appendContentsOf(symbols)
        }

        if self << "HALT" {
            doesHalt = true
        }
        else {
            doesHalt = false
        }

        return Actuator(selector:selector, modifiers:modifiers,
            traps: traps, notifications: notifications,
            doesHalt:doesHalt)
    }

    /**
     
     ```
     selector := ( ALL | [ROOT] predicates ) [ON (ALL | predicates)]
     ```
     */
    func _selector() throws -> Selector {
        var isRoot:Bool = false
        var predicates: [Predicate]
        var otherPredicates: [Predicate]? = nil

        if self << "ALL" {
            // ALL -> only one predicate
            predicates = []
        }
        else {
            isRoot = self << "ROOT"
            // rest of the predicates
            predicates = try self._predicates()
        }

        // Is interactive?
        if self << "ON" {
            if self << "ALL" {
                // ALL -> only one predicate
                otherPredicates = [Predicate(.All)]
            }
            else {
                // rest of the predicates
                otherPredicates = try self._predicates()
            }
        }

        return Selector(predicates: predicates,
                         otherPredicates: otherPredicates,
                         isRoot: isRoot)
    }

    func _predicates() throws -> [Predicate] {
        var predicates = [Predicate]()
        var predicate: Predicate
        var isNegated: Bool

        // TODO: Why again?? Check the grammar!
        if self << "ALL" {
            predicates = [Predicate(.All)]
            return predicates
        }

        // TODO: implement IN slot
        // TODO: implement tag list, no commas so it reads: open jar
        while true {
            isNegated = self << "NOT"

            if self << "SET" {
                let tags = try self._tagList()

                predicate = Predicate(.TagSet(tags), isNegated)
            }
            else if self << "UNSET" {
                let tags = try self._tagList()

                predicate = Predicate(.TagUnset(tags), isNegated)
            }
            else if self << "ZERO" {
                let counter = try self.expectSymbol()

                predicate = Predicate(.CounterZero(counter), isNegated)
            }
            else if self << "BOUND" {
                let slot = try self.expectSymbol()

                predicate = Predicate(.IsBound(slot), isNegated)
            }
            else {
                // TODO: If we decide to classify symbols, don't forget
                // about this one
                let symbol = try self.expectSymbol("counter name or tag")

                if self.accept(.Less) {
                    let value = try self.expectInteger("counter value")
                    predicate = Predicate(.CounterLess(symbol, value))
                }
                else if self.accept(.Greater) {
                    let value = try self.expectInteger("counter value")
                    predicate = Predicate(.CounterGreater(symbol, value))
                }
                else if self << .Comma {
                    var tags = try self._tagList()
                    tags.insert(symbol)
                    predicate = Predicate(.TagSet(tags), isNegated)
                    // taglist
                }
                else {
                    predicate = Predicate(.TagSet(TagList([symbol])), isNegated)
                }
            }

            predicates.append(predicate)

            if !self.acceptKeyword("AND") {
                break
            }

        }

        return predicates
    }

    func _modifiers() throws -> [Modifier] {
        var modifiers = [Modifier]()

        while true {
            if let modifier = try self._modifier() {
                modifiers.append(modifier)
            }
            else {
                break
            }
        }

        if modifiers.isEmpty {
            throw SyntaxError.Syntax(message: "expected at least one modifier")
        }

        return modifiers
    }

    /** Parses a single instruction string */
    public func parseModifier() -> Modifier? {
        do {
            if let modifier = try self._modifier() {
                try self.expect(.End)
                return modifier
            }
        }
        catch SyntaxError.Syntax(let message) {
            self.error = message
        }
        catch {
            self.error = "Unknown error"
            return nil
        }
        return nil
    }

    public func _modifier() throws -> Modifier? {
        let action: ModifierAction
        let ref: CurrentRef

        // TODO: make this part of modifier instruction only
        if self << "IN" {
            ref = try self._currentReference()
        }
        else {
            ref = CurrentRef(type:.This, slot:nil)
        }

        if self << "NOTHING" {
            action = .Nothing
        }
        else if self << "SET" {
            let tags = try self._tagList()

            action = .SetTags(tags)
        }
        else if self << "UNSET" {
            let tags = try self._tagList()

            action = .UnsetTags(tags)
        }
        else if self << "BIND" {
            let targetRef: CurrentRef
            let symbol: Symbol

            symbol = try self.expectSymbol()

            try self.expectKeyword("TO")

            targetRef = try self._currentReference()

            action = .Bind(targetRef, symbol)
        }
        else if self << "UNBIND" {
            let symbol = try self.expectSymbol()

            action = .Unbind(symbol)
        }
        else {
            return nil
        }

        return Modifier(currentRef:ref, action:action)
    }

    /** Parse a current reference: */
    func _currentReference() throws -> CurrentRef {
        let type: CurrentType
        var slot: Symbol? = nil

        type = try self._currentType()

        if self << .Dot {
            slot = try self.expectSymbol("slot name")
        }

        return CurrentRef(type:type, slot:slot)
    }

    func _currentType() throws -> CurrentType {
        if self << "THIS" {
            return .This
        }
        else if self << "OTHER" {
            return .Other
        }
        else {
            // FIXME: expected: "context specified THIS, OTHER or ROOT")
            try self.expectKeyword("ROOT")
            return .Root
        }
    }

    /**
         MEASURE counter IN ROOT
         MEASURE open_jars COUNT WHERE jar AND open
         MEASURE closed_jars COUNT WHERE jar AND closed
         MEASURE all_jars COUNT WHERE jar
         MEASURE free_lids COUNT WHERE lid AND free
         MEASURE all_lids COUNT WHERE lid OR open
     */
    func _measure() throws -> Measure {
        let name: Symbol
        let function: AggregateFunction
        let counter: Symbol

        name = try self.expectSymbol("measure name")

        if self << "COUNT" {
            function = AggregateFunction.Count
        }
        else if self << "SUM" {
            counter = try self.expectSymbol("counter name")
            function = AggregateFunction.Sum(counter)
        }
        else if self << "MIN" {
            counter = try self.expectSymbol("counter name")
            function = AggregateFunction.Min(counter)
        }
        else {
            try self.expectKeyword("MAX", expected: "aggregate function")
            counter = try self.expectSymbol("counter name")
            function = AggregateFunction.Max(counter)
        }

        let predicates = try self._predicates()

        // TODO: we support only aggregate function now
        let measure = Measure(name: name, type:.Aggregate(function, predicates))

        return measure
    }

    /** Parse list of symbols:
    
        symbol_list := symbol [, symbol]*
    */
    public func parseSymbolList() throws -> [Symbol] {
        var symbols = [Symbol]()
        let first = try self.expectSymbol()

        symbols.append(first)

        while(self << .Comma) {
            let symbol = try self.expectSymbol()
            symbols.append(symbol)
        }

        return symbols
    }

    func _tagList() throws -> TagList {
        return try TagList(self.parseSymbolList())
    }

}

public func <<(parser: Parser, keyword: String) -> Bool {
    return parser.acceptKeyword(keyword)
}

public func <<(parser: Parser, token: Token) -> Bool {
    return parser.accept(token)
}

