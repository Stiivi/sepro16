/// Describes initial contents of a simulation.
///
public struct World {
    public var name: Symbol
    /// Contents
    public var graph: InstanceGraph
    /// Root object – referenced to as `ROOT`.
    public var root: Symbol? = nil

    public init(name: Symbol, graph: InstanceGraph, root: Symbol?=nil) {
        self.name = name
        self.graph = graph
        self.root = root
    }

    public func asString() -> String {
        var out = ""

        out += "WORLD \(name)"
        if self.root != nil {
            out += " ROOT \(root)"
        }
        out += "\n"
        out += graph.asString()

        return out
    }

}

/// Structure of concepts. Describes concept instances forming a linked structure.
///
public struct Struct {
    public var name: Symbol
    public let graph: InstanceGraph
    /// Names of outlets – instances from the graph that are exposed
    public let outlets: [PropertyReference:Symbol]

    /// Creates a concept structure.
    ///
    /// - Parameters:
    ///     - name: Structure name
    ///     - contents: Graph contents
    ///     - outlets: Named objects to be exposed to the outside
    ///
    public init(name: Symbol, graph: InstanceGraph, outlets: [PropertyReference:Symbol]?=nil) {
        self.name = name
        self.outlets = outlets ?? Dictionary<PropertyReference,Symbol>()
        self.graph = graph
    }

}

