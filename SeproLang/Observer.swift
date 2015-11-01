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
    func observationWillStart(measures: [Measure])
    func observationDidEnd()

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
    var measures: [Measure]

    public init() {
        measures = [Measure]()
    }

    public func observationWillStart(measures: [Measure]) {
        self.measures = measures

        let names = self.measures.map { measure in measure.name }
        let header = names.joinWithSeparator(",")
        print(header)
    }

    public func observationDidEnd() {
        // Do nothing
    }

    public func observe(step:Int, record:ProbeRecord) {
        var stringValues: [String]

        stringValues = self.measures.map {
            measure in
            if let value = record[measure.name] {
                return String(value)
            }
            else {
                return ""
            }
        }

        stringValues.insert("\(step)", atIndex: 0)
        let line = stringValues.joinWithSeparator(",")

        print(line)
    }

    public func notify(step: Int, notification: Symbol) {
        print("# \(step): \(notification)")
    }

}