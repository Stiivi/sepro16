//
//  ArrayExt.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 13/01/16.
//  Copyright © 2016 Stefan Urbanek. All rights reserved.
//

extension Array {
    /// - Returns: `true` when all elements match `predicate`
    public func all(_ predicate: (Element) -> Bool) -> Bool {
        return self.index { item in !predicate(item) } == nil
    }
}

