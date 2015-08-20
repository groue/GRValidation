//
//  ValidationTests.swift
//  ValidationTests
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

import XCTest
import Validation

enum ValidatedRawRepresentable: Int {
    case Zero
    case One
    case Two
}

class ValidationTests: ValidationTestCase {
    
    func testValidationSuccess() {
        let v = ValidationSuccess<Int>()
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
    }
    
    func testValidationFailure() {
        let v = ValidationFailure<Int>()
        assertValidationError("1 is invalid.") {
            try v.validate(1)
        }
    }
    
    func testValidationNotNil() {
        let v = ValidationNotNil<Int>()
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testValidationNotEmpty() {
        let v = ValidationNotEmpty<[Int]>()
        assertNoError() {
            let result = try v.validate([1,2,3])
            XCTAssertEqual(result, [1,2,3])
        }
        assertValidationError("[] should not be empty.") {
            try v.validate([])
        }
    }
    
    func testValidationStringNotEmpty() {
        let v = ValidationStringNotEmpty()
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValidationError("\"\" should not be empty.") {
            try v.validate("")
        }
    }
    
    func testValidationRawValue() {
        let v = ValidationRawValue<ValidatedRawRepresentable>()
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, ValidatedRawRepresentable.One)
        }
        assertValidationError("5 is invalid.") {
            try v.validate(5)
        }
    }
    
    func testValidationEqual() {
        let v = ValidationEqual(1)
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError("2 should be equal to 1.") {
            try v.validate(2)
        }
    }
    
    func testValidationNotEqual() {
        let v = ValidationNotEqual(1)
        assertNoError() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertValidationError("1 should not be equal to 1.") {
            try v.validate(1)
        }
    }
    
    func testValidationLessThanOrEqual() {
        let v = ValidationLessThanOrEqual(2)
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertNoError() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertValidationError("3 should be less or equal to 2.") {
            try v.validate(3)
        }
    }
    
    func testValidationGreaterThanOrEqual() {
        let v = ValidationGreaterThanOrEqual(2)
        assertNoError() {
            let result = try v.validate(3)
            XCTAssertEqual(result, 3)
        }
        assertNoError() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertValidationError("1 should be greater or equal to 2.") {
            try v.validate(1)
        }
    }
    
    func testRegularExpressionValidationFromPattern() {
        let v = ValidationRegularExpression(pattern: "foo")
        assertNoError() {
            let result = try v.validate("xxxfooxxx")
            XCTAssertEqual(result, "xxxfooxxx")
        }
        assertValidationError("\"bar\" is invalid.") {
            try v.validate("bar")
        }
    }
    
    func testRegularExpressionValidationFromRegularExpression() {
        let v = try! ValidationRegularExpression(NSRegularExpression(pattern: "^foo$", options: NSRegularExpressionOptions()))
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValidationError("\"xxxfooxxx\" is invalid.") {
            try v.validate("xxxfooxxx")
        }
    }
    
    func testAnyValidationFromBlock() {
        let v = AnyValidation { (value: Int) -> Int in
            guard value != 10 else { throw ValidationError(value: value, message: "should not be 10.") }
            return value
        }
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError("10 should not be 10.") {
            try v.validate(10)
        }
    }
    
    func testAnyValidationFromBaseValidation() {
        let v = AnyValidation(ValidationNotNil<Int>())
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testFlatMap() {
        let v = ValidationNotNil<String>().flatMap { return $0.characters.count }
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, 3)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testComposedValidation() {
        let v = ValidationNotNil<String>() >>> ValidationStringNotEmpty()
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
        assertValidationError("\"\" should not be empty.") {
            try v.validate("")
        }
    }
    
    func testOrValidation() {
        let v = AnyValidation { (value: String) -> Int in
            guard value == "foo" else { throw ValidationError(value: value, message: "should be foo.") }
            return 1
        } || AnyValidation { (value: String) -> Bool in
            guard value == "bar" else { throw ValidationError(value: value, message: "should be bar.") }
            return true
        }
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertNoError() {
            let result = try v.validate("bar")
            XCTAssertEqual(result, "bar")
        }
        assertValidationError("\"qux\" should be foo. \"qux\" should be bar.") {
            try v.validate("qux")
        }
    }
    
    func testAndValidation() {
        let v = AnyValidation { (value: Int) -> String in
            guard value % 2 == 1 else { throw ValidationError(value: value, message: "should be odd.") }
            return "foo"
        } && AnyValidation { (value: Int) -> Bool in
            guard value <= 10 else { throw ValidationError(value: value, message: "should be less than 10.") }
            return true
        }
        assertNoError() {
            let result = try v.validate(5)
            XCTAssertEqual(result, 5)
        }
        assertValidationError("2 should be odd.") {
            try v.validate(2)
        }
        assertValidationError("11 should be less than 10.") {
            try v.validate(11)
        }
        assertValidationError("12 should be odd. 12 should be less than 10.") {
            try v.validate(12)
        }
    }
}
