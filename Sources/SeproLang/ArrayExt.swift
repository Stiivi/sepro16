//
//  ArrayExt.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 13/01/16.
//  Copyright © 2016 Stefan Urbanek. All rights reserved.
//

extension Array {
    /**
     - Returns: `true` when all elements match `predicate`
     */
    public func all(predicate: (Element) -> Bool) -> Bool {
        return self.index { item in !predicate(item) } == nil
    }
}

extension Array {
    public func findFirst(predicate: (Element) -> Bool) -> Element? {
        if let index = self.index(where: predicate) {
            return self[index]
        }
        else {
            return nil
        }
    }
}
