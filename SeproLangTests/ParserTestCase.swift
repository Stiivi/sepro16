//
//  TopDownTests.swift
//  TopDownTests
//
//  Created by Stefan Urbanek on 20/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import XCTest
@testable import SeproLang

prefix func §(right: String) -> Token {
    return .Symbol(right)
}


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
        let lexer = SequenceLexer(tokens: tokens)
        let parser = Parser(grammar: self.grammar)!

        var ast: AST? = nil
        var error: String? = nil

        do {
            ast = try parser.parse(lexer, start: start)
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

        self.parse([.IntLiteral(10)], start: "symbol")
        self.assertError("Expected symbol: name")

        self.parse([.Symbol("foo")], start: "symbol")
        self.assertASTNode("symbol", [.ASTString("foo")])

        self.parse([.Keyword("OBJECT")], start: "keyword")
        self.assertASTNode("keyword", [.ASTString("OBJECT")])

        self.parse([.Operator("+")], start: "operator")
        self.assertASTNode("operator", [.ASTOperator("+")])

    }


    func testGroupWithRule() {
        self.grammar["top"] = "TOP" .. ^"bottom"
        self.grammar["bottom"] = "BOTTOM"

        self.parse(["TOP", "BOTTOM"], start: "top")
        self.assertASTNode("top", ["TOP", .ASTNode("bottom", ["BOTTOM"])])

        self.parse(["TOP"], start: "top")
        self.assertError("Expected keyword BOTTOM")
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

    func testOptionalGroup() {
        self.grammar["optional"] = ??("ONE" .. "TWO")

        self.parse([], start: "optional")
        self.assertASTNode("optional", [nil])

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
        self.grammar["optional_suffix"] = "WHERE" .. ??"ALL"

        self.parse([], start: "optional")
        self.assertASTNode("optional", [.ASTNil])

        self.parse(["SOMETHING"], start: "optional")
        self.assertASTNode("optional", [.ASTNil])

        self.parse(["ALL"], start: "optional")
        self.assertASTNode("optional", ["ALL"])

        self.parse(["WHERE"], start: "optional_suffix")
        self.assertASTNode("optional_suffix", ["WHERE", .ASTNil])

        self.parse(["WHERE", "ALL"], start: "optional_suffix")
        self.assertASTNode("optional_suffix", ["WHERE", "ALL"])
    }

    func testSimpleTree() {
        self.grammar["concept"] = "CONCEPT" .. §"name" .. ??(^"member")
        self.grammar["member"] = ("TAG" .. §"name") | ("SLOT" .. §"name")

        self.parse(["TAG", §"t"], start: "member")
        self.assertASTNode("member", ["TAG", "t"])

        self.parse(["SLOT", §"s"], start: "member")
        self.assertASTNode("member", ["SLOT", "s"])

        self.parse(["CONCEPT", §"x"], start: "concept")
        self.assertASTNode("concept", ["CONCEPT", "x", nil])
        // self.assertError("xxx")
    }

    func testRepeat() {
        self.grammar["repeat"] = +"HI"
        self.grammar["lalala"] = "LA" .. +"LA"

        self.parse([], start:"repeat")
        self.assertASTNode("repeat", [])

        self.parse(["HI"], start:"repeat")
        self.assertASTNode("repeat", ["HI"])

        self.parse(["HI", "GOODBYE"], start:"repeat")
        self.assertASTNode("repeat", ["HI"])

        self.parse(["HI", "HI", "GOODBYE"], start:"repeat")
        self.assertASTNode("repeat", ["HI", "HI"])

        self.parse(["LA"], start:"lalala")
        self.assertASTNode("lalala", ["LA"])

        self.parse(["LA", "LA"], start:"lalala")
        self.assertASTNode("lalala", ["LA", "LA"])
    }

    func testMultipleRuleRepeats() {
        self.grammar["concept"] = "CONCEPT" .. §"name" .. +(^"member")
        self.grammar["member"] = ("TAG" .. §"name") | ("SLOT" .. §"name")

        self.parse(["TAG", §"t"], start: "member")
        self.assertASTNode("member", ["TAG", "t"])

        self.parse(["SLOT", §"s"], start: "member")
        self.assertASTNode("member", ["SLOT", "s"])

        self.parse(["CONCEPT", §"x"], start: "concept")
        self.assertASTNode("concept", ["CONCEPT", "x"])

        self.parse(["CONCEPT", §"x", "TAG", §"y"], start: "concept")
        self.assertASTNode("concept", ["CONCEPT", "x",
            .ASTNode("member", ["TAG", "y"])])
    }

    func testSymbolList() {
        self.grammar["list"] = §"symbol" .. +("|" .. §"symbol")

        self.parse([§"a"], start: "list")
        self.assertASTNode("list", ["a"])

        self.parse([§"a", "|", §"b", "|", §"c"], start:"list")
        self.assertASTNode("list", ["a", "|", "b", "|", "c"])

    }

    func testOutput() {
        // self.grammar["list"] = §"symbol" | (§"symbol" .. "|" .. ^"list") => {
        self.grammar["list"] = §"symbol" .. +("|" .. §"symbol") => {
            items in
            print("Items: \(items)")
            let filtered = items.filter {
                item in item.stringValue != "|"
            }
            return AST.ASTNode("trans", filtered)
        }

        self.parse([§"a", "|", §"b", "|", §"c"], start:"list")
        print(self.ast)

        // self.grammar["list"] = §"symbol" .. +("|" .. §"symbol") => {
        //    input in
        //    input.filter()
        //}
    }
}


class LexerTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func lexer(source: String) -> Lexer {
        let operators = ["->", "*", ".", ","]
        let keywords = ["OBJECT", "THIS"]
        return SimpleLexer(source: source, keywords: keywords, operators: operators)
    }

    func testEmpty() {
        var lexer = self.lexer("")
        var token = lexer.nextToken()

        XCTAssertEqual(token, Token.Empty)

        lexer = self.lexer("  ")
        token = lexer.nextToken()

        XCTAssertEqual(token, Token.Empty)
    }

    func testNumber() {
        let lexer = self.lexer("1234")
        let token = lexer.nextToken()

        XCTAssertEqual(token, Token.IntLiteral(1234))
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
        let lexer = self.lexer("1234x")

        let token = lexer.nextToken()
        self.assertError(token, " in number")
    }

    func testOperator() {
        var lexer = self.lexer("*")

        var token = lexer.nextToken()
        XCTAssertEqual(token, Token.Operator("*"))

        lexer = self.lexer("->")
        token = lexer.nextToken()
        XCTAssertEqual(token, Token.Operator("->"))
    }
    func testInvalidArrow() {
        var lexer = self.lexer("-")

        var token = lexer.nextToken()
        self.assertError(token, "Unexpected end")

        lexer = self.lexer("- ")

        token = lexer.nextToken()
        self.assertError(token, "Unexpected character ' '")
    }


    func testKeyword() {
        let lexer = self.lexer("OBJECT")
        let token = lexer.nextToken()

        XCTAssertEqual(token, Token.Keyword("OBJECT"))
    }

    func testKeywordCase() {
        let lexer = self.lexer("oBjEcT")
        let token = lexer.nextToken()

        XCTAssertEqual(token, Token.Keyword("OBJECT"))
    }

    func testSymbol() {
        let lexer = self.lexer("this_is_something")
        let token = lexer.nextToken()

        XCTAssertEqual(token, Token.Symbol("this_is_something"))
    }

    func testMultiple() {
        let lexer = self.lexer("this that 10, 20, 30 ")
        var token = lexer.nextToken()
        
        XCTAssertEqual(token, Token.Keyword("THIS"))
        
        token = lexer.nextToken()
        XCTAssertEqual(token, Token.Symbol("that"))
        
        for val in [10, 20] {
            token = lexer.nextToken()
            XCTAssertEqual(token, Token.IntLiteral(val))
            
            token = lexer.nextToken()
            XCTAssertEqual(token, Token.Operator(","))
        }
        
        token = lexer.nextToken()
        XCTAssertEqual(token, Token.IntLiteral(30))
        
        token = lexer.nextToken()
        XCTAssertEqual(token, Token.Empty)
        
    }
    
}


