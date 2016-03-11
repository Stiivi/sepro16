//
//	Dot.swift
//	SeproLang
//
//	Created by Stefan Urbanek on 04/11/15.
//	Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Foundation
import SeproLang

public struct DotAttributes {
	var attributes = [String:String]()

	public subscript(key: String) -> Int? {
		get {
			return Int(attributes[key]!)
		}
		set(value) {
			if value != nil {
				attributes[key] = String(value!)
			}
			else {
				attributes[key] = "0"
			}
		}
	}

	public subscript(key: String) -> String? {
		get {
			return attributes[key]
		}
		set(value) {
			attributes[key] = value
		}
	}

	public var stringValue:String {
		let retval = self.attributes.map { key, value in
			let quotedValue: String
			let quotedKeys = ["label"]

			if quotedKeys.contains(key) || value.containsString(" ") {
				// Quote the value
				quotedValue = "\"\(value)\""
			}
			else {
				quotedValue = value
			}
			return "\(key)=\(quotedValue)"
		}.joinWithSeparator(",")

		return retval

	}

}

/// Generator for `.dot` graph files. Every object and its links are
/// emmited in a single line.
public class DotWriter{
	public let path: String
	public var header = "digraph g {"
	public var footer = "}"
	public var fontName = "Helvetica"

	let file: NSFileHandle
	var line: String!
	let model: Model

	init(path: String, model: Model) {
		let manager = NSFileManager.defaultManager()
		self.path = path
		self.model = model

		manager.createFileAtPath(path, contents:nil, attributes:nil)

		self.file = NSFileHandle.init(forWritingAtPath: path)!
		self.writeLine(header)
	}

	public func closeGraph() {
		self.writeLine(footer)
	}

	func writeLine(str: String) {
		let line = str + "\n"
		if let data = line.dataUsingEncoding(NSUTF8StringEncoding) {
			file.writeData(data)
		}
	}

	/// Write object node and it's relationships from slots. Nodes
	/// are labelled with object ids.
	func writeObject(obj: Object) {
		var line: String
		let links: [String]
		var linkAttrs = DotAttributes()

		links = obj.bindings.map { slot, ref in
			linkAttrs["label"] = slot
			linkAttrs["fontname"] = self.fontName
			linkAttrs["fontsize"] = 9

			return "\(obj.id) -> \(ref) [\(linkAttrs.stringValue)]"
		}

		let tags = obj.tags.sort().joinWithSeparator(",")
		let counters = obj.counters.map {k, v in return "\(k)=\(v)"}

		// Fromatting from data
		let allData = obj.tags.flatMap { tag in self.model.getData(Set([tag, "dot:attributes"])) }
		var data = allData.joinWithSeparator(",")
		if data != "" {
			data = "," + data
		}

		let label = "\(obj.id):\(tags)"
		var attrs = DotAttributes()

		attrs["fontname"] = fontName
		attrs["shape"] = "box"
		attrs["style"] = "rounded"
		if counters.count == 0 {
			attrs["label"] = label
		}
		else {
			attrs["label"] = label + ";" + counters.joinWithSeparator(",") 
		}

		attrs["fontsize"] = 11

		line = "    \(obj.id) [\(attrs.stringValue)\(data)]; "

		if !links.isEmpty {
			line += links.joinWithSeparator("; ") + ";"
		}

		self.writeLine(line)
	}
}

public func writeDot(path: String, model: Model, selection: ObjectSelection) {
	let writer = DotWriter(path: path, model: model)

	// FIXME: Despite we might want some kind of sorting, this also
	// serves as a hack. Without this sorting we would get a runtime error
	let sorted = selection.sort { left, right in left.id < right.id }

	sorted.forEach {
		obj in
		writer.writeObject(obj)
	}

	writer.closeGraph()
}
