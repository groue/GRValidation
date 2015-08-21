//
//  ValidationError.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

/**
A Validation Error
*/
indirect public enum ValidationError : ErrorType {
    
    public enum CompoundMode {
        case And
        case Or
    }
    
    /// Error on a value
    case Value(value: Any?, message: String)
    
    /// Error on a named value
    case Named(name: String, error: ValidationError)
    
    /// Compound errors
    case Compound(mode: CompoundMode, errors: [ValidationError])
    
    /// Error with custom description
    case Global(description: String, error: ValidationError)
    
    /// Owned error
    case Owned(owner: Any, error: ValidationError)
}

extension ValidationError : CustomStringConvertible {
    public var description: String {
        return description(nil)
    }
    
    private func description(valueDescription: String?) -> String {
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
        case .Compound(let mode, let errors):
            switch mode {
            case .Or:
                return errors.last!.description(valueDescription)
            case .And:
                // Avoid duplicated descriptions
                var found = Set<String>()
                var uniq = [String]()
                for error in errors {
                    let description = error.description(valueDescription)
                    if !found.contains(description) {
                        uniq.append(description)
                        found.insert(description)
                    }
                }
                return " ".join(uniq)
            }
        case .Global(let description, _):
            return description
        case .Owned(let owner, let error):
            return "\(owner.dynamicType) validation error: \(error.description(valueDescription))"
        }
    }
}
