//: Playground - noun: a place where people can play

// Note: we are using underscode instead of camelCase for gramar rules
// to maintain consistency with common practice in BNF

import ParserCombinator

extension Token: EmptyCheckable {
    public static let EmptyValue = Token(.Empty, "")
    public var isEmpty: Bool { return self.kind == TokenKind.Empty }
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
let text    = { label in token(.StringLiteral, label) => { t in t.text } }
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
        || §"COUNTER" *> %"counter" + ((op("=") *> number("initial count")) || succeed(0))
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
// TODO: Swap NOT with context IN
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
//        || fail("Expected modifier action")

let modifier =
        ((§"IN" *> nofail(modifier_target)) || succeed(ModifierTarget(.This) ))
            + modifier_action => { mod in Modifier(target: mod.0, action: mod.1) }

let control =
          option(§"TRAP" *> symbol_list(.Any))
        + option(§"NOTIFY" *> symbol_list(.Any))
        + optionFlag(§"HALT")
        => { ast in (traps: ast.0.0, notifications: ast.0.1, doesHalt: ast.1) }

// WHERE something DO something
// WHERE something ON somethin else DO something
// ((selector, selector?), [modifier])
let actuator =
    ((§"WHERE" *> selector) + option(§"ON" *> selector))
        + nofail(§"DO" *> (some(modifier) + control))
    => { ast in Actuator(selector: ast.0.0,
                         combinedSelector:ast.0.1,
                         modifiers:ast.1.0,
                         traps: ast.1.1.traps,
                         notifications: ast.1.1.notifications,
                         doesHalt: ast.1.1.doesHalt) }

// Probes
// ========================================================================

// PROBE foo

let counter_agg_function =
           §"SUM"      *> succeed(AggregateFunction.Sum)
        || §"MIN"      *> succeed(AggregateFunction.Min)
        || §"MAX"      *> succeed(AggregateFunction.Max)

let aggregate =
           §"COUNT" *> op("(") *> option(tag_list) <* op(")")        => { tags in AggregateFunction.Count(tags ?? []) }
        || counter_agg_function + (op("(") *> %"counter" <* op(")")) => { $0($1) }

let measure = §"MEASURE" *> %"measure" + aggregate + (§"WHERE" *> (predicate ... §"AND"))
//    => { Measure(name: $0.1, type: $0.2) }


// World
// ========================================================================

let initializer =
	   %"symbol" + (op(":") *> number("counter value")) => Initializer.Counter
	|| %"symbol"                                        => Initializer.Tag 


let initializers =
	op("(") *> (initializer ... op(",")) <* op(")") 


let instance =
    ((%"symbol" + option(initializers)) +
    (
           op("*")  *> number("instance count") => ASTInstanceType.Counted
        || §"AS"    *> %"name"                  => ASTInstanceType.Named
        ||                                         succeed(ASTInstanceType.Default)
    ))
    => { i in createInstance(i.0.0, initializers: i.0.1, type: i.1) }


let binding =
    %"obj" + (op(".") *> %"slot") + (§"TO" *> %"target")
        => { spec in Binding(source:spec.0.0, sourceSlot:spec.0.1, target:spec.1)}


let graph_member =
           §"OBJECT" *> (instance ... op(",")) => GraphMember.InstanceMember
        || §"BIND"   *> (binding ... op(","))  => GraphMember.BindingMember


let world =
        (§"WORLD" *> %"name") + (option(§"ROOT" *> %"symbol") + (many(graph_member) => createGraph))
            => { x in World(name: x.0, graph: x.1.1, root: x.1.0) }


let data =
        (§"DATA" *> tag_list) + text("data string")


// Model
// ========================================================================

let model_object =
           concept  => ModelObject.ConceptModel
        || actuator => ModelObject.ActuatorModel
        || world    => ModelObject.WorldModel
        || data     => ModelObject.DataModel
        || fail("Expected model object")

let _model =
		   token(.Empty, "end (no model)") => { _ in createModel([]) }
		|| many(model_object) <* token(.Empty, "end") => createModel

let model =
		many(model_object) => createModel


// REPL
// ========================================================================

// SHOW CONCEPT x
// SHOW ACTUATORS
