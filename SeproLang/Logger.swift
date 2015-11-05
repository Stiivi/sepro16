//
//  Logger.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 31/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

public typealias ProbeRecord = [Symbol:Int]

public protocol Logger {

    func loggingWillStart(measures: [Measure])
    func loggingDidEnd()

    /**
     Allows the observe to observe probed simulation state.
     
     - Parameters:
        - step: Simulation step
        - record: Observed record
     */
    func logRecord(step: Int, record: ProbeRecord)

    /**
     Log a notification.

     - Parameters:
        - step: Simulation step
        - record: notification that occured
     */
    func logNotification(step: Int, notification: Symbol)
}


/**
 Simple logger that prints to the standard output.
 */
public class PrintingLogger: Logger {
    var measures: [Measure]

    public init() {
        measures = [Measure]()
    }

    public func loggingWillStart(measures: [Measure]) {
        self.measures = measures

        let names = self.measures.map { measure in measure.name }
        let header = names.joinWithSeparator(",")
        print(header)
    }

    public func loggingDidEnd() {
        // Do nothing
    }

    public func logRecord(step:Int, record:ProbeRecord) {
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

    public func logNotification(step: Int, notification: Symbol) {
        print("# \(step): \(notification)")
    }

}