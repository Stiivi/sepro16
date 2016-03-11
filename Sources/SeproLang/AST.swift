//
//  AST.swift
//  SeproLang
//
//  Created by Stefan Urbanek on 19/01/16.
//  Copyright © 2016 Stefan Urbanek. All rights reserved.
//

// Constructs that don't have real model representation. They are used
// only during parsing.
//

enum ObjectMember {
    case Tags(TagList)
    case Slots([Symbol])
    case Counter(Symbol, Int)
}


// TODO: There must be a nicer way...
func makeConcept(name: String, _ members: [ObjectMember]) -> Concept {
    let allTags: [TagList] = members.flatMap {
        switch $0 {
        case .Tags(let syms): return syms
        default: return nil
        }
    }

    let allSlots: [[Symbol]] = members.flatMap {
        switch $0 {
        case .Slots(let syms): return syms
        default: return nil
        }
    }

    let allCounters: [(String, Int)] = members.flatMap {
        switch $0 {
        case .Counter(let sym, let count): return (sym, count)
        default: return nil
        }
    }

    let tags = TagList(allTags.flatten())
    let slots = [Symbol](allSlots.flatten())
    let counters = CounterDict(items: allCounters)

    return Concept(name: name, tags: tags, slots: slots, counters: counters)
}

enum ModelObject {
    case ConceptModel(Concept)
    case ActuatorModel(Actuator)
    case WorldModel(World)

    case StructModel(Struct)
    case MeasureModel(Measure)

    case DataModel(TagList, String)
}

func createModel(objects: [ModelObject]) -> Model {
    let concepts: [Concept] = objects.flatMap {
        switch $0 {
        case .ConceptModel(let obj): return obj
        default: return nil
        }
    }

    let actuators: [Actuator] = objects.flatMap {
        switch $0 {
        case .ActuatorModel(let obj): return obj
        default: return nil
        }
    }

    let worlds: [World] = objects.flatMap {
        switch $0 {
        case .WorldModel(let obj): return obj
        default: return nil
        }
    }

    let structs: [Struct] = objects.flatMap {
        switch $0 {
        case .StructModel(let obj): return obj
        default: return nil
        }
    }

    let measures: [Measure] = objects.flatMap {
        switch $0 {
        case .MeasureModel(let obj): return obj
        default: return nil
        }
    }

    let data: [(TagList, String)] = objects.flatMap {
        switch $0 {
        case .DataModel(let obj): return obj
        default: return nil
        }
    }

    return Model(concepts: concepts, actuators: actuators, measures: measures,
                           worlds: worlds, structures: structs,
                                   data: data)
}



enum GraphMember {
    case InstanceMember([Instance])
    case BindingMember([Binding])

    func instances() -> [Instance]? {
        switch(self) {
        case InstanceMember(let val): return val
        default: return nil
        }
    }

    func bindings() -> [Binding]? {
        switch(self) {
        case BindingMember(let val): return val
        default: return nil
        }
    }
}

func createGraph(members: [GraphMember]) -> InstanceGraph {
    let bindings = members.flatMap { m in m.bindings() }.flatten()
    let instances = members.flatMap { m in m.instances() }.flatten()

    let graph = InstanceGraph(instances: Array(instances), bindings: Array(bindings))

    return graph
}

enum ASTInstanceType {
    case Counted(Int)
    case Named(Symbol)
    case Default
}

func createInstance(symbol: Symbol, initializers:[Initializer]?, type:
	ASTInstanceType) -> Instance { 

	let translatedType: InstanceType

	switch type {
	case .Counted(let count): translatedType = InstanceType.Counted(count)
	case .Named(let name):    translatedType = InstanceType.Named(name)
	case .Default:        translatedType = InstanceType.Named(symbol)
	}

	return Instance(concept: symbol, initializers: initializers ?? [],
					type: translatedType)

}

