//
//  ParserTestCase.swift
//  AgentFarms
//
//  Created by Stefan Urbanek on 14/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

@testable import SeproLang
import XCTest

class LexerTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEmpty() {
        var lexer = Lexer(source: "")
        var token = lexer.next()

        XCTAssertEqual(token, Token.End)

        lexer = Lexer(source: "  ")
        token = lexer.next()

        XCTAssertEqual(token, Token.End)
    }

    func testNumber() {
        let lexer = Lexer(source: "1234")
        let token = lexer.next()

        XCTAssertEqual(token, Token.Integer(1234))
    }

    func assertError(token: Token, _ str: String) {
        switch token {
        case .Error(let val) where val.containsString(str):
            break
        default:
            XCTFail("Token \(token) is not an error containing '\(str)'")
        }
    }

    func testInvalidNumber() {
        let lexer = Lexer(source: "1234x")

        let token = lexer.next()
        self.assertError(token, " in number")
    }

    func testInvalidArrow() {
        var lexer = Lexer(source: "-")

        var token = lexer.next()
        self.assertError(token, "Did you mean '->'")

        lexer = Lexer(source: "- ")

        token = lexer.next()
        self.assertError(token, "Did you mean '->'")
    }


    func testKeyword() {
        let lexer = Lexer(source: "CONCEPT")
        let token = lexer.next()

        XCTAssertEqual(token, Token.Keyword("CONCEPT"))
    }

    func testKeywordCase() {
        let lexer = Lexer(source: "cOnCePt")
        let token = lexer.next()

        XCTAssertEqual(token, Token.Keyword("CONCEPT"))
    }

    func testSymbol() {
        let lexer = Lexer(source: "this_is_something")
        let token = lexer.next()

        XCTAssertEqual(token, Token.Symbol("this_is_something"))
    }

    func testMultiple() {
        let lexer = Lexer(source: "this that 10, 20, 30 ")
        var token = lexer.next()

        XCTAssertEqual(token, Token.Keyword("THIS"))

        token = lexer.next()
        XCTAssertEqual(token, Token.Symbol("that"))

        for val in [10, 20] {
            token = lexer.next()
            XCTAssertEqual(token, Token.Integer(val))

            token = lexer.next()
            XCTAssertEqual(token, Token.Comma)
        }

        token = lexer.next()
        XCTAssertEqual(token, Token.Integer(30))

        token = lexer.next()
        XCTAssertEqual(token, Token.End)

    }
}

class CompilerTestase: XCTestCase {
    func compile(source:String) -> Model{
        let parser = Parser(source: source)
        if let model = parser.compile() {
            return model
        }
        else {
            XCTFail("Compile failed. Reason: \(parser.error!)")
        }
        return Model()
    }

    func compileError(source:String) -> String?{
        let parser = Parser(source: source)
        parser.compile()
        return parser.error
    }

    func assertError(source:String, _ match:String) {
        let error:String = self.compileError(source)!

        if error.rangeOfString(match) == nil {
            XCTFail("Error: \"\(error)\" does not match: '\(match)'")
        }
    }

    func testEmpty() {
        let model = self.compile("")
        XCTAssertEqual(model.concepts.count, 0)
    }
    func testError() {
        var error: String?

        error = self.compileError("thisisbad")
        XCTAssertNotNil(error)

        error = self.compileError("CONCEPT")
        XCTAssertNotNil(error)

    }

    func testAccept() {
        var parser = Parser(source: "")

        XCTAssertTrue(parser.accept(.End))

        parser = Parser(source: "CONCEPT something")
        XCTAssertFalse(parser.accept(.End))

        XCTAssertTrue(parser.accept(.Keyword("CONCEPT")))
        XCTAssertFalse(parser.accept(.Keyword("CONCEPT")))
        XCTAssertFalse(parser.accept(.End))

        XCTAssertTrue(parser.accept(.Symbol("something")))
        XCTAssertFalse(parser.accept(.Symbol("something")))

        // The same with helper methods
        parser = Parser(source: "CONCEPT something")
        XCTAssertFalse(parser.accept(.End))

        XCTAssertTrue(parser.acceptKeyword("CONCEPT"))
    }

    func assertError(error: String, block: () throws -> Void) {
        do {
            try block()
            XCTFail("Exception with error '\(error)' not raised")
        }
        catch SyntaxError.Syntax(let message) {
            if !message.containsString(error) {
                XCTFail("Thrown error does not contain '\(error)'. Got '\(message)'")
            }
        }
        catch {
            XCTFail("Unexpected error catched")
        }

    }
    func testExpect() {
        var parser = Parser(source:"")

        self.assertError("got end") {
            try parser.expect(.Symbol("nothing"))
        }

        parser = Parser(source:"concept foo")
        self.assertError("Expected symbol") {
            try parser.expect(.Symbol("concept"))
        }

    }

