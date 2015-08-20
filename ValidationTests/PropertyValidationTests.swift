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
    
    static let nameValidation = ValidationNotNil<String>() >>> ValidationStringNotEmpty()
    static let ageValidation = ValidationNotNil<Int>() >>> ValidationGreaterThanOrEqual(0)
    static let magicWordValidation = ValidationNotNil<String>() >>> (ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar"))
    func validate() throws {
        try Model.nameValidation.validate(name)
        try Model.ageValidation.validate(age)
        try Model.magicWordValidation.validate(magicWord)
    }
}

class PropertyValidationTests: XCTestCase {
}
