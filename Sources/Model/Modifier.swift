//
//  Action.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 29/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

// TODO: Merge TrgetType and ModifierTarget into one as:
/*
enum TargetType {
    case this
    case other
    case indirectThis(Symbol)
    case indirectOther(Symbol)

}
*/

public enum TargetType: Int, CustomStringConvertible {
    case this
    case other

    public var description: String {
        switch self {
        case.this: return "THIS"
        case.other: return "OTHER"
        }
    }
}

/** Reference to the *current object* – object that the modifier is
applied to
*/

public struct ModifierTarget: CustomStringConvertible, Equatable {
    public let type: TargetType
    public let slot: Symbol?

    public init(_ type: TargetType,_ slot: Symbol?=nil) {
        self.type = type
        self.slot = slot
    }

    public var description: String {
        if let slot = slot {
            switch self.type {
            case .this: return String(slot)
            default: return "\(type).\(slot)"
            }
        }
        else {
            return String(describing:type)
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
    public let target: ModifierTarget
    public let action: ModifierAction

	public init(target: ModifierTarget, action: ModifierAction) {
		self.target = target
		self.action = action
	}

    public var description: String {
        if self.target.type == TargetType.this && self.target.slot == nil {
            return "\(self.action)"
        }
        else {
            return "IN \(self.target) \(self.action)"
        }
    }
}

/**
  Object modifier.
*/
public enum ModifierAction: CustomStringConvertible, Equatable {
    case nothing
    case setTags(TagList)
    case unsetTags(TagList)
    case inc(Symbol)
    case dec(Symbol)
    case clear(Symbol)
    case bind(Symbol, ModifierTarget)
    case unbind(Symbol)

    public var description: String {
        switch self {
        case .nothing: return "NOTHING"
        case .setTags(let symbols):
                    let str = symbols.joined(separator:", ")
                    return "SET \(str)"
        case .unsetTags(let symbols):
                    let str = symbols.joined(separator:", ")
                    return "UNSET \(str)"
        case .inc(let symbol): return "INC \(symbol)"
        case .dec(let symbol): return "DEC \(symbol)"
        case .clear(let symbol): return "CLEAR \(symbol)"
        case .bind(let symbol, let target): return "BIND \(symbol) TO \(target)"
        case .unbind(let symbol): return "UNBIND \(symbol)"
        }
    }

}

public func ==(left: ModifierAction, right: ModifierAction) -> Bool {
    switch(left, right) {
    case (.nothing, .nothing):
            return true
    case (.setTags(let ltags), .setTags(let rtags)) where ltags == rtags:
            return true
    case (.unsetTags(let ltags), .unsetTags(let rtags)) where ltags == rtags:
            return true
    case (.inc(let lsym), .inc(let rsym)) where lsym == rsym:
            return true
    case (.dec(let lsym), .dec(let rsym)) where lsym == rsym:
            return true
    case (.clear(let lsym), .clear(let rsym)) where lsym == rsym:
            return true
    case (.bind(let lref, let lsym), .bind(let rref, let rsym))
        where lref == rref && lsym == rsym:
            return true
    case (.unbind(let lsym), .unbind(let rsym)) where lsym == rsym:
            return true
    default:
            return false
    }
}
