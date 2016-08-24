//
//  main.swift
//  sepro
//
//  Created by Stefan Urbanek on 29/10/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Foundation
import Sepro
import Model
import Parser

let processInfo = ProcessInfo.processInfo

func usage() {
    print("Usage: \(processInfo.processName) MODEL STEPS")
}

func main() {
    let engine: SimpleEngine
    let args = processInfo.arguments
    let source: String
    let modelFile: String
    let stepCount: Int

    if args.count < 2 {
        usage()
        return
    }
    else {
        modelFile = args[1]
        stepCount = Int(args[2])!
    }

    print("Loading model from \(modelFile)...")

    do {
        source = try String(contentsOfFile: modelFile, encoding:String.Encoding.utf8)
    } catch {
        print("Error: Unable to read model.")
		exit(1)
    }

    print("Compiling model...")
    let model: Model
    do {
        model = try parseModel(source: source)
    } catch let SyntaxError.ParserError(e) {
        print("Error compiling model: \(e)")
		exit(1)
    }
    catch {
        print("Unknown error")
		exit(1)
    }

    print("Model compiled: \(model.concepts.count) concepts. \(model.actuators.count) actuators")

    let path = "./out"

    engine = SimpleEngine(model:model)
    engine.logger = CSVLogger(path: path)
    engine.delegate = CLIDelegate(path:path)
    
    do {
        try engine.initialize(worldName: "main")
    }
    catch {
        print("Error: Can't initialize engine")
		exit(1)
    }


    engine.debugDump()
    engine.run(steps: stepCount)
    engine.debugDump()

}

main()
