//
//  Parser.swift
//  AgentFarms
//
//  Created by Stefan Urbanek on 10/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public enum TokenType:Int {
    case Error = 0
    case End
    case Integer, Symbol
    case Keyword, Description
    case Comma, Arrow, Dot
    case Times
}

public let Keywords = [
    // Model Objects
    "CONCEPT", "TAG", "COUNTER", "SLOT",
    "STRUCT","OBJECT", "BIND", "OUTLET", "AS",
    "PROBE",
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
    "ROOT", "THIS", "OTHER"
]

public struct SourceToken {
    public let type: TokenType
    public let value: String?
}


/**
    Tokenize the model source into lexical units.
*/

public class Lexer {
    let source: String
    var currentChar: Character?
    var currentLine: Int
    var chars: String.CharacterView
    var pos: String.CharacterView.Index!

    public var currentToken: SourceToken?

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

    public func parse() -> [SourceToken]{
        var tokens = [SourceToken]()

        while(true) {
            let token = self.nextToken()
            
            tokens.append(token)
            if token.type == TokenType.End ||
                token.type == TokenType.Error {
                    break
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
        while(isspace(self.currentChar)){
            self.nextChar()
        }
    }

    /**
        - Returns: `true` if the parser is at end
    */
    public func atEnd() -> Bool {
        return self.pos >= self.chars.endIndex
    }

    /**
        Parse next token.
    
        - Returns: currently parsed SourceToken
    */
    public func nextToken() -> SourceToken {
        let start: String.CharacterView.Index
        let end: String.CharacterView.Index
        var type: TokenType = TokenType.Error

        if self.currentToken?.type == TokenType.Error {
            return self.currentToken!
        }

        self.skipWhitespace()
        start = self.pos

        if self.atEnd() {
            self.currentToken = SourceToken(type:TokenType.End, value:nil)
            return self.currentToken!
        }

        if isnumber(self.currentChar) {
            while(isnumber(self.nextChar())) {
            }
            if isalpha(self.currentChar) || self.currentChar == "_" {
                type = TokenType.Error
            }
            else {
                type = TokenType.Integer
            }
        }
        else if isalpha(self.currentChar) {
            while(isidentifier(self.nextChar())){
            }
            type = TokenType.Symbol
        }
        else if self.currentChar == "." {
            self.nextChar()
            type = TokenType.Dot
        }
        else if self.currentChar == "," {
            self.nextChar()
            type = TokenType.Comma
        }
        else if self.currentChar == "*" {
            self.nextChar()
            type = TokenType.Times
        }
        else if self.currentChar == "-" {
            if self.nextChar() == ">" {
                self.nextChar()
                type = TokenType.Arrow
            }
        }
        else {
            self.nextChar()
        }

        end = self.pos.predecessor()
        var value = self.source.substringWithRange(start...end)

        if type == TokenType.Symbol && Keywords.contains(value.uppercaseString) {
            value = value.uppercaseString
            type = TokenType.Keyword
        }

        self.currentToken = SourceToken(type:type, value:value)
        return self.currentToken!
    }

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

    public var currentValue: String?

    // TODO: Add the following
    // * symbol location
    // * symbol type

    /**
        Creates a model parser from a source string.
    */
    public init(source:String) {
        self.lexer = Lexer(source:source)
        self.lexer.nextToken()
    }


    public var currentLine: Int {
        return lexer.currentLine
    }

    func accept(type:TokenType,_ value:String?=nil) throws -> Bool {
        if let token:SourceToken = self.lexer.currentToken {
            if token.type == TokenType.Error {
                throw SyntaxError.Parser(message: "Parser error")
            }
            if token.type == type && (value == nil || token.value == value){
                    self.currentValue = token.value
                    self.lexer.nextToken()
                    return true
            }
            return false
        }
        else {
            return false
        }
    }

    // Convenience
    func acceptKeyword(keyword: String) throws -> Bool {
        return try self.accept(TokenType.Keyword, keyword)
    }

    /** Expects a token */
    func expect(type:TokenType,_ value:String?=nil,
        expected:String?=nil) throws -> String {

        if try self.accept(type, value) {
            return currentValue!
        }

        let currValue:String = self.lexer.currentToken!.value ?? "(nil)"
        let currType:String = String(self.lexer.currentToken!.type) ?? "(nil)"

        if expected != nil {
            self.error = "Expected \(expected!), got '\(currValue)'"
        }
        else {
            let displayValue: String

            displayValue = value ?? "(nil)"

            self.error = "Expected \(type) '\(displayValue)', " +
                            "got \(currType) '\(currValue)'"
        }
        self.offendingToken = self.currentValue

        throw SyntaxError.Syntax(message: self.error!)
    }

    // Convenience
    func expectKeyword(keyword: String, expected:String?=nil) throws
        -> String {
            return try self.expect(TokenType.Keyword, keyword,
                expected: expected)
    }

    /**
        Expects the next token to be a symbol. Human readable description
        of the expected symbol can be provided as `expected` – it will be 
        displayed to the user on compilation error.
    */
    func expectSymbol(expected:String?=nil) throws -> Symbol {
        return try self.expect(TokenType.Symbol, expected: expected)
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
        var probes = [Probe]()

        while(true) {
            if let concept = try self._concept() {
                concepts[concept.name] = concept
            }
            else if let actuator = try self._actuator() {
                actuators.append(actuator)
            }
            else if let world = try self._world() {
                worlds.append(world)
            }
            else if let probe = try self._probe() {
                probes.append(probe)
            }
            else if try self.accept(TokenType.End) {
                break
            }
            else {
                let message: String
                let value = self.lexer.currentToken!.value
                message = "Expecting model object, got '\(value)'"
                throw SyntaxError.Syntax(message: message)
            }

        }

        let model = Model(concepts:concepts, actuators:actuators,
                        worlds:worlds)

        return model
    }

    /**
        Parse concept description:
    
            concept := CONCEPT name [TAGS tags] [SLOTS slots] [COUNTERS counters]
    */
    func _concept() throws -> Concept? {
        var tags: TagList? = nil
        var slots: SlotList? = nil

        if try !self.acceptKeyword("CONCEPT") {
            return nil
        }

        let name = try self.expect(TokenType.Symbol, expected: "concept name")

        if try self.acceptKeyword("TAG") {
            tags = TagList(try self._symbolList())
        }

        if try self.acceptKeyword("SLOT") {
            slots = SlotList(try self._symbolList())
        }

        let concept = Concept(name: name, tags: tags, slots: slots)
        return concept
    }

    func _world() throws -> World? {
        var root: Symbol? = nil
        var name: Symbol
        let graph = GraphDescription()

        if try !self.acceptKeyword("WORLD") {
            return nil
        }

        name = try self.expectSymbol("world name")

        if try self.acceptKeyword("ROOT") {
            root = try self.expectSymbol("root concept")
        }

        while true {
            if try self.acceptKeyword("OBJECT") {
                var concept: Symbol
                var alias: Symbol?
                var count: Int?

                while true {
                    (concept, alias, count) = try self._instanceSpec()

                    if alias == nil && count == nil {
                        graph.addObject(concept)
                    }
                    else if alias != nil {
                        graph.addObject(concept, alias: alias)
                    }
                    else if count != nil {
                        graph.addObjectCount(concept, count: count!)
                    }
                    else {
                        // TODO: This should not happen
                        throw SyntaxError.Internal(message: "Instance should not have both count and alias")
                    }

                    if try !self.accept(TokenType.Comma) {
                        break
                    }
                }

            }
            else if try self.acceptKeyword("BIND") {
                var source: Symbol
                var sourceSlot: Symbol
                var target: Symbol

                while true {
                    source = try self.expectSymbol("source object")
                    try self.expect(TokenType.Dot)
                    sourceSlot = try self.expectSymbol("source slot")
                    try self.expectKeyword("TO")
                    target = try self.expectSymbol("target object")

                    graph.bind(source, sourceSlot: sourceSlot, target: target)

                    if try !self.accept(TokenType.Comma) {
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
    func _instanceSpec() throws -> (Symbol, Symbol?, Int?) {
        let concept: Symbol

        concept = try self.expectSymbol("concept name")

        if try self.acceptKeyword("AS") {
            let alias = try self.expectSymbol("object alias")
            return (concept, alias, nil)
        }
        else if try self.accept(TokenType.Times) {
            let count = try self.expect(TokenType.Integer, expected:"instance count")
            return (concept, nil, Int(count))
        }
        else {
            return (concept, nil, nil)
        }

    }

    /** Parse actuator:
     
    Examples:

        WHERE predicates DO actions
        WHERE predicates ON predicates DO actions
    
    Rule:

        actuator := WHERE selector DO actions

     */
    func _actuator() throws -> Actuator? {
        var predicates: [Predicate]
        var otherPredicates: [Predicate]?
        var actions = [Action]()
        var isRoot:Bool

        if try self.acceptKeyword("WHERE") {
            (isRoot, predicates, otherPredicates) = try self._selector()
        }
        else {
            return nil
        }

        try self.expectKeyword("DO")

        actions = try self._actions()

        return Actuator(predicates:predicates, actions:actions,
                otherPredicates:otherPredicates, isRoot:isRoot)
    }

    /**
     
     ```
     selector := ( ALL | [ROOT] predicates ) [ON (ALL | predicates)]
     ```
     */
    func _selector() throws -> (Bool, [Predicate], [Predicate]?) {
        var isRoot:Bool = false
        var predicates: [Predicate]
        var otherPredicates: [Predicate]? = nil

        if try self.acceptKeyword("ALL") {
            // ALL -> only one predicate
            predicates = [AllPredicate()]
        }
        else {
            isRoot = try self.acceptKeyword("ROOT")
            // rest of the predicates
            predicates = try self._predicates()
        }

        // Is interactive?
        if try self.acceptKeyword("ON") {
            if try self.acceptKeyword("ALL") {
                // ALL -> only one predicate
                otherPredicates = [AllPredicate()]
            }
            else {
                // rest of the predicates
                otherPredicates = try self._predicates()
            }
        }

        return (isRoot, predicates, otherPredicates)
    }

    func _predicates() throws -> [Predicate] {
        var predicates = [Predicate]()
        var isNegated: Bool

        if try self.acceptKeyword("ALL") {
            predicates = [AllPredicate()]
            return predicates
        }

        // TODO: implement IN slot
        // TODO: implement tag list, no commas so it reads: open jar
        while true {
            isNegated = try self.acceptKeyword("NOT")

            if try self.accept(TokenType.Symbol) {
                let tag = self.currentValue!
                let predicate = TagSetPredicate(tags:[tag], isNegated:isNegated)
                predicates.append(predicate)
            }
            else if try self.accept(TokenType.Keyword, "BOUND") {
                let slot = try self.expectSymbol()
                let predicate = IsBoundPredicate(slot:slot, isNegated:isNegated)
                predicates.append(predicate)
            }
            else {
                let token = self.currentValue
                throw SyntaxError.Syntax(message: "Expected predicate, got '\(token)'")
            }

            if try !self.acceptKeyword("AND") {
                break
            }

        }

        return predicates
    }

    func _actions() throws -> [Action] {
        var actions = [Action]()
        var context: ObjectContextType = ObjectContextType.This
        var slot: Symbol? = nil

        while true {
            if try self.acceptKeyword("IN") {
                (context, slot) = try self._context()
            }

            if try self.acceptKeyword("NOTHING") {
                actions.append(NoAction())
            }
            else if try self.acceptKeyword("TRAP") {
                var symbol: Symbol? = nil
                if try self.accept(TokenType.Symbol) {
                    symbol = self.currentValue
                }
                actions.append(TrapAction(type: symbol))
            }
            else if try self.acceptKeyword("NOTIFY") {
                var symbol: Symbol? = nil
                if try self.accept(TokenType.Symbol) {
                    symbol = self.currentValue
                }
                actions.append(NotifyAction(symbol: symbol))
            }
            else if try self.acceptKeyword("SET") {
                let tags = try self._symbolList()
                let action = SetTagsAction(inContext: context, inSlot:slot,
                                    tags: TagList(tags))
                actions.append(action)
            }
            else if try self.acceptKeyword("UNSET") {
                let tags = try self._symbolList()
                let action = UnsetTagsAction(inContext: context, inSlot:slot,
                                    tags: TagList(tags))
                actions.append(action)
            }
            else if try self.acceptKeyword("BIND") {
                let symbol:Symbol
                var targetContext: ObjectContextType?
                var targetSlot: Symbol? = nil

                symbol = try self.expectSymbol()

                try self.expectKeyword("TO")

                (targetContext, targetSlot) = try self._target()
                // Make the target context consistent with the 'IN' context
                if targetContext == nil {
                    targetContext = context
                }

                let action = BindAction(inContext: context, inSlot: slot,
                    slot:symbol, targetContext:targetContext!, targetSlot:targetSlot)

                actions.append(action)
            }
            else {
                break
            }

        }

        return actions
    }

    func _context() throws -> (ObjectContextType, Symbol?) {
        let context: ObjectContextType
        var slot: Symbol? = nil

        context = try self._contextType()

        if try self.accept(TokenType.Dot) {
            slot = try self.expectSymbol("slot name")
        }

        return (context, slot)
    }
    func _contextType() throws -> ObjectContextType {
        if try self.acceptKeyword("THIS") {
            return ObjectContextType.This
        }
        else if try self.acceptKeyword("OTHER") {
            return ObjectContextType.Other
        }
        else {
            try self.expectKeyword("ROOT",
                          expected: "Expected context specified THIS, OTHER or ROOT")
            return ObjectContextType.Root
        }
    }
    func _target() throws -> (ObjectContextType?, Symbol?) {
        var context: ObjectContextType? = nil
        var slot: Symbol? = nil

        if try self.accept(TokenType.Symbol) {
            slot = self.currentValue
        }
        else {
            context = try self._contextType()
            if try self.accept(TokenType.Dot) {
                slot = try self.expectSymbol("target slot name")
            }
        }

        return (context, slot)
    }

    /**
         PROBE counter IN ROOT
         PROBE open_jars COUNT WHERE jar AND open
         PROBE closed_jars COUNT WHERE jar AND closed
         PROBE all_jars COUNT WHERE jar
         PROBE free_lids COUNT WHERE lid AND free
         PROBE all_lids COUNT WHERE lid OR open
     */
    func _probe() throws -> Probe? {
        let name: Symbol
        let function: ProbeFunction

        if try !self.acceptKeyword("PROBE") {
            return nil
        }


        name = try self.expectSymbol("probe name")

        if try self.acceptKeyword("COUNT") {
            function = ProbeFunction.Count
        }
        else if try self.acceptKeyword("SUM") {
            function = ProbeFunction.Sum
        }
        else if try self.acceptKeyword("AVG") {
            function = ProbeFunction.Avg
        }
        else if try self.acceptKeyword("MIN") {
            function = ProbeFunction.Min
        }
        else {
            try self.expectKeyword("MAX")
            function = ProbeFunction.Max
        }

        let predicates = try self._predicates()

        let probe = AggregateProbe(name: name, type: ProbeType.Aggregate,
            function: function, predicates: predicates)

        return probe
    }

    /** Parse list of symbols:
    
        symbol_list := symbol [, symbol]*
    */
    func _symbolList() throws -> [Symbol] {
        var symbols = [Symbol]()
        let first = try self.expect(TokenType.Symbol)

        symbols.append(first)

        while(try self.accept(TokenType.Comma)) {
            let symbol = try self.expect(TokenType.Symbol)
            symbols.append(symbol)
        }

        return symbols
    }
    func ___tagList() throws -> TagList? {
        var tags = TagList()

        while(try self.accept(TokenType.Symbol)) {
            let tag = self.currentValue!
            tags.insert(tag)

            if try !self.accept(TokenType.Comma) {
                break
            }
        }

        return tags
    }

}
