public enum Result<T, E> where E: Error {
    case success(T)
    case failure(E)

    public var isFailure: Bool {
        switch self {
        case .success: return false
        case .failure: return true
        }
    }

    public var value: T? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }

    public var error: E? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}



public enum ResultList<T, E> where E: Error {
    case success(T)
    case failure([E])

    public var isFailure: Bool {
        switch self {
        case .success: return false
        case .failure: return true
        }
    }

    public var value: T? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }

    public var errors: [E]? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}

