//
//	Engine.swift
//	AgentFarms
//
//	Created by Stefan Urbanek on 02/10/15.
//	Copyright © 2015 Stefan Urbanek. All rights reserved.
//

import Base
import Model

/**
	Simulation engine interface
*/
public protocol Engine {

	var model:Model { get }
	var container:Container { get }


	/// Run simulation for `steps` number of steps.
	/// 
	/// If a trap occurs during the execution the delegate will be notified
	/// and the simulation run will be stopped.
	/// 
	/// If `HALT` action was encountered, the simulation is terminated and
	/// can not be resumed unless re-initialized.
	func run(steps:Int)
	var stepCount:Int { get }

	/// Initialize the container with `world`. If `world` is not specified then
	/// `main` is used.
    // TODO: This should be simpler. We need to return multiple errors
    // TODO: Flag for stopping after first error/max errors
	func initialize(worldName: Symbol) -> ResultList<Bool, EngineError>

	/// Instantiate concept `name`.
	/// - Returns: reference to the newly created object
	// TODO: move to engine, change this to add(object)
	func instantiate(name: Symbol, initializers:[Initializer]) -> Result<ObjectReference, EngineError>

}

// MARK: Selection Generator

// TODO: make this a protocol, since we can't expose our internal
// implementation of object

public protocol EngineDelegate {
	func willRun(engine: Engine)
	func didRun(engine: Engine)
	func willStep(engine: Engine)
	func didStep(engine: Engine)

	func handleTrap(engine: Engine, traps: CountedSet<Symbol>)
	func handleHalt(engine: Engine)
}

/**
	SimpleEngine – simple implementation of computational engine. Performs
	computations of simulation steps, captures traps and observes probe values.
*/

public final class SimpleEngine: Engine {
	/// Simulation model
	public let model: Model

	/// Simulation state instance
	public var container: Container

	/// Current step
	public var stepCount = 0

	/// Traps caught in the last step
	public var traps = CountedSet<Symbol>()

	/// Flag saying whether the simulation is halted or not.
	public var isHalted: Bool = false

	// Probing
	// -------

	/// List of probes
	public var probes: [Probe]

	/// Logging delegate – an object that implements the `Logger`
	/// protocol
	public var logger: Logger? = nil

	/// Delegate for handling traps, halt and other events
	public var delegate: EngineDelegate? = nil

	/// Create an object instance from concept
	public init(model:Model, container: Container){
		self.container = container
		self.model = model

		self.probes = [Probe]()
	}

	/// Runs the simulation for `steps`.
	public func run(steps:Int) {
        precondition(steps > 0, "Number of steps to run must be greater than 0")
		if logger != nil {
			logger!.loggingWillStart(measures: model.measures, steps: steps)
			// TODO: this should be called only on first run
			probe()
		}
		
		delegate?.willRun(engine:self)
		var stepsRun = 0

		for _ in 1...steps {

			step()

			if isHalted {
				delegate?.handleHalt(engine:self)
				break
			}

			stepsRun += 1
		}

		logger?.loggingDidEnd(steps: stepsRun)
	}

	/// Compute one step of the simulation by evaluating all actuators.
    ///
	func step() {
		traps.removeAll()

		stepCount += 1

		delegate?.willStep(engine: self)

		// >>>
		// The main step...
		model.actuators.shuffled().forEach(perform)
		// <<<

		delegate?.didStep(engine: self)

		if logger != nil {
			probe()
		}

		if !traps.isEmpty {
			delegate?.handleTrap(engine: self, traps: traps)
		}
	}

    ///
    /// Probe the simulation and pass the results to the logger. Probing
	/// is ignored when logger is not provided.
    ///
	/// - Complexity: O(n) – does full scan on all objects
	func probe() {
		var record = ProbeRecord()

		// Nothing to probe if we have no logger
        guard let logger = self.logger else {
            return
        }

		// Create the probes
		let probeList = model.measures.map {
			measure in
			(measure, createProbe(measure: measure))
		}

		container.selectAll().forEach {
			ref in
			probeList.filter {
				measure, _ in
				container.match(ref, predicates: measure.predicates)
            }
            .forEach {
				measure, probe in
                probe.probe(object: container[ref]!)
            }
		}

		// Gather the probe results
		// TODO: replace this with Array<tuple> -> Dictionary
		probeList.forEach {
			measure, probe in
			record[measure.name] = probe.value
		}

		logger.logRecord(step: self.stepCount, record: record)
	}

	/// Dispatch an `actuator` – unary vs. combined
	///
    // TODO: Rename to:
    //          apply(modifier, with: Selector)
    //          apply(modifier, with: Selector, on: Selector)
	func perform(actuator:Actuator){
		if actuator.isCombined {
			self.perform(this: actuator.selector,
						 other: actuator.combinedSelector!,
						 actuator: actuator)
		}
		else {
			self.perform(unary: actuator.selector, actuator: actuator)
		}

		// Handle traps
		//
        if let traps = actuator.traps {
			traps.forEach {
				trap in self.traps.add(trap)
			}
        }

		// TODO: handle 'ONCE'
		// TODO: maybe handle similar way as traps
        if let notifications = actuator.notifications {
			notifications.forEach {
				notification in self.notify(symbol:notification)
			}
		}

		self.isHalted = actuator.doesHalt
	}


