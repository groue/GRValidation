//
//  ValidationPlan.swift
//  Validation
//
//  Created by Gwendal Roué on 21/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

/**
A Navigation Plan helps validating a Validable value as a whole.

It is able to gather many validation errors and turn them into a single one:

Compare:

    struct Person : Validable {
        let name: String?
        let age: Int?
        var phoneNumber: String?
        
        // This method stops after the first validation error:
        func validate1() throws {
            try validate(name, forName: "name", with: ValidationStringNotEmpty())
            try validate(age, forName: "age", with: ValidationRange(minimum: 0))
            try validate(phoneNumber, forName: "phoneNumber", with: PhoneNumberValidation())
        }

        // This method is able to return all validation errors found in Person.
        func validate2() throws {
            try ValidationPlan()
                .append { try validate(name, forName: "name", with: ValidationStringNotEmpty()) }
                .append { try validate(age, forName: "age", with: ValidationRange(minimum: 0)) }
                .append { try validate(phoneNumber, forName: "phoneNumber", with: PhoneNumberValidation()) }
                .validate()
        }
    }
*/
public class ValidationPlan {
    private var validationErrors = [ValidationError]()
    
    public init() { }
    
    public func append(@noescape block: () throws -> ()) -> ValidationPlan {
        do {
            try block()
        } catch let error as ValidationError {
            validationErrors.append(error)
        } catch {
            // TODO: should store and rethrow in validate()
            fatalError("Not a Validation error: \(error)")
        }
        return self
    }
    
    public func validate() throws {
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
