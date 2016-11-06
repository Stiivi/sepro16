// Note: we are using underscode instead of camelCase for gramar rules
// to maintain consistency with common practice in BNF

import ParserCombinator
import Model

extension Token: EmptyCheckable {
    public static let EmptyValue = Token(.empty, "")
    public var isEmpty: Bool { return self.kind == TokenKind.empty }
}

// Terminals
// =======================================================================

func token(_ kind: TokenKind, _ expected: String) -> Parser<Token, Token> {
    return satisfy(expected) { token in token == kind }
}

func tokenValue(_ kind: TokenKind, _ value: String) -> Parser<Token, Token> {
    return satisfy(value) { token in token == Token(kind, value) }
}

let symbol  = { name  in token(.identifier, name)  => { t in Symbol(describing:t.text) } }
let number  = { label in token(.intLiteral, label) => { t in Int(t.text)! } }
let text    = { label in token(.stringLiteral, label) => { t in t.text } }
let keyword = { kw    in tokenValue(.keyword, kw)  => { t in t.text } }
let op      = { o     in tokenValue(.operator, o) }

// TODO: This is just to type-hint the following rule. Otherwise Swift does not
// know that the `type` is of `SymbolType`
func typeDesc(_ type: SymbolType) -> String {
    return type.description
}

// Primitive Items
// =======================================================================

let symbol_list = { type in separated(symbol(typeDesc(type)), op(",")) }
let tag_list = symbol_list(.tag) => { ast in TagList(ast) }


// Concept
// =======================================================================

let concept_member  =
           §"TAG"     *> tag_list           => ObjectMember.tags
        || §"SLOT"    *> symbol_list(.slot) => ObjectMember.slots
        || §"COUNTER" *> %"counter" + ((op("=") *> number("initial count")) || succeed(0))
                             => { (sym, count) in return ObjectMember.counter(sym, count)}


let concept =
        §"CONCEPT" *> (%"name" + many(concept_member)) => { makeConcept($0.0, $0.1) }


let predicate_type =
           §"SET"   *> tag_list         => PredicateType.tagSet
        || §"BOUND" *> %"slot"          => PredicateType.isBound
        || §"ZERO"  *> %"counter"       => PredicateType.counterZero
        ||             tag_list         => PredicateType.tagSet
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
               §"ALL"  *>                          succeed(Selector.all)
            ||            (predicate ... §"AND")   => Selector.filter


// Modifier
// ------------------------------------------------------------------------

let target_type: Parser<Token, TargetType> =
           §"THIS"  *> succeed(TargetType.this)
        || §"OTHER" *> succeed(TargetType.other)

let modifier_target: Parser<Token, ModifierTarget> =
        target_type + option(op(".") *> %"slot") => { target in ModifierTarget(target.0, target.1) }
		|| %"slot"                               => { symbol in ModifierTarget(TargetType.this, symbol)}

let bind_target = modifier_target

let modifier_action =
           §"NOTHING" *>              succeed(ModifierAction.nothing)
        || §"SET"     *> tag_list     => ModifierAction.setTags
        || §"UNSET"   *> tag_list     => ModifierAction.unsetTags
        || §"INC"     *> %"counter"   => ModifierAction.inc
        || §"DEC"     *> %"counter"   => ModifierAction.dec
        || §"CLEAR"   *> %"counter"   => ModifierAction.clear
        || §"UNBIND"  *> %"slot"      => ModifierAction.unbind
        || §"BIND"    *> %"slot" + (§"TO" *> bind_target) => { ast in ModifierAction.bind(ast.0, ast.1)}
//        || fail("Expected modifier action")

let modifier: Parser<Token, Modifier> =
        ((§"IN" *> nofail(modifier_target)) || succeed(ModifierTarget(.this) ))
            + modifier_action => { mod in Modifier(target: mod.0, action: mod.1) }

let control =
          option(§"TRAP" *> symbol_list(.any))
        + option(§"NOTIFY" *> symbol_list(.any))
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
           §"SUM"      *> succeed(AggregateFunction.sum)
        || §"MIN"      *> succeed(AggregateFunction.min)
        || §"MAX"      *> succeed(AggregateFunction.max)

let aggregate =
           §"COUNT" *> op("(") *> option(tag_list) <* op(")")        => { tags in AggregateFunction.count(tags ?? []) }
        || counter_agg_function + (op("(") *> %"counter" <* op(")")) => { $0($1) }

let measure = §"MEASURE" *> %"measure" + aggregate + (§"WHERE" *> (predicate ... §"AND"))
//    => { Measure(name: $0.1, type: $0.2) }


// World
// ========================================================================

let initializer =
	   %"symbol" + (op(":") *> number("counter value")) => Initializer.counter
	|| %"symbol"                                        => Initializer.tag 


let initializers =
	op("(") *> (initializer ... op(",")) <* op(")") 


let instance =
    ((%"symbol" + option(initializers)) +
    (
           op("*")  *> number("instance count") => ASTInstanceType.counted
        || §"AS"    *> %"name"                  => ASTInstanceType.named
        ||                                         succeed(ASTInstanceType.default)
    ))
    => { i in createInstance(i.0.0, initializers: i.0.1, type: i.1) }


let binding =
    %"obj" + (op(".") *> %"slot") + (§"TO" *> %"target")
        => { spec in Binding(source:spec.0.0, sourceSlot:spec.0.1, target:spec.1)}


let graph_member =
           §"OBJECT" *> (instance ... op(",")) => GraphMember.instanceMember
        || §"BIND"   *> (binding ... op(","))  => GraphMember.bindingMember


let world =
        (§"WORLD" *> %"name") + ((many(graph_member) => createGraph))
            => { x in World(name: x.0, graph: x.1) }


let data =
        (§"DATA" *> tag_list) + text("data string")


// Model
// ========================================================================

let model_object =
           concept  => ModelObject.conceptModel
        || actuator => ModelObject.actuatorModel
        || world    => ModelObject.worldModel
        || data     => ModelObject.dataModel
        || fail("Expected model object")

let _model =
		   token(.empty, "end (no model)") => { _ in createModel([]) }
		|| many(model_object) <* token(.empty, "end") => createModel

let model =
		many(model_object) => createModel


// REPL
// ========================================================================

// SHOW CONCEPT x
// SHOW ACTUATORS
