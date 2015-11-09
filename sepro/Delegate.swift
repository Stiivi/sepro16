//
//  Delegate.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 07/11/15.
//  Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import SeproLang

public class CLIDelegate: EngineDelegate {
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
        writeDot("/tmp/sepro/dots/0.dot", selection: engine.store.objects)
        // do nothing
    }

    public func didRun(engine: Engine) {
        writeDot("/tmp/sepro/dots/final.dot", selection: engine.store.objects)
        // do nothing
    }

    public func willStep(engine: Engine, objects: ObjectSelection) {
        // FIXME: this is very awkward hack, since we are getting some
        // bad error here
        print("Will step \(engine.stepCount)")
        let xxx = (engine.store as! SimpleStore).objectMap.values
        let objects = AnySequence(xxx)
        writeDot("/tmp/sepro/dots/\(engine.stepCount).dot", selection: objects)
        // do nothing
    }

    public func didStep(engine: Engine) {
        // do nothing
    }


}
