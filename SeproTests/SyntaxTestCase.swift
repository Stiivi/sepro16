//
//  SyntaxTestCase.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 20/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import XCTest
@testable import SeproLang

class SeproSyntaxTestCase: XCTestCase {
    var grammar: Grammar? = nil
    var ast: AST? = nil
    var error: String! = nil

    override func setUp() {
        self.grammar = makeSeproGrammar()
    }
    func parse(src:String,_ start:String="model") {
        let lexer = SimpleLexer(source: src, keywords: ModelKeywords)
        let parser = Parser(grammar: self.grammar!)

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
        self.parse("")
    }
}