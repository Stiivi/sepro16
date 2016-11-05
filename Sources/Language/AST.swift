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

import Model
import Base

enum ObjectMember {
    case tags(TagList)
    case slots([Symbol])
    case counter(Symbol, Int)
}


// TODO: There must be a nicer way...
func makeConcept(_ name: String, _ members: [ObjectMember]) -> Concept {
    let allTags: [TagList] = members.flatMap {
        switch $0 {
        case .tags(let syms): return syms
        default: return nil
        }
    }

    let allSlots: [[Symbol]] = members.flatMap {
        switch $0 {
        case .slots(let syms): return syms
        default: return nil
        }
    }

    let allCounters: [(String, Int)] = members.flatMap {
        switch $0 {
        case .counter(let sym, let count): return (sym, count)
        default: return nil
        }
    }

    let tags = TagList(allTags.joined())
    let slots = [Symbol](allSlots.joined())
    let counters = CounterDict(items: allCounters)

    return Concept(name: name, counters: counters, slots: slots,  tags: tags)
}

enum ModelObject {
    case ConceptModel(Concept)
    case ActuatorModel(Actuator)
    case WorldModel(World)

    case StructModel(Struct)
    case MeasureModel(Measure)

    case DataModel(TagList, String)
}



enum GraphMember {
    case InstanceMember([Instance])
    case BindingMember([Binding])

    func instances() -> [Instance]? {
        switch(self) {
        case .InstanceMember(let val): return val
        default: return nil
        }
    }

    func bindings() -> [Binding]? {
        switch(self) {
        case .BindingMember(let val): return val
        default: return nil
        }
    }
}

func createGraph(_ members: [GraphMember]) -> InstanceGraph {
    let bindings = members.flatMap { m in m.bindings() }.joined()
    let instances = members.flatMap { m in m.instances() }.joined()

    let graph = InstanceGraph(instances: Array(instances), bindings: Array(bindings))

    return graph
}

enum ASTInstanceType {
    case counted(Int)
    case named(Symbol)
    case `default`
}

func createInstance(_ symbol: Symbol, initializers:[Initializer]?, type:
	ASTInstanceType) -> Instance { 

	let translatedType: InstanceType

	switch type {
	case .counted(let count): translatedType = InstanceType.counted(count)
	case .named(let name):    translatedType = InstanceType.named(name)
	case .default:        translatedType = InstanceType.named(symbol)
	}

	return Instance(concept: symbol, initializers: initializers ?? [],
					type: translatedType)

}


func createModel(_ objects: [ModelObject]) -> Model {
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