    func testExpectMultiple() {
        let parser: Parser

        parser = Parser(source:"concept foo")
        do {
            let result = try parser.expectKeyword("CONCEPT")
            XCTAssertTrue(result)
        }
        catch {
            XCTFail()
        }
        do {
            let result = try parser.expectSymbol()
            XCTAssertEqual(result, "foo")
        }
        catch SyntaxError.Syntax(let message) {
            XCTFail("Symbol expectation failed: \(message)")
        }
        catch {
            XCTFail()
        }
    }

    func testSymbolList() {
        var parser = Parser(source: "one")
        var symbols: [Symbol]

        do {
            symbols = try parser.parseSymbolList()
            XCTAssertEqual(symbols, ["one"])
        }
        catch {
            XCTFail("Can't parse symbol list")
        }

        parser = Parser(source: "one, two, three")

        do {
            symbols = try parser.parseSymbolList()
            XCTAssertEqual(symbols, ["one", "two", "three"])
        }
        catch {
            XCTFail("Can't parse symbol list")
        }

    }

    func testNothingInstruction() {
        var parser: Parser

        parser = Parser(source:"NOTHING")
        if let instruction = parser.parseInstruction() {
            XCTAssertEqual(instruction, Instruction.Nothing)
        }
        else {
            XCTFail("Can't parse instruction")
        }
    }

    func testSystemInstructions() {
        var parser: Parser

        parser = Parser(source:"TRAP")
        if parser.parseInstruction() != nil {
            XCTFail("Trap should contain a symbol")
        }
        else {
            XCTAssertTrue(parser.error!.containsString("Expected trap name"))
        }

        parser = Parser(source:"TRAP itsatrap")
        if let instruction = parser.parseInstruction() {
            XCTAssertEqual(instruction, Instruction.Trap("itsatrap"))
        }
        else {
            XCTAssertTrue(parser.error!.containsString("ex"))
        }
    }
    func testConcept() {
        var model: Model

        model = self.compile("CONCEPT some")
        XCTAssertEqual(model.concepts.count, 1)

        model = self.compile("CONCEPT one CONCEPT two\nCONCEPT three")
        XCTAssertEqual(model.concepts.count, 3)

        self.assertError("CONCEPT CONCEPT", "concept name")
        self.assertError("CONCEPT one two", "two")

    }

    func testConceptTags() {
        var model: Model
        var concept: Concept

        model = self.compile("CONCEPT test TAG left, right")
        concept = model.getConcept("test")!
        XCTAssertEqual(concept.tags.count, 2)
    }

    func testConceptSlots() {
        var model: Model
        var concept: Concept

        model = self.compile("CONCEPT test SLOT left, right")
        concept = model.getConcept("test")!
        XCTAssertEqual(concept.slots.count, 2)
    }

    func testAlwaysActuator() {
        var model: Model

        model = self.compile("WHERE ALL DO NOTHING")

        XCTAssertEqual(model.actuators.count, 1)

        let actuator = model.actuators[0]

        XCTAssertEqual(actuator.predicates.count, 1)
        XCTAssertEqual(actuator.instructions.count, 1)
    }

    /// Compile a model containing only one actuator
    func compileActuator(source:String) -> Actuator {
        var model: Model
        model = self.compile(source)
        
        if model.actuators.isEmpty {
            XCTFail("Actuator list is empty")
        }

        return model.actuators[0]
    }

    // MARK: Conditions

