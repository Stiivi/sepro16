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
        return self.indexOf { item in !predicate(item) } == nil
    }
}

extension Array {
    public func findFirst(predicate: (Element) -> Bool) -> Element? {
        if let index = self.indexOf(predicate) {
            return self[index]
        }
        else {
            return nil
        }
    }
}
