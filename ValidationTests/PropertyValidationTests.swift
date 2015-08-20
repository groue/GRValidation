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
    
    func validate() throws {
        let v = Validation<Model>()
            >>> (
                    // TODO: $0.name is too far away from forPropertyName("name")
                   ({ $0.name }
                    >>> ValidationNotNil()
                    >>> ValidationStringNotEmpty()).forPropertyName("name")
                && ({ $0.age }
                    >>> ValidationNotNil()
                    >>> ValidationGreaterThanOrEqual(0)).forPropertyName("age")
                && ({ $0.magicWord }
                    >>> ValidationNotNil<String>()
                    >>> (ValidationRegularExpression(pattern: "foo")
                         && ValidationRegularExpression(pattern: "bar"))).forPropertyName("magicWord"))
        try v.validate(self)
    }
}

//struct ValidationPlan {
//    var validationBlocks: [() -> ValidationError?] = []
//    mutating func addValidation<T, V : Validation where V.TestedType == T>(propertyName: String, value: T, validation: V) {
//        validationBlocks.append {
//            do {
//                try validation.validate(value)
//                return nil
//            } catch let error as ValidationError {
//                return ValidationError(propertyName: propertyName, error: error)
//            } catch {
//                fatalError("Not a validation error: \(error)")
//            }
//        }
//    }
//
//    func run() throws {
//        let validationErrors = validationBlocks.map { $0() }.flatMap { $0 }
//        switch validationErrors.count {
//        case 0:
//            return
//        case 1:
//            throw validationErrors.first!
//        default:
//            throw ValidationError(children: validationErrors)
//        }
//    }
//}

class PropertyValidationTests: ValidationTestCase {
    
    func testValidModel() {
        let model = Model(name: "Arthur", age: 12, magicWord: "foobar")
        assertNoError {
            try model.validate()
        }
    }
    
    func testInvalidModel() {
        let model = Model(name: "", age: -12, magicWord: "qux")
        // TODO: avoid duplicated error descriptions (magicWord is invalid.)
        assertValidationError("name should not be empty. age should be greater or equal to 0. magicWord is invalid. magicWord is invalid.") {
            try model.validate()
        }
    }
}
