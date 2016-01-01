//
//  Parser.swift
//  AgentFarms
//
//  Created by Stefan Urbanek on 10/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

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


// MARK: Parser

public enum SyntaxError: ErrorType {
    case Parser(String)
    case Syntax(String)
}

infix operator <<§ { associativity left precedence 130 }


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
        self.lexer.advance()
    }


    // TODO: we have way too many parsing methods here. Reason is too many
    // approaches tried over the time. Needs consolidation.

    func accept(token: Token) -> Bool {
        if token == self.lexer.currentToken {
            self.lexer.advance()
            return true
        }
        else {
            return false
        }
    }

    func token(tokenKind: TokenKind) -> String? {
        if  self.lexer.currentToken.kind == tokenKind {
            let text = self.lexer.currentToken.text
            self.lexer.advance()
            return text
        }
        else {
            return nil
        }
    }

    func acceptKeyword(keyword: String) -> Bool {
        return self.accept(Token(.Keyword, keyword))
    }

    private func expectationError(expected: String) -> SyntaxError {
        let unexpected = self.lexer.currentToken.description ?? "nothing"

        let message = "Expected \(expected), got \(unexpected)"

        return SyntaxError.Syntax(message)
    }

    func expect(kind: TokenKind, _ expected:String) throws -> String {
        if self.lexer.currentToken == kind {
            let text = self.lexer.currentToken.text
            self.lexer.advance()
            return text
        }

        throw self.expectationError(expected)
    }

    func expect<T>(rule: () throws -> T?, _ expected: String) throws -> T {
        if let result = try rule() {
            return result
        }
        else {
            throw expectationError(expected)
        }
    }
    /**
        Expects the next token to be a symbol. Human readable description
        of the expected symbol can be provided as `expected` – it will be 
        displayed to the user on compilation error.
    */
    func expectSymbol(expected:String?=nil) throws -> Symbol {
        let alias = expected ?? "symbol"
        return Symbol(try self.expect(.Identifier, alias))
    }

    func expectOperator(op: String) throws {
        try self.expect(.Operator, "\(op)")
    }

    func expectKeyword(keyword: String) throws {
        try self.expect(.Identifier, "keyword \(keyword)")
    }

    func expectInteger(expected: String) throws -> Int {
        let text = Symbol(try self.expect(.Identifier, expected))
        if let value = Int(text) {
            return value
        }
        else {
            throw SyntaxError.Parser("Invalid integer \(text)")
        }
    }

    /** Parse multiple occurences of `rule`
     
     - Returns: list of objects returned by `rule`
     */
    func many<T>(rule:() throws -> T?) throws -> [T] {
            var container = [T]()
            while true {
                if let object = try rule() {
                    container.append(object)
                }
                else {
                    break
                }
            }
            return container
    }
    /** Parse multiple occurences of `rule` separated by token `separator`
     
     - Returns: list of objects returned by `rule`
     */
    func manySeparatedBy<T>(rule:() throws -> T?, _ separator: Token) throws -> [T]? {
        var container = [T]()
        while true {
            if let object = try rule() {
                container.append(object)
            }
            else {
                break
            }

            if !self.accept(separator) {
                break
            }
        }
        if container.isEmpty {
            return nil
        }
        else {
            return container
        }
    }

    /** Parse list of symbols:
    
        symbol_list := symbol [, symbol]*
    */
    public func symbolList() throws -> [Symbol]? {
        return try self.manySeparatedBy(self.symbol, Token(.Operator, ","))
    }

    public func symbol() -> Symbol? {
        return self.token(.Identifier)
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

    func _model() throws -> Model? {
        var concepts = [Symbol:Concept]()
        var actuators = [Actuator]()
        var worlds = [World]()
        var measures = [Measure]()

        while(true) {
            if let concept = try self.concept() {
                concepts[concept.name] = concept
            }
            else if let actuator = try self.actuator() {
                actuators.append(actuator)
            }
            else if let world = try self.world() {
                worlds.append(world)
            }
            else if let measure = try self.measure() {
                measures.append(measure)
            }
            else if self.lexer.currentToken == TokenKind.Empty {
                break
            }
            else {
                throw self.expectationError("model object")
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
    func concept() throws -> Concept? {
        var tags = TagList()
        var slots = SymbolList()

        guard self << "CONCEPT" else {
            return nil
        }

        let name = try self <<§ "concept name"

        while(true) {
            if self << "TAG" {
                tags = tags.union(try self.expect(self.symbolList, "tag list"))
            }
            else if self << "SLOT" {
                slots += try self.expect(self.symbolList, "slot list")
            }
            else {
                break
            }
        }

        let concept = Concept(name: name, tags: tags, slots: slots)
        return concept
    }

    /**
        Parser world
     
        world :=
    */
    func world() throws -> World? {
        var root: Symbol? = nil
        var name: Symbol
        let graph = GraphDescription()

        guard self << "WORLD" else {
            return nil
        }

        name = try self <<§ "world name"

        // [ROOT root_concept]
        if self << "ROOT" {
            root = try self <<§ "root concept"
        }

        while true {
            // OBJECT instance_spec
            if self << "OBJECT" {
                let instances = try self.expect(instanceList, "instance list")
                instances.forEach { instance in
                    graph.addObject(instance)
                }
            }
            else if self << "BIND" {
                let bindings = try self.expect(bindingList, "binding specification list")

                bindings.forEach {
                    (source, sourceSlot, target) in
                    graph.bind(source, sourceSlot: sourceSlot, target: target)
                }
            }
            else {
                break
            }
        }
        return World(name:name, contents: graph, root:root)
    }

    /// Specification of a binding in a structure
    /// binding := source "." slot "TO" target
    func bindingSpec() throws -> (Symbol, Symbol, Symbol) {
        let source: Symbol
        let sourceSlot: Symbol
        let target: Symbol

        source = try self <<§ "source object"

        try self.expectOperator(".")

        sourceSlot = try self <<§ "source slot"

        try self.expectKeyword("TO")

        target = try self <<§ "target object"

        return (source, sourceSlot, target)
    }

    func bindingList() throws -> [(Symbol, Symbol, Symbol)]? {
        return try self.manySeparatedBy(self.bindingSpec, Token(.Operator, ","))
    }
    /** Parse instance specification

    Rule: `symbol (AS

    Examples:
    
        link AS first
     */

    func instanceSpec() throws -> ContentObject {
        let concept: Symbol

        concept = try self <<§ "concept name"

        if self << "AS" {
            let alias = try self <<§ "object alias"
            return .Named(concept, alias)
        }
        else if self.accept(Token(.Operator, "*")) {
            let count = try self.expectInteger("instance count")
            return .Many(concept, count)
        }
        else {
            return .Many(concept, 1)
        }

    }

    func instanceList() throws -> [ContentObject]? {
        return try self.manySeparatedBy(self.instanceSpec, Token(.Operator, ","))
    }

    /** Parse actuator:
     
    Examples:

        WHERE predicates DO actions
        WHERE predicates ON predicates DO actions
    
    Rule:

        actuator := WHERE selector DO actions

     */
    func actuator() throws -> Actuator? {
        var modifiers = [Modifier]()
        let selector: Selector
        let combined: Selector?
        var notifications = [Symbol]()
        var traps = [Symbol]()
        let doesHalt: Bool

        guard self << "WHERE" else {
            return nil
        }

        selector = try self.selector()

        if self << "ON" {
            combined = try self.selector()
        }
        else {
            combined = nil
        }

        try self.expectKeyword("DO")

        modifiers = try self.expect(self.modifiers, "modifiers")

        if self << "NOTIFY" {
            let symbols = try self.expect(symbolList, "list of notification symbols")
            notifications.appendContentsOf(symbols)
        }

        if self << "TRAP" {
            let symbols = try self.expect(symbolList, "list of trap symbols")
            traps.appendContentsOf(symbols)
        }

        if self << "HALT" {
            doesHalt = true
        }
        else {
            doesHalt = false
        }

        return Actuator(selector:selector,
                        combinedSelector: combined,
                        modifiers:modifiers,
                        traps: traps,
                        notifications: notifications,
                        doesHalt:doesHalt)
    }

    /**
     
     ```
     selector := ( ALL | [ROOT] predicates ) [ON (ALL | predicates)]
     ```
     */
    func selector() throws -> Selector {
        let selector: Selector
        var predicates: [Predicate]

        if self << "ALL" {
            // ALL -> only one predicate
            selector = .All
        }
        else {
            if self << "ROOT" {
                predicates = try self.expect(self.predicateList, "predicates")
                selector = .Root(predicates)
            }
            else {
                predicates = try self.expect(self.predicateList, "predicates")
                selector = .Filter(predicates)
            }
        }

        return selector
    }

    func predicateList() throws -> [Predicate]? {
        return try self.manySeparatedBy(self.predicate, "AND")
    }

    /**
     
     predicate := [IN slot] [NOT] (SET tag_list | FREE slot | ZERO counter)
     */
    func predicate() throws -> Predicate {
        let predicate: Predicate
        var isNegated: Bool
        let inSlot: Symbol?

        // TODO: implement IN slot
        // TODO: implement tag list, no commas so it reads: open jar

        if self << "IN" {
            inSlot = try self <<§ "slot name"
        }
        else {
            inSlot = nil
        }

        isNegated = self << "NOT"

        // Conditions
        if self << "SET" {
            let tags = try self.expect(self.symbolList, "tags to set")

            predicate = Predicate(.TagSet(Set(tags)), isNegated, inSlot: inSlot)
        }
        else if self << "FREE" {
            let slot = try self <<§ "slot name"

            predicate = Predicate(.IsBound(slot), isNegated, inSlot: inSlot)
        }
        else if self << "ZERO" {
            let counter = try self <<§ "counter name"

            predicate = Predicate(.CounterZero(counter), isNegated, inSlot: inSlot)
        }
        else {
            throw self.expectationError("predicate condition: SET, FREE or ZERO")
        }

        return predicate
    }

    /// modifier_list = { modifier }
    func modifiers() throws -> [Modifier] {
        var modifiers = [Modifier]()

        while true {
            if let modifier = try self.modifier() {
                modifiers.append(modifier)
            }
            else {
                break
            }
        }

        if modifiers.isEmpty {
            throw SyntaxError.Syntax("expected at least one modifier")
        }

        return modifiers
    }

    /**
     
     modifier := [IN current] action
     action := NOTHING
                | SET tags
                | UNSET tags
                | BIND slot TO
                | UNBIND slot
                | INC counter
                | DEC counter
                | ZERO counter
     
     */
    public func modifier() throws -> Modifier? {
        let action: ModifierAction
        let target: ModifierTarget

        if self << "IN" {
            // FIXME: this does not look nice
            guard let innerTarget = try self.modifierTarget() else {
                throw self.expectationError("modifier target")
            }
            target = innerTarget
        }
        else {
            target = ModifierTarget(type:.This, slot:nil)
        }
        // Object action

        if self << "NOTHING" {
            action = .Nothing
        }
        else if self << "SET" {
            let tags = try self.expect(symbolList, "tags to set")

            action = .SetTags(Set(tags))
        }
        else if self << "UNSET" {
            let tags = try self.expect(symbolList, "tags to unset")

            action = .UnsetTags(Set(tags))
        }
        else if self << "BIND" {
            let bindTarget: ModifierTarget
            let symbol: Symbol

            symbol = try self <<§ "slot"

            try self.expectKeyword("TO")

            bindTarget = try self.bindTarget()

            action = .Bind(bindTarget, symbol)
        }
        else if self << "UNBIND" {
            let symbol = try self.expectSymbol()

            action = .Unbind(symbol)
        }
        else {
            return nil
        }

        return Modifier(currentRef:target, action:action)
    }

    /** bind_target := slot | modifier_target */
    func bindTarget() throws -> ModifierTarget {
        if let target = try self.modifierTarget() {
            return target
        }
        else {
            let slot = try self <<§ "modifier target or a slot in 'THIS'"
            return ModifierTarget(type: .This, slot: slot)
        }
    }

    /** Parse a current reference: */
    func modifierTarget() throws -> ModifierTarget? {
        var slot: Symbol? = nil

        guard let type = try self.targetType() else {
            return nil
        }

        if self << Token(.Operator, ".") {
            slot = try self.expectSymbol("slot name")
        }

        return ModifierTarget(type:type, slot:slot)
    }

    func targetType() throws -> TargetType? {
        if self << "THIS" {
            return .This
        }
        else if self << "OTHER" {
            return .Other
        }
        else if self << "ROOT" {
            return .Root
        }
        else {
            return nil
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
    func measure() throws -> Measure? {
        let name: Symbol
        let function: AggregateFunction
        let counter: Symbol

        name = try self <<§ "measure name"

        if self << "COUNT" {
            function = AggregateFunction.Count
        }
        else if self << "SUM" {
            counter = try self <<§ "counter name"
            function = AggregateFunction.Sum(counter)
        }
        else if self << "MIN" {
            counter = try self <<§ "counter name"
            function = AggregateFunction.Min(counter)
        }
        else if self << "MAX" {
            counter = try self <<§ "counter name"
            function = AggregateFunction.Max(counter)
        }
        else {
            throw self.expectationError("aggregate function")
        }

        let predicates = try self.expect(predicateList, "predicate list")

        // TODO: we support only aggregate function now
        let measure = Measure(name: name, type:.Aggregate(function, predicates))

        return measure
    }
}

public func <<(parser: Parser, keyword: String) -> Bool {
    return parser.acceptKeyword(keyword)
}

public func <<(parser: Parser, token: Token) -> Bool {
    return parser.accept(token)
}

func <<§(parser: Parser, label: String) throws -> String {
    return try parser.expectSymbol(label)
}

