//
//  Validable.swift
//  Validation
//
//  Created by Gwendal Roué on 21/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

public protocol Validable {}

extension Validable {
    public func validate<TestedType, Validation: ValidationType where Validation.TestedType == TestedType>(value: TestedType, forName name: String, with validation: Validation) throws -> Validation.ValidType {
        return try validation.named(name).owned(self).validate(value)
    }
}

public struct ValidationPlan {
    var validationBlocks: [() throws -> ()] = []
    public init() { }
    public mutating func add(block: () throws -> ()) {
        validationBlocks.append(block)
    }
    public func validate() throws {
        var validationErrors = [ValidationError]()
        for block in validationBlocks {
            do {
                try block()
            } catch let error as ValidationError {
                validationErrors.append(error)
            }
        }
        switch validationErrors.count {
        case 0:
            break
        case 1:
            throw validationErrors.first!
        default:
            throw ValidationError.Multiple(validationErrors)
        }
    }
}
