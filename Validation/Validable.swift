//
//  Validable.swift
//  Validation
//
//  Created by Gwendal Roué on 21/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

/// A protocol for validation of complex values
public protocol Validable {}

extension Validable {
    /**
    Validates a property:
    
        struct Person : Validable {
            let name: String?
    
            func validate() throws {
                try validate(name, forName: "name", with: ValidationNotNil())
            }
        }
    */
    public func validateProperty<V: ValidationType where V.TestedType == Void>(name: String, with validation: V) throws -> V.ValidType {
        return try validation.named(name).owned(self).validate()
    }
    
    /**
    Validates globally:
    
        struct Person : Validable {
            let firstName: String?
            let lastName: String?
    
            func validate() throws {
                try validate(
                    "First and last name can't be both empty.",
                    with: (firstName >>> ValidationStringNotEmpty() || lastName >>> ValidationStringNotEmpty()))
            }
        }
    */
    public func validate<V: ValidationType where V.TestedType == Void>(description: String, with validation: V) throws {
        try validation.global(description).owned(self).validate()
    }
}
