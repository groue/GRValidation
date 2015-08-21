//
//  PropertyValidationTests.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

import XCTest
import Validation

struct Model {
    let name: String?
    let age: Int?
    let magicWord: String?
    let cardNumber: String?
    let value1: Int?
    let value2: Int?
    
    func validate() throws {
        
        // Name must not be empty
        let nameValidation = ValidationStringNotEmpty()
        
        // Age >= 0
        let ageValidation = ValidationRange(minimum: 0)
        
        // Card number must be nil, or, if present, contain at least 10 characters.
        // TODO: the error description contains "cardNumber should be nil. cardNumber should contain at least 10 characters." which is confusing.
        let cardNumberValidation = ValidationNil<String>() || ValidationStringLength(minimum: 10)
        
        // MagicWord must contain "foo" and "bar".
        let magicWordValidation = ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar")
        
        // TODO: Global validation should be able to be written alone, while keeping hte code readable
        let value1Validation = ValidationNotNil<Int>()
        let value2Validation = ValidationNotNil<Int>()
        
        let v = Validation<Model>() >>> (
                PropertyValidation("name", { $0.name }, nameValidation)
                && PropertyValidation("age", { $0.age }, ageValidation)
                && PropertyValidation("magicWord", { $0.magicWord }, magicWordValidation)
                && PropertyValidation("cardNumber", { $0.cardNumber }, cardNumberValidation)
                && GlobalValidation("Value1 or Value2 must be not nil.",
                    PropertyValidation("value1", { $0.value1 }, value1Validation)
                    || PropertyValidation("value2", { $0.value2 }, value2Validation))
        )
        try v.validate(self)
    }
}

class PropertyValidationTests: ValidationTestCase {
    
    func testValidModel() {
        let model = Model(name: "Arthur", age: 12, magicWord: "foobar", cardNumber: nil, value1: 1, value2: nil)
        assertNoError {
            try model.validate()
        }
    }
    
    func testInvalidModel() {
        let model = Model(name: "", age: -12, magicWord: "qux", cardNumber: "123", value1: nil, value2: nil)
        // TODO: avoid duplicated error descriptions (magicWord is invalid.)
        assertValidationError("name should not be empty. age should be greater or equal to 0. magicWord is invalid. magicWord is invalid. cardNumber should be nil. cardNumber should contain at least 10 characters. Value1 or Value2 must be not nil.") {
            try model.validate()
        }
    }
}
