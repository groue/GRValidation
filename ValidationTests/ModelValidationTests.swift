//
// GRValidation
// https://github.com/groue/GRValidation
// Copyright (c) 2015 Gwendal Roué
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


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
        try validate(property: "name", with: name >>> ValidationNotNil())
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
                .append { try validate(property: "name", with: name >>> ValidationStringLength(minimum: 1)) }
                .append { try validate(property: "age", with: age >>> ValidationRange(minimum: 0)) }
                .append { phoneNumber = try validate(property: "phoneNumber", with: phoneNumber >>> ValidationPhoneNumber(format: .International)) }
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
            .append { try validate(property: "name", with: name >>> ValidationStringLength(minimum: 1)) }
            .append { try validate(property: "age", with: age >>> ValidationRange(minimum: 0)) }
            .append { try validate(property: "magicWord", with: magicWord >>> (ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar"))) }
            .append { try validate(property: "cardNumber", with: cardNumber >>> (ValidationNil<String>() || ValidationStringLength(minimum: 10))) }
            .append { try validate(message: "Value1 or Value2 must be not nil.", with: (value1 >>> ValidationNotNil() || value2 >>> ValidationNotNil())) }
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
                name = try validate(
                    property: "name",
                    with: name >>> nameValidation)
            }
            .append {
                // Age should be nil, or positive:
                let ageValidation = ValidationNil() || ValidationRange(minimum: 0)
                try validate(
                    property: "age",
                    with: age >>> ageValidation)
            }
            .append {
                // Email should be nil, or contain @ after whitespace trimming:
                let emailValidation = ValidationNil() || (ValidationTrim() >>> ValidationRegularExpression(pattern:"@"))
                email = try validate(
                    property: "email",
                    with: email >>> emailValidation)
            }
            .append {
                // Phone number should be nil, or be a valid phone number.
                // ValidationPhoneNumber applies international formatting.
                let phoneNumberValidation = ValidationNil() || (ValidationTrim() >>> ValidationPhoneNumber(format: .International))
                phoneNumber = try validate(
                    property: "phoneNumber",
                    with: phoneNumber >>> phoneNumberValidation)
            }
            .append {
                // An email or a phone number is required.
                try validate(
                    properties: ["email", "phoneNumber"],
                    message: "Please provide an email or a phone number.",
                    with: email >>> ValidationNotNil() || phoneNumber >>> ValidationNotNil())
            }
            .validate()
    }
}

class ModelValidationTests: ValidationTestCase {
    
    func testSimpleModel() {
        assertNoError {
            let model = SimpleModel(name: "Arthur")
            try model.validate()
        }
        assertNoError {
            let model = SimpleModel(name: nil)
            do {
                try model.validate()
            } catch let error as ValidationError {
                let modelDescription = String(reflecting: model)
                XCTAssertEqual(error.description, "Invalid \(modelDescription): name should not be nil.")
                let nameMessages = error.errorsFor(propertyName: "name").map { $0.description }.sort()
                XCTAssertEqual(nameMessages, ["Invalid \(modelDescription): name should not be nil."])
            }
        }
    }
    
    func testIntermediateModel() {
        assertNoError {
            var model = IntermediateModel(name:"Arthur", age: 12, phoneNumber: "1 23 45 67 89")
            try model.validate()
            XCTAssertEqual(model.phoneNumber!, "+33 1 23 45 67 89")
        }
        assertNoError {
            var model = IntermediateModel(name:nil, age: 12, phoneNumber: "1 23 45 67 89")
            do {
                try model.validate()
            } catch let error as ValidationError {
                let modelDescription = String(reflecting: model)
                
                // Test full error description
                XCTAssertEqual(error.description, "Invalid \(modelDescription): name should not be empty.")
                
                // Test property errors
                let nameMessages = error.errorsFor(propertyName: "name").map { $0.description }.sort()
                XCTAssertEqual(nameMessages, ["Invalid \(modelDescription): name should not be empty."])
                
                // Test repaired properties
                XCTAssertEqual(model.phoneNumber!, "+33 1 23 45 67 89")
            }
        }
        assertNoError {
            var model = IntermediateModel(name:"Arthur", age: nil, phoneNumber: "1 23 45 67 89")
            do {
                try model.validate()
            } catch let error as ValidationError {
                let modelDescription = String(reflecting: model)
                
                // Test full error description
                XCTAssertEqual(error.description, "Invalid \(modelDescription): age should be greater than or equal to 0.")
                
                // Test property errors
                let ageMessages = error.errorsFor(propertyName: "age").map { $0.description }.sort()
                XCTAssertEqual(ageMessages, ["Invalid \(modelDescription): age should be greater than or equal to 0."])
                
                // Test repaired properties
                XCTAssertEqual(model.phoneNumber!, "+33 1 23 45 67 89")
            }
        }
        assertNoError {
            var model = IntermediateModel(name:nil, age: nil, phoneNumber: nil)
            do {
                try model.validate()
            } catch let error as ValidationError {
                let modelDescription = String(reflecting: model)
                
                // Test full error description
                XCTAssertEqual(error.description, "Invalid \(modelDescription): name should not be empty. Invalid \(modelDescription): age should be greater than or equal to 0. Invalid \(modelDescription): phoneNumber should not be nil.")
                
                // Test property errors
                let nameMessages = error.errorsFor(propertyName: "name").map { $0.description }.sort()
                XCTAssertEqual(nameMessages, ["Invalid \(modelDescription): name should not be empty."])
                let ageMessages = error.errorsFor(propertyName: "age").map { $0.description }.sort()
                XCTAssertEqual(ageMessages, ["Invalid \(modelDescription): age should be greater than or equal to 0."])
                let phoneNumberMessages = error.errorsFor(propertyName: "phoneNumber").map { $0.description }.sort()
                XCTAssertEqual(phoneNumberMessages, ["Invalid \(modelDescription): phoneNumber should not be nil."])
            }
        }
    }
    
