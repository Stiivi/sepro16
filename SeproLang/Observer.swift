//
//  Observer.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 01/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public protocol Observer {
    // TODO: we should not receive whole engine, just limited access
    func observeNotification(notification: Symbol)
    func observeTrap(trap: Symbol)
    func observeHalt()

    func willStep()
    func didStep()

    func willProbe()
    func didProbe()
}