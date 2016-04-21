//
//  ArrayExt.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 13/01/16.
//  Copyright © 2016 Stefan Urbanek. All rights reserved.
//

extension Array {
    /// - Returns: `true` when all elements match `predicate`
    public func all(predicate: (Element) -> Bool) -> Bool {
        return self.index { item in !predicate(item) } == nil
    }

	/// - Returns: first element matching `predicate` or `nil` if no element
	/// matches the predicate.
    public func pick(predicate: (Element) -> Bool) -> Element? {
		for obj in self where predicate(obj) {
			return obj
		}

		return nil
    }
}
