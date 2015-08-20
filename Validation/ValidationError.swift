//
//  ValidationError.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

indirect public enum ValidationError : ErrorType {
    case Value(value: Any?, message: String)
    case Property(owner: Any?, propertyName: String, error: ValidationError)
    case Global(owner: Any?, description: String, error: ValidationError)
    case Multiple([ValidationError])
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
        case .Property(_, let propertyName, let error):
            let valueDescription = valueDescription ?? propertyName
            return error.description(valueDescription)
        case .Global(_, let description, _):
            return description
        case .Multiple(let children):
            return " ".join(children.map { $0.description(valueDescription) })
        }
    }
}
