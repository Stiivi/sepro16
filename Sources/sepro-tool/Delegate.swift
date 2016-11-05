//
//	Delegate.swift
//	SeproLang
//
//	Created by Stefan Urbanek on 07/11/15.
//	Copyright © 2015 Stefan Urbanek. All rights reserved.
//
import Engine
import Model

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
		}.joined(separator:" ")

		print("Traps: \(trapstr)")
	}

	public func dotFileName(set: Int) -> String {
		let name = String(format: "%06d.dot", set)
		return self.path + "/dots/" + name
	}

	public func willRun(engine: Engine) {
		writeDot(path: dotFileName(set: engine.stepCount),
                 engine: engine,
                 selection: engine.container.selectAll())
	}

	public func didRun(engine: Engine) {
		writeDot(path: dotFileName(set: engine.stepCount),
                 engine: engine,
                 selection: engine.container.selectAll())
	}

	public func willStep(engine: Engine) {
		writeDot(path: dotFileName(set: engine.stepCount),
                 engine: engine,
                 selection: engine.container.selectAll())
	}

	public func didStep(engine: Engine) {
		// do nothing
	}


}
