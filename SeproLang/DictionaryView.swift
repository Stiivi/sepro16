//
//  DictionaryView.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 13/01/16.
//  Copyright © 2016 Stefan Urbanek. All rights reserved.
//

extension Array {
    typealias Value = Generator.Element

    func dictionaryView<K: Hashable>(keyGetter: (Value) -> K) -> [K:Value] {
        let items = self.map {
            obj in
            (keyGetter(obj), obj)
        }

        return Dictionary(items: items)
    }
}