    func testComplexModel() {
        assertNoError {
            let model = ComplexModel(name: "Arthur", age: 12, magicWord: "foobar", cardNumber: nil, value1: 1, value2: nil)
            try model.validate()
        }
        assertNoError {
            let model = ComplexModel(name: "Arthur", age: 12, magicWord: "fooquxbar", cardNumber: "1234567890", value1: nil, value2: 2)
            try model.validate()
        }
        assertNoError {
            let model = ComplexModel(name: "", age: -12, magicWord: "qux", cardNumber: "123", value1: nil, value2: nil)
            do {
                try model.validate()
            } catch let error as ValidationError {
                let modelDescription = String(reflecting: model)
                
                // Test full error description
                XCTAssertEqual(error.description, "Invalid \(modelDescription): name should not be empty. Invalid \(modelDescription): age should be greater than or equal to 0. Invalid \(modelDescription): magicWord is invalid. Invalid \(modelDescription): cardNumber should contain at least 10 characters. Invalid \(modelDescription): Value1 or Value2 must be not nil.")
                
                // Test property errors
                let nameMessages = error.errorsFor(propertyName: "name").map { $0.description }.sort()
                XCTAssertEqual(nameMessages, ["Invalid \(modelDescription): name should not be empty."])
                let ageMessages = error.errorsFor(propertyName: "age").map { $0.description }.sort()
                XCTAssertEqual(ageMessages, ["Invalid \(modelDescription): age should be greater than or equal to 0."])
                let magicWordMessages = error.errorsFor(propertyName: "magicWord").map { $0.description }.sort()
                XCTAssertEqual(magicWordMessages, ["Invalid \(modelDescription): magicWord is invalid."])
                let cardNumberMessages = error.errorsFor(propertyName: "cardNumber").map { $0.description }.sort()
                XCTAssertEqual(cardNumberMessages, ["Invalid \(modelDescription): cardNumber should contain at least 10 characters."])
                // TODO: fetch and test global error "Value1 or Value2 must be not nil."
            }
        }
    }
    
    func testPerson() {
        assertNoError() {
            var person = Person(name: " Arthur ", age: 35, email: nil, phoneNumber: " 1 23 45 67 89 ")
            try person.validate()
            XCTAssertEqual(person.name!, "Arthur")
            XCTAssertEqual(person.phoneNumber!, "+33 1 23 45 67 89")
        }
        assertNoError {
            var person = Person(name: nil, age: nil, email: "foo@bar.com", phoneNumber: nil)
            do {
                try person.validate()
            } catch let error as ValidationError {
                let personDescription = String(reflecting: person)
                
                // Test full error description
                XCTAssertEqual(error.description, "Invalid \(personDescription): name should not be empty.")
                
                // Test property errors
                let nameMessages = error.errorsFor(propertyName: "name").map { $0.description }.sort()
                XCTAssertEqual(nameMessages, ["Invalid \(personDescription): name should not be empty."])
            }
        }
        assertNoError {
            var person = Person(name: "Arthur", age: -1, email: "foo@bar.com", phoneNumber: nil)
            do {
                try person.validate()
            } catch let error as ValidationError {
                let personDescription = String(reflecting: person)
                
                // Test full error description
                XCTAssertEqual(error.description, "Invalid \(personDescription): age should be greater than or equal to 0.")
                
                // Test property errors
                let ageMessages = error.errorsFor(propertyName: "age").map { $0.description }.sort()
                XCTAssertEqual(ageMessages, ["Invalid \(personDescription): age should be greater than or equal to 0."])
            }
        }
        assertNoError {
            var person = Person(name: "Arthur", age: 35, email: "foo", phoneNumber: nil)
            do {
                try person.validate()
            } catch let error as ValidationError {
                let personDescription = String(reflecting: person)
                
                // Test full error description
                XCTAssertEqual(error.description, "Invalid \(personDescription): email is invalid.")
                
                // Test property errors
                let emailMessages = error.errorsFor(propertyName: "email").map { $0.description }.sort()
                XCTAssertEqual(emailMessages, ["Invalid \(personDescription): email is invalid."])
            }
        }
        assertNoError {
            var person = Person(name: "Arthur", age: 35, email: nil, phoneNumber: nil)
            do {
                try person.validate()
            } catch let error as ValidationError {
                let personDescription = String(reflecting: person)
                
                // Test full error description
                XCTAssertEqual(error.description, "Invalid \(personDescription): Please provide an email or a phone number.")
                
                // TODO: fetch and test global error "Please provide an email or a phone number."
            }
        }
        assertNoError {
            var person = Person(name: nil, age: nil, email: nil, phoneNumber: nil)
            do {
                try person.validate()
            } catch let error as ValidationError {
                let personDescription = String(reflecting: person)
                
                // Test full error description
                XCTAssertEqual(error.description, "Invalid \(personDescription): name should not be empty. Invalid \(personDescription): Please provide an email or a phone number.")
                
                // Test property errors
                let nameMessages = error.errorsFor(propertyName: "name").map { $0.description }.sort()
                XCTAssertEqual(nameMessages, ["Invalid \(personDescription): name should not be empty."])
                
                // TODO: fetch and test global error "Please provide an email or a phone number."
            }
        }
    }
}
