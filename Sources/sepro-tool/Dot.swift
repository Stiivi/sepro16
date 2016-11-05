//
//	Dot.swift
//	SeproLang
//
//	Created by Stefan Urbanek on 04/11/15.
//	Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Foundation
import Engine
import Model

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

			if quotedKeys.contains(key) || value.contains(" ") {
				// Quote the value
				quotedValue = "\"\(value)\""
			}
			else {
				quotedValue = value
			}
			return "\(key)=\(quotedValue)"
		}.joined(separator:",")

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

	let file: FileHandle
	var line: String!
	let model: Model
    let engine: Engine

	init(path: String, engine: Engine) {
		let manager = FileManager.default
		self.path = path
        self.engine = engine
		self.model = engine.model

		manager.createFile(atPath: path, contents:nil, attributes:nil)

		self.file = FileHandle.init(forWritingAtPath: path)!
		self.writeLine(header)
	}

	public func closeGraph() {
		self.writeLine(footer)
	}

	func writeLine(_ str: String) {
		let line = str + "\n"
		if let data = line.data(using: String.Encoding.utf8) {
			file.write(data)
		}
	}

	/// Write object node and it's relationships from slots. Nodes
	/// are labelled with object ids.
	func writeObject(_ obj: Object) {
		var line: String
		let links: [String]
		var linkAttrs = DotAttributes()

		links = obj.bindings.map { slot, ref in
			linkAttrs["label"] = slot
			linkAttrs["fontname"] = self.fontName
			linkAttrs["fontsize"] = 9

            let idString = obj.id.map { String(describing: $0) } ?? "<noid>"
			return "\(idString) -> \(ref) [\(linkAttrs.stringValue)]"
		}

		let tags = obj.tags.sorted().joined(separator:",")
		let counters = obj.counters.map {k, v in return "\(k)=\(v)"}

		// Fromatting from data
		let allData = obj.tags.flatMap { tag in self.model.getData(tags: Set([tag, "dot_attributes"])) }

		var data = allData.joined(separator:",")
		if data != "" {
			data = "," + data
		}

        let idString = obj.id.map { String(describing: $0) } ?? "<noid>"
		let label = "\(idString):\(tags)"
		var attrs = DotAttributes()

		attrs["fontname"] = fontName
		attrs["shape"] = "box"
		attrs["style"] = "rounded"
		if counters.count == 0 {
			attrs["label"] = label
		}
		else {
			attrs["label"] = label + ";" + counters.joined(separator:",") 
		}

		attrs["fontsize"] = 11

		line = "    \(idString) [\(attrs.stringValue)\(data)]; "

		if !links.isEmpty {
			line += links.joined(separator:"; ") + ";"
		}

		self.writeLine(line)
	}
}

public func writeDot(path: String, engine: Engine, selection: ObjectSelection) {
	let writer = DotWriter(path: path, engine: engine)

	selection.forEach {
		ref in
        let obj = engine.container[ref]!
		writer.writeObject(obj)
	}

	writer.closeGraph()
}
