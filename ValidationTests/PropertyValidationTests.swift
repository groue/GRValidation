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
            try ValidationPlan()
                .append { try validate(name, forName: "name", with: ValidationStringNotEmpty()) }
                .append { try validate(age, forName: "age", with: ValidationRange(minimum: 0)) }
                .append { phoneNumber = try validate(phoneNumber, forName: "phoneNumber", with: PhoneNumberValidation()) }
                .validate()
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
        try ValidationPlan()
            .append { try validate(name, forName: "name", with: ValidationStringNotEmpty()) }
            .append { try validate(age, forName: "age", with: ValidationRange(minimum: 0)) }
            .append { try validate(magicWord, forName: "magicWord", with: ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar")) }
            // TODO: the error description contains "cardNumber should be nil. cardNumber should contain at least 10 characters." which is confusing.
            .append { try validate(cardNumber, forName: "cardNumber", with: ValidationNil<String>() || ValidationStringLength(minimum: 10)) }
            // FIXME: the syntax is somewhat different than property validation.
            // Do we have to force the user to use the `||` operator?
            .append { try validate("Value1 or Value2 must be not nil.", with: (value1 >>> ValidationNotNil() || value2 >>> ValidationNotNil())) }
            .validate()
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
        assertValidationError("IntermediateModel validation error: name should not be empty.", owned: true) {
            var model = IntermediateModel(name:nil, age: 12, phoneNumber: "1 23 45 67 89")
            do {
                try model.validate()
            } catch {
                XCTAssertEqual(model.phoneNumber!, "+33 1 23 45 67 89")
                throw error
            }
        }
        assertValidationError("IntermediateModel validation error: age should be greater than or equal to 0.", owned: true) {
            var model = IntermediateModel(name:"Arthur", age: nil, phoneNumber: "1 23 45 67 89")
            do {
                try model.validate()
            } catch {
                XCTAssertEqual(model.phoneNumber!, "+33 1 23 45 67 89")
                throw error
            }
        }
        assertValidationError("IntermediateModel validation error: name should not be empty. IntermediateModel validation error: age should be greater than or equal to 0. IntermediateModel validation error: phoneNumber should not be nil.") {
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
        assertValidationError("ComplexModel validation error: name should not be empty. ComplexModel validation error: age should be greater than or equal to 0. ComplexModel validation error: magicWord is invalid. ComplexModel validation error: cardNumber should be nil. cardNumber should contain at least 10 characters. ComplexModel validation error: Value1 or Value2 must be not nil.") {
            // TODO: test for ownership
            let model = ComplexModel(name: "", age: -12, magicWord: "qux", cardNumber: "123", value1: nil, value2: nil)
            try model.validate()
        }
    }
}
