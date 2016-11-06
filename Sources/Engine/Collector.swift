//
//  Collector.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 31/10/15.
//

import Model

public typealias ProbeRecord = [Symbol:Int]

/// Represents objects that can collect probing data from an engine.
///
public protocol Collector {
    /// Prepare before the engine runs for `steps`. The list of
    /// measures might change between subsequent calls. It is up to the
    /// logger how to handle the change.
    ///
    func collectingWillStart(measures: [Measure], steps: Int)

    /// Engine finished running and it did run for `steps`, which might
    ///  be the same or less than the number of steps advertised in the
    /// `loggingWillStart()` call.*/
    ///
    func collectingDidEnd(steps: Int)

    ///
    /// Allows the observe to observe probed simulation state.
    /// 
    /// - Parameters:
    ///    - step: Simulation step
    ///    - record: Observed record
    ///
    func logRecord(step: Int, record: ProbeRecord)

    /// Log a notification.
    ///
    /// - Parameters:
    ///    - step: Simulation step
    ///    - record: notification that occured
    ///
    func logNotification(step: Int, notification: Symbol)
}


/// Simple collector that prints to the standard output.
///
public class PrintingCollector: Collector {
    var measures: [Measure]

    public init() {
        measures = [Measure]()
    }

    public func collectingWillStart(measures: [Measure], steps: Int) {
        self.measures = measures

        let names = self.measures.map { measure in measure.name }
        let header = names.joined(separator:",")
        print(header)
    }

    public func collectingDidEnd(steps: Int) {
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

        stringValues.insert("\(step)", at: 0)
        let line = stringValues.joined(separator:",")

        print(line)
    }

    public func logNotification(step: Int, notification: Symbol) {
        print("# \(step): \(notification)")
    }

}
