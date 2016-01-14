//
//  TopDownTests.swift
//  TopDownTests
//
//  Created by Stefan Urbanek on 20/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import XCTest
@testable import SeproLang

class ParserTestCase: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEmpty() {
        let parser = Parser("")
        if let model = try? parser.model() {
            XCTAssertEqual(model!.concepts.count, 0)
        }
    }

    func testConcept() {
        var parser = Parser("CONCEPT x")
        if let concept = try? parser.concept() {
            XCTAssertEqual(concept!.name, "x")
        }

        parser = Parser("CONCEPT y TAG a, b, c")
        if let concept = try? parser.concept() {
            XCTAssertEqual(concept!.name, "y")
            XCTAssertEqual(concept!.tags, ["a", "b", "c"])
        }
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
        let keywords = ["OBJECT", "THIS"]
        return Lexer(source: source, keywords: keywords)
    }

    func testEmpty() {
        var lexer = self.lexer("")
        var token = lexer.nextToken()

        XCTAssertEqual(token.kind, TokenKind.Empty)

        lexer = self.lexer("  ")
        token = lexer.nextToken()

        XCTAssertEqual(token.kind, TokenKind.Empty)
    }

    func testNumber() {
        let lexer = self.lexer("1234")
        let token = lexer.nextToken()

        XCTAssertEqual(token, Token(.IntLiteral, "1234"))
    }

    func assertError(token: Token, _ str: String) {
        switch token.kind {
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
        XCTAssertEqual(token, Token(.Operator, "*"))

        lexer = self.lexer("=")
        token = lexer.nextToken()
        XCTAssertEqual(token, Token(.Operator, "="))
    }

    func testKeyword() {
        let lexer = self.lexer("OBJECT")
        let token = lexer.nextToken()

        XCTAssertEqual(token, Token(.Keyword, "OBJECT"))
    }

    func testKeywordCase() {
        let lexer = self.lexer("oBjEcT")
        let token = lexer.nextToken()

        XCTAssertEqual(token, Token(.Keyword, "OBJECT"))
    }

    func testSymbol() {
        let lexer = self.lexer("this_is_something")
        let token = lexer.nextToken()

        XCTAssertEqual(token, Token(.Identifier, "this_is_something"))
    }

    func testMultiple() {
        let lexer = self.lexer("this that 10, 20, 30 ")
        var token = lexer.nextToken()
        
        XCTAssertEqual(token, Token(.Keyword, "THIS"))
        
        token = lexer.nextToken()
        XCTAssertEqual(token, Token(.Identifier, "that"))
        
        for val in ["10", "20"] {
            token = lexer.nextToken()
            XCTAssertEqual(token, Token(.IntLiteral, val))
            
            token = lexer.nextToken()
            XCTAssertEqual(token, Token(.Operator, ","))
        }
        
        token = lexer.nextToken()
        XCTAssertEqual(token, Token(.IntLiteral, "30"))
        
        token = lexer.nextToken()
        XCTAssertEqual(token, Token(.Empty, ""))
        
    }
    
}


