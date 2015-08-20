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

class ValidationTests: XCTestCase {
    
    func assertNoError(block: () throws -> ()) {
        do {
            try block()
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func assertValidationError(block: () throws -> ()) {
        do {
            try block()
            XCTFail("ValidationError expected")
        } catch _ as ValidationError {
        } catch {
            XCTFail("ValidationError expected")
        }
    }
    
    func testValidationSuccess() {
        let v = ValidationSuccess<Int>()
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
    }
    
    func testValidationFailure() {
        let v = ValidationFailure<Int>()
        assertValidationError() {
            try v.validate(1)
        }
    }
    
    func testValidationNotNil() {
        let v = ValidationNotNil<Int>()
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError() {
            try v.validate(nil)
        }
    }
    
    func testValidationNotEmpty() {
        let v = ValidationNotEmpty<[Int]>()
        assertNoError() {
            let result = try v.validate([1,2,3])
            XCTAssertEqual(result, [1,2,3])
        }
        assertValidationError() {
            try v.validate([])
        }
    }
    
    func testValidationStringNotEmpty() {
        let v = ValidationStringNotEmpty()
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValidationError() {
            try v.validate("")
        }
    }
    
    func testValidationRawValue() {
        let v = ValidationRawValue<ValidatedRawRepresentable>()
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, ValidatedRawRepresentable.One)
        }
        assertValidationError() {
            try v.validate(5)
        }
    }
    
    func testValidationEqual() {
        let v = ValidationEqual(1)
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError() {
            try v.validate(2)
        }
    }
    
    func testValidationNotEqual() {
        let v = ValidationNotEqual(1)
        assertNoError() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertValidationError() {
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
        assertValidationError() {
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
        assertValidationError() {
            try v.validate(1)
        }
    }
    
    func testRegularExpressionValidationFromPattern() {
        let v = ValidationRegularExpression(pattern: "foo")
        assertNoError() {
            let result = try v.validate("xxxfooxxx")
            XCTAssertEqual(result, "xxxfooxxx")
        }
        assertValidationError() {
            try v.validate("bar")
        }
    }
    
    func testRegularExpressionValidationFromRegularExpression() {
        let v = try! ValidationRegularExpression(NSRegularExpression(pattern: "^foo$", options: NSRegularExpressionOptions()))
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValidationError() {
            try v.validate("xxxfooxxx")
        }
    }
    
    func testAnyValidationFromBlock() {
        let v = AnyValidation { (value: Int) -> Int in
            guard value != 10 else { throw ValidationError(value: value, description: "should not be 10.") }
            return value
        }
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError() {
            try v.validate(10)
        }
    }
    
    func testAnyValidationFromBaseValidation() {
        let v = AnyValidation(ValidationNotNil<Int>())
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError() {
            try v.validate(nil)
        }
    }
    
    func testFlatMap() {
        let v = ValidationNotNil<String>().flatMap { return $0.characters.count }
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, 3)
        }
        assertValidationError() {
            try v.validate(nil)
        }
    }
    
    func testComposedValidation() {
        let v = ValidationNotNil<String>().flatMap { return $0.characters } >>> ValidationNotEmpty().flatMap { String($0) }
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValidationError() {
            try v.validate(nil)
        }
        assertValidationError() {
            try v.validate("")
        }
    }
    
    func testOrValidation() {
        let v = AnyValidation { (value: String) -> Int in
            guard value == "foo" else { throw ValidationError(value: value, description: "should be foo.") }
            return 1
        } || AnyValidation { (value: String) -> Bool in
            guard value == "bar" else { throw ValidationError(value: value, description: "should be bar.") }
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
        assertValidationError() {
            try v.validate("qux")
        }
    }
    
    func testAndValidation() {
        let v = AnyValidation { (value: String) -> Int in
            guard value.characters.count >= 2 else { throw ValidationError(value: value, description: "should have at least 2 characters.") }
            return 1
        } && AnyValidation { (value: String) -> Bool in
            guard value.characters.count <= 5 else { throw ValidationError(value: value, description: "should have at most 5 characters.") }
            return true
        }
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValidationError() {
            try v.validate("a")
        }
        assertValidationError() {
            try v.validate("abcdef")
        }
    }
}
