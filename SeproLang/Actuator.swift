//
//  Actuator.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 21/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public enum Selector {
    /// All objects
    case All
    /// Objects matching conjunction of predicates
    case Filter(CompoundPredicate)
    /// Root object if matches conjunction of predicates
    case Root(CompoundPredicate)
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
public struct Actuator {
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
        print("MAKING ACTUATOR")
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
