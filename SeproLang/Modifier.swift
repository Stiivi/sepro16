//
//  Action.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 29/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

/** Reference to the *current object* – object that the modifier is
applied to
*/

public struct ModifierTarget: CustomStringConvertible, Equatable {
    public let type: TargetType
    public let slot: Symbol?

    init(_ type: TargetType,_ slot: Symbol?=nil) {
        self.type = type
        self.slot = slot
    }

    public var description: String {
        if slot == nil {
            return String(type)
        }
        else {
            return "\(type).\(slot)"
        }
    }
}

public func ==(left: ModifierTarget, right: ModifierTarget) -> Bool {
    return (left.type == right.type) && (left.slot == right.slot)
}

public enum TargetType: Int, CustomStringConvertible {
    case Root
    case This
    case Other

    public var description: String {
        switch self {
        case.Root: return "ROOT"
        case.This: return "THIS"
        case.Other: return "OTHER"
        }
    }
}

/**
Modifiers:

- `INC counter` - increase counter by 1
- `DEC counter` - decrease counter by 1
- `CLEAR counter` - make counter zero
- `SET tag` - sets tag
- `UNSET tag` - unsets tag
- `BIND slot->target` – binds object to slot

*/

public struct Modifier: CustomStringConvertible {
    let target: ModifierTarget
    let action: ModifierAction

    public var description: String {
        return "IN \(self.target) \(self.action)"
    }
}

/**
  Object modifier.
*/
public enum ModifierAction: CustomStringConvertible, Equatable {
    case Nothing
    case SetTags(TagList)
    case UnsetTags(TagList)
    case Inc(Symbol)
    case Dec(Symbol)
    case Clear(Symbol)
    case Bind(ModifierTarget, Symbol)
    case Unbind(Symbol)

    public var description: String {
        switch self {
        case .Nothing: return "NOTHING"
        case .SetTags(let symbols):
                    let str = symbols.joinWithSeparator(", ")
                    return "SET \(str)"
        case .UnsetTags(let symbols):
                    let str = symbols.joinWithSeparator(", ")
                    return "UNSET \(str)"
        case .Inc(let symbol): return "INC \(symbol)"
        case .Dec(let symbol): return "DEC \(symbol)"
        case .Clear(let symbol): return "CLEAR \(symbol)"
        case .Bind(let ref, let symbol): return "BIND \(ref).\(symbol)"
        case .Unbind(let symbol): return "UNBIND \(symbol)"
        }
    }
}

public func ==(left: ModifierAction, right: ModifierAction) -> Bool {
    switch(left, right) {
    case (.Nothing, .Nothing):
            return true
    case (.SetTags(let ltags), .SetTags(let rtags)) where ltags == rtags:
            return true
    case (.UnsetTags(let ltags), .UnsetTags(let rtags)) where ltags == rtags:
            return true
    case (.Inc(let lsym), .Inc(let rsym)) where lsym == rsym:
            return true
    case (.Dec(let lsym), .Dec(let rsym)) where lsym == rsym:
            return true
    case (.Clear(let lsym), .Clear(let rsym)) where lsym == rsym:
            return true
    case (.Bind(let lref, let lsym), .Bind(let rref, let rsym))
        where lref == rref && lsym == rsym:
            return true
    case (.Unbind(let lsym), .Unbind(let rsym)) where lsym == rsym:
            return true
    default:
            return false
    }
}
