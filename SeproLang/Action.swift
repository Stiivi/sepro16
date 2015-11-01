//
//  Action.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 29/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

/**
    Action is an atomic operation of the actuator kernel. Actions have side
    effects and modify the simulation state.

    Object actions:

    - `INC counter` - increase counter by 1
    - `DEC counter` - decrease counter by 1
    - `SET counter` - sets tag
    - `UNSET tag` - unsets tag
    - `BIND slot->target` – binds object to slot

    Object actions are executed in an object context.

    System actions

    - `NOP` - no action, just a placeholder
    - `HALT` – stop simulation
    - `TRAP` – require observer's interaction
    - `NOTIFY channel[, data]` - notify channel that an event occured
*/

public enum ActionType: Int, CustomStringConvertible {
    // Special place-holder action without any effect
    case NoAction = 0

    // System control actions
    case Halt, Trap, Notify

    // Object actions
    case SetTag, UnsetTag
    case Inc, Dec, Zero
    case Bind, Unbind

    public var description: String {
        switch self {
        case.NoAction: return "NOTHING"
        case.Halt: return "HALT"
        case.Trap: return "TRAP"
        case.Notify: return "NOTIFY"
        case.SetTag: return "SET"
        case.UnsetTag: return "UNSET"
        case.Inc: return "INC"
        case.Dec: return "DEC"
        case.Zero: return "ZERO"
        case.Bind: return "BIND"
        case.Unbind: return "UNBIND"
        }
    }
}


/** Empty action */
public class Action {
}

public class NoAction: Action { }

// MARK: System and Control Actions

/// Register a notification
public class NotifyAction:Action {
    public var symbol: Symbol?

    public init(symbol: String?=nil) {
        self.symbol = symbol
    }
}

/// Stop the simulation
public class HaltAction:Action { }

/// Interrupt the simulation with an external action
public class TrapAction:Action {
    public var type: Symbol?

    public init(type: Symbol?) {
        self.type = type
    }
}

public enum ObjectContextType: Int, CustomStringConvertible {
    case Root = 0, This, Other

    public var description: String {
        switch self {
        case.Root: return "root"
        case.This: return "this"
        case.Other: return "other"
        }
    }
}

/**

    Actions on object's properties.

        IN $CONTEXT[.$SLOT]

        SET tags
        UNSET tags
        INC counter
        DEC counter
        ZERO counter

*/
public class ObjectAction: Action {
    public let inContext: ObjectContextType
    public let inSlot: Symbol?

    init(inContext:ObjectContextType, inSlot: Symbol?) {
        self.inContext = inContext
        self.inSlot = inSlot
    }

    convenience init(inSlot: Symbol?=nil) {
        self.init(inContext: ObjectContextType.This, inSlot: inSlot)
    }
}

/// Abstraction for all tag related actions
public class TagsAction: ObjectAction {
    public let tags: TagList
    public init(inContext:ObjectContextType, inSlot:Symbol?, tags: TagList) {
        self.tags = tags
        super.init(inContext:inContext, inSlot:inSlot)
    }
    convenience public init(tags:TagList) {
        self.init(inContext: ObjectContextType.This, inSlot: nil, tags:tags)
    }
}

/// Set tags of the target object
public class SetTagsAction: TagsAction {}

/// Unset tags of the target object
public class UnsetTagsAction: TagsAction {}

/// Abstract class for counter related actions
public class CounterAction: ObjectAction {
    public let counter: Symbol
    public init(inContext:ObjectContextType, inSlot:Symbol?, counter: Symbol){
        self.counter = counter
        super.init(inContext:inContext, inSlot:inSlot)
    }

    convenience public init(counter: Symbol) {
        self.init(inContext: ObjectContextType.This, inSlot:nil,
                  counter:counter)
    }
}

public class IncCounterAction: CounterAction {}
public class DecCounterAction: CounterAction {}
public class ZeroCounterAction: CounterAction {}

/**
    Action representing binding. Left side of the bond can be object's slot or
    slot indirection. Right side of the bonding action can be object's slot.
*/
public class BindingAction: ObjectAction {
    public let slot: Symbol

    public init(inContext:ObjectContextType, inSlot:Symbol?, slot: Symbol){
        self.slot = slot
        super.init(inContext:inContext, inSlot:inSlot)
    }
}
/// Unbind a slot
// Note: this is just mental placeholder
public class UnbindAction: BindingAction {
}

/** Action representing binding
*/
public class BindAction: BindingAction {
    /// Determines which object is taret of the bond
    public let targetContext: ObjectContextType

    /// Dereference the target
    public let targetSlot: Symbol?

    public init(inContext:ObjectContextType, inSlot:Symbol?, slot:Symbol,
        targetContext:ObjectContextType?, targetSlot: Symbol?){
        self.targetContext = targetContext ?? ObjectContextType.This
        self.targetSlot = targetSlot
            super.init(inContext: inContext, inSlot: inSlot, slot: slot)
    }
}
