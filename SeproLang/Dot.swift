//
//  Dot.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 04/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import SeproLang

public enum Shape {
    case Rectangle
    case Circle
    case Triangle
    case Diamond
    case Pentagon
    case Hexagon
    case Trapezoid
    case Parallelogram

    public var dotShape: String {
        switch self {
        case Rectangle: return "box"
        case Circle: return "circle"
        case Triangle: return "triangle"
        case Diamond: return "diamond"
        case Pentagon: return "pentagon"
        case Hexagon: return "hexagon"
        case Trapezoid: return "trapezium"
        case Parallelogram: return "parallelogram"
        }
    }
}

/**
 Generator for `.dot` graph files. Every object and its links are
emmited in a single line.
*/
func objectToDot(obj: Object) -> String {
    var line: String
    let links: [String]

    links = obj.links.map { slot, ref in
        "\(obj.id) -> \(ref) [label=\"\(slot)\"]"
    }

    let tags = obj.tags.sort().joinWithSeparator(",")
    let label = "\(obj.id):\(tags)"
    line = "    \(obj.id) [font=Helvetica,shape=box,label=\"\(label)\"]; "

    if !links.isEmpty {
        line += links.joinWithSeparator("; ") + ";"
    }

    line += "\n"

    return line
}

public func writeDot(path: String, selection: AnySequence<Object>) {
    let file: NSFileHandle
    let manager = NSFileManager.defaultManager()
    var line: String!

    print("Writing dot \(path)")

    manager.createFileAtPath(path, contents:nil, attributes:nil)
    file = NSFileHandle.init(forWritingAtPath: path)!

    line = "digraph g {"
    file.writeData(line.dataUsingEncoding(NSUTF8StringEncoding)!)

    selection.forEach {
        obj in
        line = objectToDot(obj)
        if let data = line.dataUsingEncoding(NSUTF8StringEncoding) {
            file.writeData(data)
        }
    }

    line = "}"
    file.writeData(line.dataUsingEncoding(NSUTF8StringEncoding)!)
    file.closeFile()
}




