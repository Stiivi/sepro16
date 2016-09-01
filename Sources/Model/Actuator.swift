//
//  Actuator.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 21/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public enum Selector: CustomStringConvertible {
    /// All objects
    case All
    /// Objects matching conjunction of predicates
    case Filter(CompoundPredicate)
    /// Root object if matches conjunction of predicates
    case Root(CompoundPredicate)

    public var description: String {
        switch self {
        case .All: return "ALL"
        case .Filter(let p):
            return p.map({ String(describing:$0) }).joined(separator:" AND ")
        case .Root(let p):
            return "ROOT " + p.map({ String(describing:$0) }).joined(separator:" AND ")
        }
    }

    public var predicates: [Predicate] {
        switch self {
        case .All: return []
        case .Filter(let p):
            return p
        case .Root(let p):
            return p

        }
    }
}

public func ==(left: Selector, right: Selector) -> Bool {
    switch (left, right) {
    case (.All, .All):
        return true
    case (.Filter(let lpred), .Filter(let rpred)) where lpred == rpred:
        return true
    case (.Root(let lpred), .Filter(let rpred)) where lpred == rpred:
        return true
    default:
        return false
    }
}

/**
Combines predicates with their respective modifiers that are executed
when the predicate is met.
*/
public class Actuator {
    public let selector: Selector
    public let combinedSelector: Selector?

    /// Actions performed by the actuator in atomic way.
    public let modifiers: [Modifier]

    /** Stop the computation. This instruction should be used when there
     is no point to continue the simulation, either because an
     expected or invalid state was reached.
     
    Computation can not continue unless the halt flag is cleared.
     */
    public let doesHalt: Bool

    /// Interrupt the computation and handle the trap externally.
    public let traps: [Symbol]?

    /** Passes a notification symbol to the logger without interrupting
     the computation.
     */
    public let notifications: [Symbol]?

    /// `true` when the actuator is combined – specified by two selectors
    public var isCombined: Bool {
        return combinedSelector != nil
    }

    public init(selector: Selector, combinedSelector:Selector?, modifiers: [Modifier],
        traps: [Symbol]?=nil, notifications: [Symbol]?=nil, doesHalt: Bool = false) {
            self.selector = selector
            self.combinedSelector = combinedSelector
            self.modifiers = modifiers
            self.traps = traps
            self.notifications = notifications
            self.doesHalt = doesHalt
    }

    public func asString() -> String {
        // TODO: Implement string representation of the actuator
        return "# (some actuator)"
    }

}

extension Actuator: CustomStringConvertible {
    public var description: String {
        var desc = self.selector.description
        if self.combinedSelector != nil {
            desc += " ON " + self.combinedSelector!.description
        }

        desc += " DO " + self.modifiers.map({String(describing:$0)}).joined(separator:" ")

        if self.traps != nil {
            desc += "TRAP " + self.traps!.joined(separator:" ")
        }

        if self.traps != nil {
            desc += "NOTIFY " + self.notifications!.joined(separator:" ")
        }

        return desc
    }
}
