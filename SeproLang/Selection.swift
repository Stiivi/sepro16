//
//  Selection.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 17/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public enum Ordering {
    /// As stored in the store, might differ between requests
    case Natural

    /// Randomized ordering, differs between requests
    case Randomized
}
