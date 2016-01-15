//: Playground - noun: a place where people can play

// Note: we are using underscode instead of camelCase for gramar rules
// to maintain consistency with common practice in BNF

import ParserCombinator

extension Token: EmptyCheckable {
    public static let EmptyValue = Token(.Empty, "")
    public var isEmpty: Bool { return self.kind == TokenKind.Empty }
}

enum SymbolType: CustomStringConvertible {
    case Tag
    case Slot
    case Counter
    case Concept

    var description: String {
        switch self {
        case .Tag: return "tag"
        case .Slot: return "slot"
        case .Counter: return "counter"
        case .Concept: return "concept"
        }
    }
}

// Intermediate
// =======================================================================
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

    return Model(concepts: concepts, actuators: actuators, measures: measures,
                           worlds: worlds, structures: structs)
}



enum GraphMember {
    case InstanceMember([InstanceSpecification])
    case BindingMember([Binding])

    func instances() -> [InstanceSpecification]? {
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

func createGraph(members: [GraphMember]) -> GraphDescription {
    let bindings = members.flatMap { m in m.bindings() }.flatten()
    let instances = members.flatMap { m in m.instances() }.flatten()

    let graph = GraphDescription(instances: Array(instances), bindings: Array(bindings))

    return graph
}

enum InstanceSpec {
    case Count(Int)
    case Name(Symbol)
    case NoName

    func contentObject(sym: Symbol) -> InstanceSpecification {
        switch(self) {
        case .Count(let val): return InstanceSpecification.Counted(sym, val)
        case .Name(let val):  return InstanceSpecification.Named(sym, val)
        case .NoName:         return InstanceSpecification.Named(sym, sym)
        }
    }
}


// Terminals
// =======================================================================

func token(kind: TokenKind, _ expected: String) -> Parser<Token, Token> {
    return satisfy(expected) { token in token == kind }
}

func tokenValue(kind: TokenKind, _ value: String) -> Parser<Token, Token> {
    return satisfy(value) { token in token == Token(kind, value) }
}

let symbol  = { name  in token(.Identifier, name)  => { t in Symbol(t.text) } }
let number  = { label in token(.IntLiteral, label) => { t in Int(t.text)! } }
let keyword = { kw    in tokenValue(.Keyword, kw)  => { t in t.text } }
let op      = { o     in tokenValue(.Operator, o) }

// TODO: This is just to type-hint the following rule. Otherwise Swift does not
// know that the `type` is of `SymbolType`
func typeDesc(type: SymbolType) -> String {
    return type.description
}

// Primitive Items
// =======================================================================

let symbol_list = { type in separated(symbol(typeDesc(type)), op(",")) }
let tag_list = symbol_list(.Tag) => { ast in TagList(ast) }

// String comparable
public prefix func §(value: String) -> Parser<Token, String>{
    return keyword(value)
}

public prefix func %(value: String) -> Parser<Token, Symbol>{
    return symbol(value)
}

infix operator ... { associativity left precedence 130 }
public func ...<T, A, B>(p: Parser<T,A>, sep:Parser<T,B>) -> Parser<T,[A]> {
    return separated(p, sep)
}

// Concept
// =======================================================================

let concept_member  =
           §"TAG"     *> tag_list           => ObjectMember.Tags
        || §"SLOT"    *> symbol_list(.Slot) => ObjectMember.Slots
        || §"COUNTER" *> %"counter" + ((§"=" *> number("initial count")) || succeed(0))
                             => { (sym, count) in return ObjectMember.Counter(sym, count)}


let concept =
        §"CONCEPT" *> %"name" + many(concept_member) => { (name, members) in makeConcept(name, members) }


let predicate_type =
           §"SET"   *> tag_list         => PredicateType.TagSet
        || §"BOUND" *> %"slot"          => PredicateType.IsBound
        || §"ZERO"  *> %"counter"       => PredicateType.CounterZero
        ||             tag_list         => PredicateType.TagSet
        || fail("Expected predicate type")


// Actuator
// ========================================================================

// Selector
// ------------------------------------------------------------------------

// §"NOT" *> succeed(true) || succeed(false)
let predicate =
        (optionFlag(§"NOT") + option(§"IN" *> %"slot") + predicate_type)
                => { (ctx, type) in return Predicate(type, ctx.0, inSlot: ctx.1) }

let predicate_list = (predicate ... §"AND")

let selector =
               §"ALL"  *>                          succeed(Selector.All)
            || §"ROOT" *> (predicate ... §"AND")   => Selector.Root
            ||            (predicate ... §"AND")   => Selector.Filter


// Modifier
// ------------------------------------------------------------------------

let target_type =
           §"THIS"  *> succeed(TargetType.This)
        || §"OTHER" *> succeed(TargetType.Other)
        || §"ROOT"  *> succeed(TargetType.Root)

let modifier_target =
        target_type + option(op(".") *> %"slot") => { target in ModifierTarget(target.0, target.1) }
        || %"slot"                               => { symbol in ModifierTarget(TargetType.This, symbol)}

let bind_target = modifier_target

let modifier_action =
           §"NOTHING" *>              succeed(ModifierAction.Nothing)
        || §"SET"     *> tag_list     => ModifierAction.SetTags
        || §"UNSET"   *> tag_list     => ModifierAction.UnsetTags
        || §"INC"     *> %"counter"   => ModifierAction.Inc
        || §"DEC"     *> %"counter"   => ModifierAction.Dec
        || §"CLEAR"   *> %"counter"   => ModifierAction.Clear
        || §"UNBIND"  *> %"slot"      => ModifierAction.Unbind
        || §"BIND"    *> %"slot" + (§"TO" *> bind_target) => { ast in ModifierAction.Bind(ast.0, ast.1)}
        || fail("Expected modifier action")

let modifier =
        ((§"IN" *> nofail(modifier_target)) || succeed(ModifierTarget(.This) ))
            + modifier_action => { mod in Modifier(target: mod.0, action: mod.1) }

// WHERE something DO something
// WHERE something ON somethin else DO something
// ((selector, selector?), [modifier])
let actuator =
    ((§"WHERE" *> selector) + option(§"ON" *> selector)) + nofail(§"DO" *> some(modifier))
            => { ast in Actuator(selector: ast.0.0, combinedSelector:ast.0.1, modifiers:ast.1) }

// World
// ========================================================================

let instance =
    (%"symbol" +
    (
           op("*")  *> number("instance count") => InstanceSpec.Count
        || §"AS"    *> %"name"                  => InstanceSpec.Name
        ||                                         succeed(InstanceSpec.NoName)
    ))
    => { spec in spec.1.contentObject(spec.0) }

let binding =
    %"obj" + (op(".") *> %"slot") + (§"TO" *> %"target")
        => { spec in Binding(source:spec.0.0, sourceSlot:spec.0.1, target:spec.1)}

let graph_member =
           §"OBJECT" *> (instance ... op(",")) => GraphMember.InstanceMember
        || §"BIND"   *> (binding ... op(","))  => GraphMember.BindingMember

let world =
        (§"WORLD" *> %"name") + (option(§"ROOT" *> %"symbol") + (many(graph_member) => createGraph))
            => { x in World(name: x.0, graph: x.1.1, root: x.1.0) }


// Model
// ========================================================================
let model_object =
           concept  => ModelObject.ConceptModel
        || actuator => ModelObject.ActuatorModel
        || world    => ModelObject.WorldModel
//        || fail("Expected model object")

let model =
        nofail(some(model_object)) => createModel
