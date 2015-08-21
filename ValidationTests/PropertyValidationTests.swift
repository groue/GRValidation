//
//  PropertyValidationTests.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

import XCTest
import Validation

// A validation that may transform its input.
struct PhoneNumberValidation : ValidationType {
    func validate(string: String?) throws -> String {
        let string = try validateNotNil(string)
        return "+33 \(string)"
    }
}

struct SimpleModel : Validable {
    let name: String?
    
    func validate() throws {
        // OK: error is named, and owned.
        try validate(name, forName: "name", with: ValidationNotNil())
    }
}

struct IntermediateModel : Validable {
    let name: String?
    let age: Int?
    var phoneNumber: String?
    
    mutating func validate() throws {
        do {
            // OK: readable enough
            // OK: phoneNumber is updated
            // OK: all errors are gathered in a single error
            // FIXME?: ValidationPlan does not adopt ValidationType. This is because we need to mutate self.phoneNumber, and ValidationType is not allowed to perform side effects on value types.
            var plan = ValidationPlan()
            plan.add { try self.validate(self.name, forName: "name", with: ValidationStringNotEmpty()) }
            plan.add { try self.validate(age, forName: "age", with: ValidationRange(minimum: 0)) }
            plan.add { self.phoneNumber = try self.validate(self.phoneNumber, forName: "phoneNumber", with: PhoneNumberValidation()) }
            try plan.validate()
        }
    }
}

struct ComplexModel : Validable {
    let name: String?
    let age: Int?
    let magicWord: String?
    let cardNumber: String?
    let value1: Int?
    let value2: Int?
    
    func validate() throws {
        var plan = ValidationPlan()
        
        // Name must not be empty
        plan.add { try self.validate(self.name, forName: "name", with: ValidationStringNotEmpty()) }
        
        // Age >= 0
        plan.add { try self.validate(self.age, forName: "age", with: ValidationRange(minimum: 0)) }
        
        // MagicWord must contain "foo" and "bar".
        plan.add { try self.validate(self.magicWord, forName: "magicWord", with: ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar")) }
        
        // Card number must be nil, or, if present, contain at least 10 characters.
        // TODO: the error description contains "cardNumber should be nil. cardNumber should contain at least 10 characters." which is confusing.
        plan.add { try self.validate(self.cardNumber, forName: "cardNumber", with: ValidationNil<String>() || ValidationStringLength(minimum: 10)) }
        
        plan.add {
            // FIXME: the syntax is radically different than property validation.
            // TODO: what about validating a tuple?
            let globalValidation = Validation<ComplexModel>() >>> GlobalValidation("Value1 or Value2 must be not nil.", { $0.value1 } >>> ValidationNotNil() || { $0.value2 } >>> ValidationNotNil())
            try globalValidation.validate(self)
        }
        
        try plan.validate()
    }
}

class PropertyValidationTests: ValidationTestCase {
    
    func testSimpleModel() {
        assertValid {
            let model = SimpleModel(name: "Arthur")
            try model.validate()
        }
        assertValidationError("SimpleModel validation error: name should not be nil.", owned: true) {
            let model = SimpleModel(name: nil)
            try model.validate()
        }
    }
    
    func testIntermediateModel() {
        assertValid {
            var model = IntermediateModel(name:"Arthur", age: 12, phoneNumber: "1 23 45 67 89")
            try model.validate()
            XCTAssertEqual(model.phoneNumber!, "+33 1 23 45 67 89")
        }
        assertValidationError("IntermediateModel validation error: name should not be nil.", owned: true) {
            var model = IntermediateModel(name:nil, age: 12, phoneNumber: "1 23 45 67 89")
            do {
                try model.validate()
            } catch {
                XCTAssertEqual(model.phoneNumber!, "+33 1 23 45 67 89")
                throw error
            }
        }
        assertValidationError("IntermediateModel validation error: age should not be nil.", owned: true) {
            var model = IntermediateModel(name:"Arthur", age: nil, phoneNumber: "1 23 45 67 89")
            do {
                try model.validate()
            } catch {
                XCTAssertEqual(model.phoneNumber!, "+33 1 23 45 67 89")
                throw error
            }
        }
        assertValidationError("IntermediateModel validation error: name should not be nil. IntermediateModel validation error: age should not be nil. IntermediateModel validation error: phoneNumber should not be nil.") {
            // TODO: test for ownership
            var model = IntermediateModel(name:nil, age: nil, phoneNumber: nil)
            try model.validate()
        }
    }
    
    func testComplexModel() {
        assertValid {
            let model = ComplexModel(name: "Arthur", age: 12, magicWord: "foobar", cardNumber: nil, value1: 1, value2: nil)
            try model.validate()
        }
        assertValid {
            let model = ComplexModel(name: "Arthur", age: 12, magicWord: "fooquxbar", cardNumber: "1234567890", value1: nil, value2: 2)
            try model.validate()
        }
        // TODO: avoid duplicated error descriptions (magicWord is invalid.)
        assertValidationError("ComplexModel validation error: name should not be empty. ComplexModel validation error: age should be greater than or equal to 0. ComplexModel validation error: magicWord is invalid. magicWord is invalid. ComplexModel validation error: cardNumber should be nil. cardNumber should contain at least 10 characters. ComplexModel validation error: Value1 or Value2 must be not nil.") {
            // TODO: test for ownership
            let model = ComplexModel(name: "", age: -12, magicWord: "qux", cardNumber: "123", value1: nil, value2: nil)
            try model.validate()
        }
    }
}
