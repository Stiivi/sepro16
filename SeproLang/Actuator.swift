//
//  Actuator.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 21/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public struct Selector {
    /// Denother whether the predicates are related to the root object
    public let isRoot: Bool
    /// Predicates that trigger the actuator
    public let predicates: [Predicate]
    /// Actions performed by the actuator in atomic way.
    public let otherPredicates: [Predicate]?

    public init(predicates: [Predicate], otherPredicates: [Predicate]?=nil,
        isRoot:Bool=false) {
        self.isRoot = isRoot
        self.predicates = predicates
        self.otherPredicates = otherPredicates
    }

}

/**
Combines predicates with their respective modifiers that are executed
when the predicate is met.
*/
public class Actuator {
    public let selector: Selector

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

    public init(selector: Selector, modifiers: [Modifier],
        traps: [Symbol]?=nil, notifications: [Symbol]?=nil, doesHalt: Bool = false) {
            self.selector = selector
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
