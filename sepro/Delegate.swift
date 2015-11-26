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

    public func willRun(engine: Engine) {
        writeDot(self.path + "/dots/0.dot", selection: engine.store.select())
    }

    public func didRun(engine: Engine) {
        writeDot(self.path + "/dots/final.dot", selection: engine.store.select())
    }

    public func willStep(engine: Engine, objects: ObjectSequence) {
        writeDot(self.path + "/dots/\(engine.stepCount).dot", selection: objects)
    }

    public func didStep(engine: Engine) {
        // do nothing
    }


}
