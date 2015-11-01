//
//  Observer.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 31/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public typealias ProbeRecord = [Symbol:Int]

public protocol Observer {

    /**
     Allows the observe to observe probed simulation state.
     
     - Parameters:
        - step: Simulation step
        - record: Observed record
     */
    func observe(step: Int, record: ProbeRecord)

    /**
     Observe a notification.

     - Parameters:
        - step: Simulation step
        - record: Occured notification
     */
    func notify(step: Int, notification: Symbol)
}


/**
 Simple observer that prints to the standard output.
 */
public class PrintingObserver: Observer {

    public func observe(step:Int, record:ProbeRecord) {
        let items = record.map {
            key, value in
            "\(key):\(value)"
        }

        let line = items.joinWithSeparator(",")
        print("\(step)," + line)
    }

    public func notify(step: Int, notification: Symbol) {
        print("# \(step): \(notification)")
    }

}