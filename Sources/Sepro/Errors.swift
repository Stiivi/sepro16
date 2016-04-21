//
//  Errors.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 20/12/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Foundation

enum SeproError: ErrorProtocol {
    case InternalError(String)
    case NotImplementedError
    case ModelError(String)
}
