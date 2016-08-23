//
//  CharacterSets.swift
//  MetaParser
//
//  Created by Stefan Urbanek on 14/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Foundation

public func ~=(left:CharacterSet, right: UnicodeScalar) -> Bool {
    return left.contains(right)
}


let WhitespaceCharacterSet = CharacterSet.whitespaces | CharacterSet.newlines
let NewLineCharacterSet = CharacterSet.newlines
let DecimalDigitCharacterSet = CharacterSet.decimalDigits
let LetterCharacterSet = CharacterSet.letters
let SymbolCharacterSet = CharacterSet.symbols
let AlphanumericCharacterSet = CharacterSet.alphanumerics

func |(left: CharacterSet, right: CharacterSet) -> CharacterSet {
    return left.union(right)
}

func |(left: CharacterSet, right: String) -> CharacterSet {
    return left.union(CharacterSet(charactersIn:right))
}

func -(left: CharacterSet, right: String) -> CharacterSet {
    return left.subtracting(CharacterSet(charactersIn: right))
}
