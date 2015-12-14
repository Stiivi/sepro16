//
//  TopDownParserTests.swift
//  TopDownParserTests
//
//  Created by Stefan Urbanek on 12/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import XCTest
@testable import TopDownParser


class TopDownParserTests: XCTestCase {

    var grammar = Grammar()
    var ast: AST! = nil
    var error: String! = nil
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func assertError(match:String) {
        if self.error == nil {
            XCTFail("No error. Expected error matching: \(match)")
        }
        else if self.error.rangeOfString(match) == nil {
            XCTFail("Expected error matching '\(match)' got: \(error)")
        }
    }

    func assertASTNode(expectName: String, _ expectChildren: [AST]) {
        if self.ast == nil {
            XCTFail("Expected ast node \(name). No node exists.")
            return
        }
        if case let AST.ASTNode(name, children) = self.ast! {
            XCTAssertEqual(name, expectName)
            XCTAssertEqual(children, expectChildren)
        }
        else {
            XCTFail("Expected ast node \(name), got \(self.ast)")
        }
    }

    func parse(tokens:[Token], start:String) {
        let lexer = DummyLexer(tokens: tokens)
        let parser = Parser(grammar: self.grammar)

        var ast: AST? = nil
        var error: String? = nil

        do {
            ast = try parser.parse(lexer, rule: start)
        }
        catch SyntaxError.Syntax(let message)
        {
            error = message
        }
        catch {
            // TODO: error = unknown error
            // Do nothing
        }

        self.ast = ast
        self.error = error

    }

    func testEmpty() {
        self.grammar["empty"] = .Empty

        self.parse([], start: "empty")
        XCTAssertEqual(ast, AST.ASTNode("empty", []))

        self.parse(["something"], start: "empty")
        XCTAssertNil(ast)
        self.assertError("Expected end")

    }

    func testTerminals() {
        self.grammar["symbol"] = §"name"
        self.grammar["integer"] = %"value"
        self.grammar["keyword"] = "OBJECT"
        self.grammar["operator"] = .Terminal(.Operator("+"))

        self.parse([], start: "symbol")
        self.assertError("Expected symbol: name")

        self.parse([.Integer(10)], start: "symbol")
        self.assertError("Expected symbol: name")

        self.parse([.Symbol("foo")], start: "symbol")
        self.assertASTNode("symbol", [.ASTString("foo")])

        self.parse([.Keyword("OBJECT")], start: "keyword")
        self.assertASTNode("keyword", [.ASTString("OBJECT")])

        self.parse([.Operator("+")], start: "operator")
        self.assertASTNode("operator", [.ASTOperator("+")])

    }

    func testGroup() {
        self.grammar["concept"] = "CONCEPT" .. §"name"
        self.grammar["concept_final"] = "CONCEPT" .. §"name" .. nil

        self.parse(["OBJECT"], start: "concept")
        self.assertError("Expected keyword CONCEPT")

        self.parse(["CONCEPT", "OBJECT"], start: "concept")
        self.assertError("Expected symbol")

        self.parse(["CONCEPT", §"x"], start: "concept")
        XCTAssertNotNil(ast)
        self.assertASTNode("concept", ["CONCEPT", "x"])

        self.parse(["CONCEPT", §"x", §"y"], start: "concept_final")
        self.assertError("Expected end")

        self.parse(["CONCEPT", §"x"], start: "concept_final")
        self.assertASTNode("concept_final", ["CONCEPT", "x"])
    }

    func testError() {
        self.grammar["error"] = .Error("Serious error")

        self.parse([], start: "error")
        self.assertError("Serious error")

        self.parse(["one", "two"], start: "error")
        self.assertError("Serious error")

    }

    func testAlternate() {
        self.grammar["choice"] = "ONE" | "TWO" | "THREE"
        self.grammar["side"] = "LEFT" | "RIGHT" | .Error("Expected side")

        self.parse(["INVALID"], start: "choice")
        self.assertError("got: INVALID")

        self.parse(["INVALID"], start: "side")
        self.assertError("Expected side")

        self.parse(["ONE"], start: "choice")
        self.assertASTNode("choice", ["ONE"])

        self.parse(["TWO"], start: "choice")
        self.assertASTNode("choice", ["TWO"])

        self.parse(["THREE"], start: "choice")
        self.assertASTNode("choice", ["THREE"])
    }

    func testRule() {
        self.grammar["outer"] = ^"inner"
        self.grammar["inner"] = "WORD"

        self.parse(["WORD"], start: "outer")
        self.assertASTNode("outer", [.ASTNode("inner", ["WORD"])])
    }

    func testOptional() {
        self.grammar["optional"] = ??"ALL"

        self.parse([], start: "optional")
        self.assertASTNode("optional", [.ASTNil])

        self.parse(["SOMETHING"], start: "optional")
        self.assertASTNode("optional", [.ASTNil])

        self.parse(["ALL"], start: "optional")
        self.assertASTNode("optional", ["ALL"])
    }

    func testSimpleTree() {
        self.grammar["concept"] = "CONCEPT" .. §"name" .. ^"member"
        self.grammar["member"] = ("TAG" .. "name") | ("SLOT" .. "name")

        self.parse(["CONCEPT", §"x"], start: "concept")
        self.assertError("xxx")
    }
}
