//
//  ValidationError.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

public struct ValidationError : ErrorType {
    public indirect enum Type {
        case Value(value: Any?, message: String)
        case Multiple([ValidationError])
        case Property(propertyName: String, error: ValidationError)
    }
    public let type: Type
    
    public init(value: Any?, message: String) {
        self.type = .Value(value: value, message: message)
    }
    
    public init(children: [ValidationError]) {
        self.type = .Multiple(children)
    }
    public init(propertyName: String, error: ValidationError) {
        self.type = .Property(propertyName: propertyName, error: error)
    }
}

extension ValidationError : CustomStringConvertible {
    public var description: String {
        return description(nil)
    }
    
    public func description(valueDescription: String?) -> String {
        switch type {
        case .Value(let value, let message):
            if let value = value {
                let valueDescription = valueDescription ?? String(reflecting: value)
                return "\(valueDescription) \(message)"
            } else {
                return "\(valueDescription) \(message)"
            }
        case .Multiple(let children):
            return " ".join(children.map { $0.description(valueDescription) })
        case .Property(let propertyName, let error):
            let valueDescription = valueDescription ?? propertyName
            return error.description(valueDescription)
        }
    }
}
