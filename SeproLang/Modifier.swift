//
//  Action.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 29/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

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

    /// - Returns: A tuple of symbols (`this`, `other`, `root`)
    public var slotMatrix: ([Symbol], [Symbol], [Symbol]) {
        switch (self.type, self.slot) {
        case (_, nil):
            return ([], [], [])
        case (.This, let targetSlot):
            return ([targetSlot!], [], [])
        case (.Other, let targetSlot):
            return ([], [targetSlot!], [])
        case (.Root, let targetSlot):
            return ([], [], [targetSlot!])
        }
    }

    public var description: String {
        if slot == nil {
            return String(type)
        }
        else {
            switch self.type {
            case .This: return String(slot!)
            default: return "\(type).\(slot)"
            }
        }
    }
}

public func ==(left: ModifierTarget, right: ModifierTarget) -> Bool {
    return (left.type == right.type) && (left.slot == right.slot)
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
        if self.target.type == TargetType.This && self.target.slot == nil {
            return "\(self.action)"
        }
        else {
            return "IN \(self.target) \(self.action)"
        }
    }


    /// - Returns: A tuple of symbols (`this`, `other`, `root`)
    public var slotMatrix: ([Symbol], [Symbol], [Symbol]) {
        let ts = target.slotMatrix

        switch self.action {
        case .Bind(let slot, let bindTarget):
            let bs = bindTarget.slotMatrix
            switch target.type {
            case .This:  return (ts.0 + bs.0 + [slot], ts.1 + bs.1, ts.2 + bs.2)
            case .Other: return (ts.0 + bs.0, ts.1 + bs.1 + [slot], ts.2 + bs.2)
            case .Root:  return (ts.0 + bs.0, ts.1 + bs.1, ts.2 + bs.2 + [slot])
            }
        case .Unbind(let slot):
            switch target.type {
            case .This:  return (ts.0 + [slot], ts.1, ts.2)
            case .Other: return (ts.0, ts.1 + [slot], ts.2)
            case .Root:  return (ts.0, ts.1, ts.2 + [slot])
            }
        default: return ([], [], [])
        }
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
    case Bind(Symbol, ModifierTarget)
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
        case .Bind(let symbol, let target): return "BIND \(symbol) TO \(target)"
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
