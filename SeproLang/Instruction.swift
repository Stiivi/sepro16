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

public struct CurrentRef: CustomStringConvertible, Equatable {
    public let type: CurrentType
    public let slot: Symbol?

    public var description: String {
        if slot == nil {
            return String(type)
        }
        else {
            return "\(type).\(slot)"
        }
    }
}

public func ==(left: CurrentRef, right: CurrentRef) -> Bool {
    return (left.type == right.type) && (left.slot == right.slot)
}

public enum CurrentType: Int, CustomStringConvertible {
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
Instruction represents a command to the engine. There are two groups of
instructions: *system instructions* – have no influence on
the actual state of the simulation, *modifiers* – modify object state.

System instructions:

- `NOP` - no action, just a placeholder
- `HALT` – stop simulation
- `TRAP` – require observer's interaction
- `NOTIFY channel[, data]` - notify channel that an event occured

Modifiers:

- `INC counter` - increase counter by 1
- `DEC counter` - decrease counter by 1
- `CLEAR counter` - make counter zero
- `SET tag` - sets tag
- `UNSET tag` - unsets tag
- `BIND slot->target` – binds object to slot


*/

public enum Instruction: CustomStringConvertible, Equatable {
    /// Special place-holder without any effect
    case Nothing

    /** Stop the computation. This instruction should be used when there
     is no point to continue the simulation, either because an
     expected or invalid state was reached.
     
    Computation can not continue unless the halt flag is cleared.
     */
    case Halt

    /// Interrupt the computation and handle the trap externally.
    case Trap(Symbol)

    /** Passes a notification symbol to the logger without interrupting
     the computation.
     */
    case Notify(Symbol)

    /** Modifies a state of an object */
    case Modify(CurrentRef, Modifier)

    public var description: String {
        switch self {
        case .Nothing: return "NOTHING"
        case .Halt: return "HALT"
        case .Trap(let symbol): return "TRAP \(symbol)"
        case .Notify(let symbol): return "NOTIFY \(symbol)"
        case .Modify(let ref, let modifier): return "\(ref) \(modifier.description)"
        }
    }

}

public func ==(left: Instruction, right: Instruction) -> Bool {
    switch (left, right) {
    case (.Nothing, .Nothing): return true
    case (.Halt, .Halt): return true
    case (.Trap(let a), .Trap(let b)) where a == b: return true
    case (.Notify(let a), .Notify(let b)) where a == b: return true
    case (.Modify(let lref, let lmod), .Modify(let rref, let rmod))
            where lref == rref && lmod == rmod: return true
    default: return false
    }
}


// Note: We are leaning towards a single (or a very few) "modifier"
// instructions, therefore we are logically wrapping it under one
// enumeration
//
/**
  Object modifier.
*/
public enum Modifier: CustomStringConvertible, Equatable {
    // Object modifiers
    case SetTags(TagList)
    case UnsetTags(TagList)
    case Inc(Symbol)
    case Dec(Symbol)
    case Clear(Symbol)
    case Bind(CurrentRef, Symbol)
    case Unbind(Symbol)

    public var description: String {
        switch self {
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

public func ==(left: Modifier, right: Modifier) -> Bool {
    switch(left, right) {
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