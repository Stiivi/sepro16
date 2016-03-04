// Symbol
//


public typealias Symbol = String
public typealias SymbolList = [Symbol]

enum SymbolType: CustomStringConvertible {
    case Any
    case Tag
    case Slot
    case Counter
    case Concept
    case World
    case Struct
    case Notification
    case Trap

    var description: String {
        switch self {
        case .Any: return "any"
        case .Tag: return "tag"
        case .Slot: return "slot"
        case .Counter: return "counter"
        case .Concept: return "concept"

        case .World: return "world"
        case .Struct: return "struct"
        case .Notification: return "notification"
        case .Trap: return "trap"
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
