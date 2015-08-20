//
//  ValidationError.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

public struct ValidationError : ErrorType {
    public enum Type {
        case Value(value: Any?, message: String)
        case Multiple([ValidationError])
    }
    public let type: Type
    
    public init(value: Any?, message: String) {
        self.type = .Value(value: value, message: message)
    }
    
    public init(children: [ValidationError]) {
        self.type = .Multiple(children)
    }
}

extension ValidationError : CustomStringConvertible {
    public var description: String {
        switch type {
        case .Value(let value, let message):
            if let value = value {
                return "\(String(reflecting: value)) \(message)"
            } else {
                return "\(String(reflecting: value)) \(message)"
            }
        case .Multiple(let children):
            return " ".join(children.map { $0.description })
        }
    }
}
