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
    let value1: Int?
    let value2: Int?
    
    func validate() throws {
        let nameValidation = ValidationNotNil<String>() >>> ValidationStringNotEmpty()
        let ageValidation = ValidationNotNil<Int>() >>> ValidationGreaterThanOrEqual(0)
        let magicWordValidation = ValidationNotNil<String>() >>> (ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar"))
        let value1Validation = ValidationNotNil<Int>()
        let value2Validation = ValidationNotNil<Int>()
        let v = Validation<Model>() >>> (
                PropertyValidation("name", { $0.name }, nameValidation)
                && PropertyValidation("age", { $0.age }, ageValidation)
                && PropertyValidation("magicWord", { $0.magicWord }, magicWordValidation)
                && GlobalValidation("Value1 or Value2 must be not nil.",
                    PropertyValidation("value1", { $0.value1 }, value1Validation)
                    || PropertyValidation("value2", { $0.value2 }, value2Validation))
        )
        try v.validate(self)
    }
}

class PropertyValidationTests: ValidationTestCase {
    
    func testValidModel() {
        let model = Model(name: "Arthur", age: 12, magicWord: "foobar", value1: 1, value2: nil)
        assertNoError {
            try model.validate()
        }
    }
    
    func testInvalidModel() {
        let model = Model(name: "", age: -12, magicWord: "qux", value1: nil, value2: nil)
        // TODO: avoid duplicated error descriptions (magicWord is invalid.)
        assertValidationError("name should not be empty. age should be greater or equal to 0. magicWord is invalid. magicWord is invalid. Value1 or Value2 must be not nil.") {
            try model.validate()
        }
    }
}
