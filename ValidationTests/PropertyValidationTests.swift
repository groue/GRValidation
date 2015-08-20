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
        let v = AnyValidation { (model: Model) in return model }
            >>> ((AnyValidation { $0.name } >>> ValidationNotNil() >>> ValidationStringNotEmpty())
                && (AnyValidation { $0.age } >>> ValidationNotNil() >>> ValidationGreaterThanOrEqual(0))
                && (AnyValidation { $0.magicWord }
                    >>> ValidationNotNil<String>()
                    >>> (ValidationRegularExpression(pattern: "foo")
                        && ValidationRegularExpression(pattern: "bar")))
        )
        try v.validate(self)
    }
    
//    static let nameValidation = ValidationNotNil<String>() >>> ValidationStringNotEmpty()
//    static let ageValidation = ValidationNotNil<Int>() >>> ValidationGreaterThanOrEqual(0)
//    static let magicWordValidation = ValidationNotNil<String>() >>> (ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar"))
    //    func validate() throws {
    //        try Model.nameValidation.validate(name)
    //        try Model.ageValidation.validate(age)
    //        try Model.magicWordValidation.validate(magicWord)
    //    }
    
//    func validationPlan() -> ValidationPlan {
//        var plan = ValidationPlan()
//        plan.addValidation(
//            "name",
//            value: name,
//            validation: ValidationNotNil<String>() >>> ValidationStringNotEmpty())
//        plan.addValidation(
//            "age",
//            value: age,
//            validation: ValidationNotNil<Int>() >>> ValidationGreaterThanOrEqual(0))
//        plan.addValidation(
//            "magicWord",
//            value: magicWord,
//            validation: ValidationNotNil<String>() >>> (ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar")))
//        return plan
//    }
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
        // TODO: avoid duplicated error descriptions ("qux" is invalid.)
        assertValidationError("\"\" should not be empty. -12 should be greater or equal to 0. \"qux\" is invalid. \"qux\" is invalid.") {
            try model.validate()
        }
    }
}