	/// Unary actuator execution.
	///
	/// - Complexity: O(n) - performs full scan
	///
    // TODO: Pass modifier only, not whole actuator
	func perform(unary selector: Selector, actuator: Actuator) {
		for this in container.select(selector) {
			// Check for required slots
			if !actuator.modifiers.all({ canApply(modifier: $0, this: this) }) {
				continue
			}

			actuator.modifiers.forEach {
				modifier in
				apply(modifier: modifier, this: this)
			}
		}

	}

	/// Combined actuator execution.
	///
	/// Algorithm:
	///
	/// 1. Find objects matching conditions for `this`
	/// 2. Find objects matching conditions for `other`
	/// 3. If any of the sets is empty, don't perform anything – there is
	///    no reaction
	/// 4. Perform reactive action on the objects.
	///
	/// - Complexity: O(n^2) - performs cartesian product on two full scans
	///
	func perform(this thisSelector: Selector, other otherSelector: Selector,
		actuator: Actuator) {

		let thisRefs = container.select(thisSelector)
		let otherRefs = container.select(otherSelector)

		var match: Bool

		// Cartesian product: everything 'this' interacts with everything
		// 'other'
		// Note: We can't use forEach, as there is no way to break from the loop
		for this in thisRefs {
			// Check for required slots
			for other in otherRefs {
				// Check for required slots
				if !actuator.modifiers.all({ canApply(modifier: $0, this: this, other: other) }) {
					continue
				}
				else if this == other {
					continue
				}

				actuator.modifiers.forEach {
					modifier in
					apply(modifier: modifier, this: this, other: other)
				}

				// Check whether 'this' still matches the predicates
				match = thisSelector == Selector.all
                        || container.match(this, predicates: thisSelector.predicates)
				// ... predicates don't match the object, therefore we
				// skip to the next one
				if !match {
					break
				}
			}
		}

	}

	/// Get "current" object – choose between THIS and OTHER then
	/// optionally apply dereference to a slot, if specified.
	///
	func getCurrent(_ ref: ModifierTarget, this: ObjectReference,
                    other: ObjectReference?=nil) -> Object? {
		let current: ObjectReference

		switch ref.type {
		case .this:
			// Is guaranteed to exist by argument
			current = this
		case .other:
			// Exists only in combined selectors
			assert(other != nil, "Required `other` for .Other target reference")
			current = other!
		}

        if let slot = ref.slot {
            let obj = container[current]!
			assert(obj.slots.contains(slot), "Target sohuld contain slot '\(ref.slot!)'")
			if let indirect = obj.bindings[slot] {
				return container[indirect]!
			}
			else {
				// Nothing bound at the slot
				return nil
			}
        }
        else {
            return container[current]!
        }
	}

	/// - Returns: `true` if the `modifier` can be applied, otherwise `false`
	func canApply(modifier:Modifier, this:ObjectReference, other:ObjectReference!=nil) -> Bool {
		let current = self.getCurrent(modifier.target, this: this, other: other)

		switch modifier.action {
		case .inc(let counter):
			return current?.counters.keys.contains(counter) ?? false

		case .dec(let counter):
			if let value = current?.counters[counter] {
				return value > 0
			}
			else {
				return false
			}

		case .clear(let counter):
			return current?.counters.keys.contains(counter) ?? false

		case .bind(let slot, let targetRef):
			let target = self.getCurrent(targetRef, this: this, other: other)

			if current == nil || target == nil {
				// There is nothing to bind
				// TODO: Should be consider assigning nil as 'unbind' or as failure?
				return false
			}

			return current?.slots.contains(slot) ?? false

		case .unbind(let slot):
			return current?.slots.contains(slot) ?? false
		default:
			return true
		}
	}

	/// Applies `modifier` on either `this` or `other` depending on the modifier's
	/// target
	// TODO: apply(modifier:to:)
	func apply(modifier:Modifier, this:ObjectReference, other:ObjectReference?=nil) {
		guard let current = self.getCurrent(modifier.target, this: this, other: other) else {
			preconditionFailure("Current object for modifier should not be nil (apllication should be guarded)")
		}

        var newTags: TagList? = nil
        var newCounters = current.counters
        var newBindings = current.bindings

		switch modifier.action {
		case .nothing:
			// Do nothing
			break

		case .setTags(let tags):
			newTags = current.tags.union(tags)

		case .unsetTags(let tags):
			newTags = current.tags.subtracting(tags)

		case .inc(let counter):
			let value = current.counters[counter]!
			newCounters[counter] = value + 1

		case .dec(let counter):
			let value = current.counters[counter]!
			newCounters[counter] = value - 1

		case .clear(let counter):
			newCounters[counter] = 0

		case .bind(let slot, let targetRef):
			guard let target = self.getCurrent(targetRef, this: this, other: other) else {
				preconditionFailure("Target sohuld not be nil (application should be guarded)")
			}

			newBindings[slot] = target.id

		case .unbind(let slot):
			newBindings[slot] = nil
		}


        let newObject = current.copy(
            tags:newTags,
            counters:newCounters,
            bindings:newBindings
        )
        container.update(object: newObject)
	}

