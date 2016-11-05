//
//  DictionaryExt.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 13/01/16.
//  Copyright © 2016 Stefan Urbanek. All rights reserved.
//

extension Dictionary {
    public init(items:[(Key, Value)]) {
        self.init()

        items.forEach {
            key, value in 
            self[key] = value
        }
    }

	/// Update elements of the receiver with elements
	public mutating func update(from: Dictionary) {
		from.forEach {
            key, value in
			self.updateValue(value, forKey: key) 
		} 
	}
}
