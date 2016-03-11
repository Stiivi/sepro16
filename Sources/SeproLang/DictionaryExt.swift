//
//  DictionaryExt.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 13/01/16.
//  Copyright © 2016 Stefan Urbanek. All rights reserved.
//

extension Dictionary {
    init(items:[(Key, Value)]) {
        self.init()

        for (key, value) in items {
            self[key] = value
        }
    }

	/// Update elements of the receiver with elements
	mutating func update(other: Dictionary) {
		for (key, value) in other { 
			self.updateValue(value, forKey: key) 
		} 
	}

}