	func notify(symbol: Symbol) {
		self.logger?.logNotification(step: self.stepCount, notification: symbol)
	}

	// MARK: Instantiation

	/// Initialize the container according to the model. All existing objects will
	/// be discarded.
	public func initialize(worldName: Symbol="main") -> ResultList<Bool, EngineError> {
		// FIXME: handle non-existing world
		let world = self.model.getWorld(name: worldName)!

		// Clean-up the objects container
		self.container.removeAll()

        // TODO: gather errors
		let result = self.instantiateGraph(graph: world.graph)

        if case let .failure(errors) = result {
            return .failure(errors)
        }
        else {
            return .success(true)
        }
	}
	/// Creates instances of objects in the GraphDescription and returns a
	/// dictionary of created named objects.
	@discardableResult
	func instantiateGraph(graph: InstanceGraph) -> ResultList<ObjectMap, EngineError> {
        // TODO: Return Object Reference Dictionary
        // TODO: Gather all the errors
        // TODO: Have instantiation of multiple elements through a function
        // something like 'reduce':(proto, state) -> (object, state))
		var map = ObjectMap()
        var errors: [EngineError] = []

        // TODO: Refactor this ugly loop
		graph.instances.forEach() { inst in
			switch inst.type {
			case let .named(name):
                let result = instantiate(name: inst.concept,
                                         initializers: inst.initializers) 
                if case let .failure(error) = result {
                    errors.append(error)
                }
                else {
                    map[name] = result.value!
                }
			case let .counted(count):
                // TODO: Gather errors
				for _ in 1...count {
					instantiate(name: inst.concept,
                                initializers: inst.initializers)
				}
			}
		}

        if errors.isEmpty {
            return .success(map)
        }
        else {
            return .failure(errors)
        }
	}


	/// Instantiate a concept `concept` with optional initializers for tags
	/// and concepts `initializers`. Created instance will have additional tag
	/// set – the concept name symbol. 
	/// 
	/// - Returns: reference to the newly created object
	@discardableResult
	public func instantiate(name:Symbol, initializers: [Initializer]=[])
            -> Result<ObjectReference, EngineError> {
		guard let concept = self.model.getConcept(name: name) else {
			return .failure(.unknownConcept(name))
		}

        let implicitTags = TagList([name])
        let tags = concept.tags.union(implicitTags)
        var counters = concept.counters

        let initTags = TagList(initializers.flatMap {
            initializer in
            switch initializer {
            case let .tag(symbol): return symbol
            default: return nil
            }
        })

        let initCounters:[(Symbol,Int)] = initializers.flatMap {
            initializer in
            switch initializer {
            case let .counter(symbol, value): return (symbol, value)
            default: return nil
            }
        }

        counters.update(from: Dictionary(items:initCounters))
    
        let obj = Object(tags: tags.union(initTags),
                         counters:counters,
                         slots:concept.slots)
        let ref = container.insert(object: obj)
        return .success(ref)
	}

	/// Create a structure of conceptual objects
	public func createStruct(str:Struct) throws {
		// var instances = [String:Object]()

		// Create concept instances
//		  for (name, concept) in str.concepts {
//			  let obj = self.createObject(concept)
//			  instances[name] = obj
//		  }
//
//
//		  for (sourceRef, targetRef) in str.links {
//
//			  guard let source = instances[sourceRef.owner] else {
//				  throw SimulationError.UnknownObject(name:sourceRef.owner)
//			  }
//			  guard let target = instances[targetRef] else	{
//				  throw SimulationError.UnknownObject(name:targetRef)
//			  }
//
//
//			  source.links[sourceRef.property] = target
//		  }
	}

	public func debugDump() {
		print("ENGINE DUMP START\n")
		print("STEP \(self.stepCount)")
		self.container.selectAll().forEach {
			ref in
            let obj = container[ref]!
			print("\(obj.debugDescription)")
		}
		print("END OF DUMP\n")
	}
}

extension Predicate {
    /**
     Evaluate predicate on `object`.
     
     - Returns: `true` if `object` matches predicate, otherwise `false`
     */
    public func matchesObject(object: Object) -> Bool {
        let result: Bool

        switch self.type {
        case .all:
            result = true

        case .tagSet(let tags):
            if isNegated {
                result = tags.isDisjoint(with:object.tags)
            }
            else {
                result = tags.isSubset(of:object.tags)
            }

        case .counterZero(let counter):
            if let counterValue = object.counters[counter] {
                result = (counterValue == 0) != self.isNegated
            }
            else {
                // TODO: Shouldn't we return false or have invalid state?
                result = false
            }

        case .isBound(let slot):
            result = (object.bindings[slot] != nil) != self.isNegated
        }

        return result
    }
}
