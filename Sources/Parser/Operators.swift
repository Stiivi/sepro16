// String comparable

import ParserCombinator
import Model

public prefix func §(value: String) -> Parser<Token, String>{
    return keyword(value)
}

public prefix func %(value: String) -> Parser<Token, Symbol>{
    return symbol(value)
}

infix operator ... : BindPrecedence
public func ...<T, A, B>(p: Parser<T,A>, sep:Parser<T,B>) -> Parser<T,[A]> {
    return separated(p, sep)
}