    func testTagConditions() {
        var actuator: Actuator
        var predicate: Predicate

        actuator = self.compileActuator("WHERE test DO NOTHING")

        XCTAssertEqual(actuator.predicates.count, 1)
        predicate = actuator.predicates.first!

        XCTAssertEqual(predicate.isNegated, false)
        XCTAssertEqual(predicate.type, PredicateType.TagSet(["test"]))

        actuator = self.compileActuator("WHERE NOT notest DO NOTHING")
        predicate = actuator.predicates.first!
        XCTAssertEqual(predicate.isNegated, true)
        XCTAssertEqual(predicate.type, PredicateType.TagSet(["notest"]))

        // TODO: this should be one
        let model = self.compile("WHERE open AND left DO NOTHING")
        XCTAssertEqual(model.actuators.count, 1)
        XCTAssertEqual(model.actuators[0].predicates.count, 2)

        actuator = self.compileActuator("WHERE open AND NOT left DO NOTHING")
        predicate = actuator.predicates.first!
        XCTAssertEqual(predicate.isNegated, false)
        XCTAssertEqual(predicate.type, PredicateType.TagSet(["open"]))
    }
//    func testContextCondition(){
//        var actuator: Actuator
//        actuator = self.compileActuator("WHERE ROOT ready DO NOTHING")
//        XCTAssertTrue(actuator.isRoot)
//
//        let cond = actuator.conditions[0] as! TagSetPredicate
//        XCTAssertEqual(cond.tags, ["ready"])
//    }
//    func testInteractiveCondition(){
//        var left: Predicate
//        var right: Predicate
//
//        var actuator = self.compileActuator("WHERE left ON ANY DO NOTHING")
//        left = actuator.conditions[0] as! TagSetPredicate
//        XCTAssertEqual(left.tags, ["left"])
//
//        XCTAssertEqual(actuator.otherConditions!.count, 1)
//
//        actuator = self.compileActuator("WHERE left ON right AND test DO NOTHING")
//
//        right = actuator.otherConditions![0] as! TagSetPredicate
//        XCTAssertEqual(right.tags, ["right"])
//
//        right = actuator.otherConditions![1] as! TagSetPredicate
//        XCTAssertEqual(right.tags, ["test"])
//    }
//
//    // MARK: Actions
//
//    func testTagAction() {
//        var actuator: Actuator
//        var action: TagsAction
//
//        actuator = self.compileActuator("WHERE ALL DO SET test")
//
//        XCTAssertEqual(actuator.actions.count, 1)
//        action = actuator.actions[0] as! TagsAction
//        XCTAssertEqual(action.tags, ["test"])
//
//
//        actuator = self.compileActuator("WHERE ALL DO SET one, two")
//        XCTAssertEqual(actuator.actions.count, 1)
//        action = actuator.actions[0] as! TagsAction
//        XCTAssertEqual(action.tags, ["one", "two"])
//
//        actuator = self.compileActuator("WHERE ALL DO SET one UNSET two")
//
//        action = actuator.actions[0] as! TagsAction
//        XCTAssertEqual(action.tags, ["one"])
//        action = actuator.actions[1] as! TagsAction
//        XCTAssertEqual(action.tags, ["two"])
//    }
//    func testContextAction() {
//        var actuator: Actuator
//        var action: TagsAction
//
//        actuator = self.compileActuator("WHERE ALL DO IN this SET test")
//        action = actuator.actions[0] as! TagsAction
//
//        XCTAssertEqual(action.inContext, ObjectContextType.This)
//        XCTAssertEqual(action.inSlot, nil)
//
//        actuator = self.compileActuator("WHERE ALL DO IN root SET test")
//        action = actuator.actions[0] as! TagsAction
//
//        XCTAssertEqual(action.inContext, ObjectContextType.Root)
//
//        actuator = self.compileActuator("WHERE ALL DO IN other.link SET test")
//        action = actuator.actions[0] as! TagsAction
//
//        XCTAssertEqual(action.inContext, ObjectContextType.Other)
//        XCTAssertEqual(action.inSlot, "link")
//
//    }
//    func testBindAction() {
//        var actuator: Actuator
//        var action: BindAction
//
//        actuator = self.compileActuator("WHERE ALL DO BIND link TO this")
//        action = actuator.actions[0] as! BindAction
//        XCTAssertEqual(action.targetContext, ObjectContextType.This)
//        XCTAssertNil(action.targetSlot)
//
//        actuator = self.compileActuator("WHERE ALL DO BIND link TO backlink")
//        action = actuator.actions[0] as! BindAction
//        XCTAssertEqual(action.targetContext, ObjectContextType.This)
//        XCTAssertEqual(action.targetSlot, "backlink")
//
//        actuator = self.compileActuator("WHERE ALL DO BIND link TO root.some")
//        action = actuator.actions[0] as! BindAction
//        XCTAssertEqual(action.targetContext, ObjectContextType.Root)
//        XCTAssertEqual(action.targetSlot, "some")
//
//        actuator = self.compileActuator("WHERE ALL DO IN root BIND link TO some")
//        action = actuator.actions[0] as! BindAction
//        XCTAssertEqual(action.targetContext, ObjectContextType.Root)
//        XCTAssertEqual(action.targetSlot, "some")
//    }
//
//    func testWorld() {
//        var model: Model
//
//        model = self.compile("WORLD main OBJECT atom")
//        model = self.compile("WORLD main OBJECT atom AS link")
//        model = self.compile("WORLD main ROOT global OBJECT atom AS o1, atom AS o2")
//        model = self.compile("WORLD main OBJECT atom AS o1, atom AS o2")
//        model = self.compile("WORLD main BIND left.next TO right, right.previous TO left")
//
//        // TODO: fail this
//        // model = self.compile("WORLD main OBJECT atom, atom ")
//    }

}
