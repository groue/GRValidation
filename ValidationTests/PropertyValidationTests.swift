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
struct ValidationPhoneNumber : ValidationType {
    enum Format {
        case International
    }
    init(format: Format) { }
    func validate(string: String?) throws -> String {
        let string = try validateNotNil(string)
        return "+33 \(string)"
    }
}

struct SimpleModel : Validable {
    let name: String?
    
    func validate() throws {
        // OK: error is named, and owned.
        try validateProperty("name", with: name >>> ValidationNotNil())
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
                .append { try validateProperty("name", with: name >>> ValidationStringLength(minimum: 1)) }
                .append { try validateProperty("age", with: age >>> ValidationRange(minimum: 0)) }
                .append { phoneNumber = try validateProperty("phoneNumber", with: phoneNumber >>> ValidationPhoneNumber(format: .International)) }
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
            .append { try validateProperty("name", with: name >>> ValidationStringLength(minimum: 1)) }
            .append { try validateProperty("age", with: age >>> ValidationRange(minimum: 0)) }
            .append { try validateProperty("magicWord", with: magicWord >>> (ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar"))) }
            .append { try validateProperty("cardNumber", with: cardNumber >>> (ValidationNil<String>() || ValidationStringLength(minimum: 10))) }
            // FIXME: the syntax is somewhat different than property validation.
            // Do we have to force the user to use the `||` operator?
            .append { try validate("Value1 or Value2 must be not nil.", with: (value1 >>> ValidationNotNil() || value2 >>> ValidationNotNil())) }
            .validate()
    }
}

struct Person : Validable {
    var name: String?
    var age: Int?
    var email: String?
    var phoneNumber: String?
    
    mutating func validate() throws {
        // ValidationPlan doesn't fail on the first validation error. Instead,
        // it gathers all of them, and eventually throws a single ValidationError.
        try ValidationPlan()
            .append {
                // Name should not be empty after whitespace trimming:
                let nameValidation = ValidationTrim() >>> ValidationStringLength(minimum: 1)
                name = try validateProperty(
                    "name",
                    with: name >>> nameValidation)
            }
            .append {
                // Age should be nil, or positive:
                let ageValidation = ValidationNil() || ValidationRange(minimum: 0)
                try validateProperty(
                    "age",
                    with: age >>> ageValidation)
            }
            .append {
                // Email should be nil, or contain @ after whitespace trimming:
                let emailValidation = ValidationNil() || (ValidationTrim() >>> ValidationRegularExpression(pattern:"@"))
                email = try validateProperty(
                    "email",
                    with: email >>> emailValidation)
            }
            .append {
                // Phone number should be nil, or be a valid phone number.
                // ValidationPhoneNumber applies international formatting.
                let phoneNumberValidation = ValidationNil() || (ValidationTrim() >>> ValidationPhoneNumber(format: .International))
                phoneNumber = try validateProperty(
                    "phoneNumber",
                    with: phoneNumber >>> phoneNumberValidation)
            }
            .append {
                // An email or a phone number is required.
                try validate(
                    "Please provide an email or a phone number.",
                    with: email >>> ValidationNotNil() || phoneNumber >>> ValidationNotNil())
            }
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
        assertValidationError("ComplexModel validation error: name should not be empty. ComplexModel validation error: age should be greater than or equal to 0. ComplexModel validation error: magicWord is invalid. ComplexModel validation error: cardNumber should contain at least 10 characters. ComplexModel validation error: Value1 or Value2 must be not nil.") {
            // TODO: test for ownership
            let model = ComplexModel(name: "", age: -12, magicWord: "qux", cardNumber: "123", value1: nil, value2: nil)
            try model.validate()
        }
    }
    
    func testPerson() {
        assertValid() {
            var person = Person(name: " Arthur ", age: 35, email: nil, phoneNumber: " 1 23 45 67 89 ")
            try person.validate()
            XCTAssertEqual(person.name!, "Arthur")
            XCTAssertEqual(person.phoneNumber!, "+33 1 23 45 67 89")
        }
        assertValidationError("Person validation error: name should not be empty.") {
            var person = Person(name: nil, age: nil, email: "foo@bar.com", phoneNumber: nil)
            try person.validate()
        }
        assertValidationError("Person validation error: age should be greater than or equal to 0.") {
            var person = Person(name: "Arthur", age: -1, email: "foo@bar.com", phoneNumber: nil)
            try person.validate()
        }
        assertValidationError("Person validation error: Please provide an email or a phone number.") {
            var person = Person(name: "Arthur", age: 35, email: nil, phoneNumber: nil)
            try person.validate()
        }
        assertValidationError("Person validation error: email is invalid.") {
            var person = Person(name: "Arthur", age: 35, email: "foo", phoneNumber: nil)
            try person.validate()
        }
        assertValidationError("Person validation error: name should not be empty. Person validation error: Please provide an email or a phone number.") {
            var person = Person(name: nil, age: nil, email: nil, phoneNumber: nil)
            try person.validate()
        }
    }
}
