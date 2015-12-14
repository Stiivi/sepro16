//
//  AST.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 12/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public enum AST: CustomStringConvertible, Equatable {
    // Named node
    case ASTNode(String, [AST])
    
    // Leaves
    case ASTNil
    case ASTString(String)
    case ASTInteger(Int)
    case ASTOperator(String)

    public var description: String {
        switch(self) {
        case ASTNil: return "nil"
        case ASTString(let val): return "\"\(val)\""
        case ASTInteger(let val): return String(val)
        case ASTOperator(let val): return String(val)
        case ASTNode(let name, let val):
            let strings = val.map { i in String(i) }
            return "\(name)[" + strings.joinWithSeparator(", ") + "]"
        }
    }
}

public func ==(left: AST, right: AST) -> Bool {
    switch (left, right) {
    case (.ASTNil, .ASTNil):
        return true
    case let (.ASTString(lval), .ASTString(rval)) where lval == rval:
        return true
    case let (.ASTInteger(lval), .ASTInteger(rval)) where lval == rval:
        return true
    case let (.ASTOperator(lval), .ASTOperator(rval)) where lval == rval:
        return true
    case let (.ASTNode(lnam, lval), .ASTNode(rnam, rval)) where lval == rval && lnam == rnam:
        return true
    default:
        return false
    }
}

extension AST: StringLiteralConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = String
    public typealias UnicodeScalarLiteralType = String

    public init(stringLiteral value: StringLiteralType){
        self = .ASTString(value)
    }

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType){
        self = .ASTString(value)
    }

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType){
        self = .ASTString(value)
    }
}

extension AST: IntegerLiteralConvertible {
    public typealias IntegerLiteralType = Int

    public init(integerLiteral value: IntegerLiteralType) {
        self = .ASTInteger(value)
    }
}

extension AST: NilLiteralConvertible {
    public init(nilLiteral: ()) {
        self = .ASTNil
    }
}
