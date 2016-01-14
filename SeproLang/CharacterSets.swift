//
//  CharacterSets.swift
//  MetaParser
//
//  Created by Stefan Urbanek on 14/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Foundation

public struct CharacterSet: Hashable {
    let characterSet: NSCharacterSet

    public init(_ sets: NSCharacterSet...) {
        let combined = NSMutableCharacterSet()
        for set in sets {
            combined.formUnionWithCharacterSet(set)
        }
        self.characterSet = combined
    }

    public init(string: String) {
        self.init(NSCharacterSet(charactersInString: string))
    }

    public func matches(c: Character) -> Bool {
        let utf = String(c).utf16
        return self.characterSet.characterIsMember(utf.first!)
    }

    public func union(set: CharacterSet) -> CharacterSet {
        return CharacterSet(self.characterSet, set.characterSet)
    }

    /// Form an union with characters from string `str`
    public func union(str: String) -> CharacterSet {
        return CharacterSet(self.characterSet, NSCharacterSet(charactersInString: str))
    }

    /// - Returns: `true` if the other character set has common characters with
    /// the receiver
    public func intersectsWith(other: CharacterSet) -> Bool {
        let set = NSMutableCharacterSet()
        set.formUnionWithCharacterSet(self.characterSet)
        set.formIntersectionWithCharacterSet(other.characterSet)
        return !set.isEqual(NSCharacterSet())
    }

    /// - Returns: a set with characters as the receiver minus characters in the
    /// string `str`
    public func subtract(str: String) -> CharacterSet {
        let set = NSMutableCharacterSet(charactersInString: str)
        set.removeCharactersInString(str)
        return CharacterSet(set)
    }

    public var hashValue: Int {
        return self.characterSet.hashValue
    }

}

public func ==(left: CharacterSet, right:CharacterSet) -> Bool {
    return left.characterSet.isEqual(right.characterSet)
}

public func ~=(left:CharacterSet, right: Character) -> Bool {
    return left.matches(right)
}


let WhitespaceCharacterSet = CharacterSet(NSCharacterSet.whitespaceCharacterSet())
                                | CharacterSet(NSCharacterSet.newlineCharacterSet())
let NewLineCharacterSet = CharacterSet(NSCharacterSet.newlineCharacterSet())
let DecimalDigitCharacterSet = CharacterSet(NSCharacterSet.decimalDigitCharacterSet())
let LetterCharacterSet = CharacterSet(NSCharacterSet.letterCharacterSet())
let SymbolCharacterSet = CharacterSet(NSCharacterSet.symbolCharacterSet())
let AlphanumericCharacterSet = CharacterSet(NSCharacterSet.alphanumericCharacterSet())

func |(left: CharacterSet, right: CharacterSet) -> CharacterSet {
    return left.union(right)
}

func |(left: CharacterSet, right: String) -> CharacterSet {
    return left.union(right)
}

func -(left: CharacterSet, right: String) -> CharacterSet {
    return left.subtract(right)
}
