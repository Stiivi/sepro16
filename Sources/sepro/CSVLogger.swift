//
//	CSVObserver.swift
//	SeproLang
//
//	Created by Stefan Urbanek on 01/11/15.
//	Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import SeproLang
import Foundation

/**
Simple CSV writer. Does not do quoting.
*/
public class CSVWriter {
	let path:String
	let file: NSFileHandle
	var recordSeparator = ","
	var lineSeparator = "\n"

	public init(path: String) {
		let manager = NSFileManager.defaultManager()

		self.path = path

		manager.createFile(atPath:path, contents:nil, attributes:nil)
		self.file = NSFileHandle.init(forWritingAtPath: self.path)!
	}

	public func writeRow(values: [String]) {
		let strings = values.map() { value in
			value == nil ? "" : String(value)
		}
		let line = strings.joined(separator:self.recordSeparator) + self.lineSeparator
		self.file.write(line.data(usingEncoding:NSUTF8StringEncoding)!)
	}

	public func close() {
		self.file.closeFile()
	}
}

/**
 Simple observer that prints to the standard output.
 */

public class CSVLogger: Logger {
	var measures: [Measure]
	let root: String
	var measureWriter: CSVWriter! = nil
	var notificationWriter: CSVWriter! = nil

	public init(path: String) {
		self.measures = [Measure]()
		self.root = path

		let manager = NSFileManager.defaultManager()

		do {
			try manager.createDirectory(atPath: self.root, withIntermediateDirectories: true, attributes: nil)
		}
		catch let error as NSError {
			print("Unable to create directory: \(error)")
			exit(1)
		}

		let mpath = self.root + "/" + "measures.csv"
		self.measureWriter = CSVWriter(path: mpath)

		let npath = self.root + "/" + "notifications.csv"
		self.notificationWriter = CSVWriter(path: npath)
	}

	public func loggingWillStart(measures: [Measure], steps: Int) {
		self.measures = measures

		var names = self.measures.map { measure in measure.name }
		names.insert("step", at: 0)

		self.measureWriter.writeRow(names)
	}

	public func loggingDidEnd(steps: Int) {
		self.measureWriter.close()
		self.notificationWriter.close()
	}

	public func logRecord(step:Int, record:ProbeRecord) {
		var row: [String]

		row = self.measures.map {
			measure in
			if let value = record[measure.name] {
				return String(value)
			}
			else {
				return ""
			}
		}

		row.insert(String(step), at: 0)
		self.measureWriter.writeRow(row)
	}

	public func logNotification(step: Int, notification: Symbol) {
		let row = [String(step), String(notification)]
		self.notificationWriter.writeRow(row)
	}
}
