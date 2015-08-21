//
//  ValidationError.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

indirect public enum ValidationError : ErrorType {
    /// Error on a value
    case Value(value: Any?, message: String)
    
    /// Error on a named value
    case Named(name: String, error: ValidationError)
    
    /// Multiple errors
    case Multiple([ValidationError])
    
    /// Error with custom description
    case Global(description: String, error: ValidationError)
    
    /// Owned error
    case Owned(owner: Any, error: ValidationError)
}

extension ValidationError : CustomStringConvertible {
    public var description: String {
        return description(nil)
    }
    
    public func description(valueDescription: String?) -> String {
        switch self {
        case .Value(let value, let message):
            if let valueDescription = valueDescription {
                return "\(valueDescription) \(message)"
            } else if let value = value {
                return "\(String(reflecting: value)) \(message)"
            } else {
                return "nil \(message)"
            }
        case .Named(let name, let error):
            return error.description(name)
        case .Multiple(let children):
            return " ".join(children.map { $0.description(valueDescription) })
        case .Global(let description, _):
            return description
        case .Owned(_, let error):
            return error.description(valueDescription)
        }
    }
}
