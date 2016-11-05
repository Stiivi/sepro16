// Symbol
//


public typealias Symbol = String
public typealias SymbolList = [Symbol]

public enum SymbolType: CustomStringConvertible {
    case `any`
    case tag
    case slot
    case counter
    case concept
    case world
    case `struct`
    case notification
    case trap

    public var description: String {
        switch self {
        case .any: return "any"
        case .tag: return "tag"
        case .slot: return "slot"
        case .counter: return "counter"
        case .concept: return "concept"

        case .world: return "world"
        case .`struct`: return "struct"
        case .notification: return "notification"
        case .trap: return "trap"
        }
    }
}


struct SymbolInfo {
    let name: String
    let type: SymbolType
    let comment: String?

    init(name: String, type: SymbolType, comment: String?=nil) {
        self.name = name
        self.type = type
        self.comment = comment
    }  

    var fullyQualifiedName: String {
        return ""
    }

}
