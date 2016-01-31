//
//  Delegate.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 07/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import SeproLang

public class CLIDelegate: EngineDelegate {
    public let path: String

    public init(path: String) {
        self.path = path
    }

    public func handleHalt(engine: Engine) {
        print("Halted!")
    }

    public func handleTrap(engine: Engine, traps: CountedSet<Symbol>) {
        let trapstr = traps.map {
            trap, count in
            "\(trap):\(count)"
        }.joinWithSeparator(" ")

        print("Traps: \(trapstr)")
    }

    public func dotFileName(set: Int) -> String {
        let name = String(format: "%06d.dot", set)
        return self.path + "/dots/" + name
    }

    public func willRun(engine: Engine) {
        writeDot(dotFileName(engine.stepCount), model: engine.model, selection: engine.store.select())
    }

    public func didRun(engine: Engine) {
        writeDot(dotFileName(engine.stepCount), model: engine.model, selection: engine.store.select())
    }

    public func willStep(engine: Engine) {
        writeDot(dotFileName(engine.stepCount), model: engine.model, selection: engine.store.select())
    }

    public func didStep(engine: Engine) {
        // do nothing
    }


}
