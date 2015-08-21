//
//  PropertyValidationTests.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

import XCTest
import Validation

struct SimpleModel {
    let name: String?
    
    // TODO: this is not quite nice
    static let validation = PropertyValidation<SimpleModel>("name", { $0.name } >>> ValidationStringNotEmpty())
    
    func validate() throws {
        try SimpleModel.validation.validate(self)
    }
}

struct ComplexModel {
    let name: String?
    let age: Int?
    let magicWord: String?
    let cardNumber: String?
    let value1: Int?
    let value2: Int?
    
    // Name must not be empty
    static let nameValidation = ValidationStringNotEmpty()
    
    // Age >= 0
    static let ageValidation = ValidationRange(minimum: 0)
    
    // Card number must be nil, or, if present, contain at least 10 characters.
    // TODO: the error description contains "cardNumber should be nil. cardNumber should contain at least 10 characters." which is confusing.
    static let cardNumberValidation = ValidationNil<String>() || ValidationStringLength(minimum: 10)
    
    // MagicWord must contain "foo" and "bar".
    static let magicWordValidation = ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar")
    
    // ComplexModel validation
    static let validation = Validation<ComplexModel>() >>> (    // This line lets PropertyValidation avoid declaring <ComplexModel> on each PropertyValidation
        PropertyValidation("name", { $0.name } >>> nameValidation)
        && PropertyValidation("age", { $0.age } >>> ageValidation)
        && PropertyValidation("magicWord", { $0.magicWord } >>> magicWordValidation)
        && PropertyValidation("cardNumber", { $0.cardNumber } >>> cardNumberValidation)
        && GlobalValidation("Value1 or Value2 must be not nil.", { $0.value1 } >>> ValidationNotNil() || { $0.value2 } >>> ValidationNotNil()))
    
    func validate() throws {
        try ComplexModel.validation.validate(self)
    }
}

class PropertyValidationTests: ValidationTestCase {
    
    func testSimpleModel() {
        assertValid {
            let model = SimpleModel(name: "Arthur")
            try model.validate()
        }
        assertValidationError("name should not be nil.") {
            let model = SimpleModel(name: nil)
            try model.validate()
        }
        assertValidationError("name should not be empty.") {
            let model = SimpleModel(name: "")
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
        assertValidationError("name should not be empty. age should be greater or equal to 0. magicWord is invalid. magicWord is invalid. cardNumber should be nil. cardNumber should contain at least 10 characters. Value1 or Value2 must be not nil.") {
            let model = ComplexModel(name: "", age: -12, magicWord: "qux", cardNumber: "123", value1: nil, value2: nil)
            try model.validate()
        }
    }
}
