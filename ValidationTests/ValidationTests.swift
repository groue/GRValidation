//
//  ValidationTests.swift
//  ValidationTests
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

import XCTest
import Validation

class ValidationTests: ValidationTestCase {
    
    func testValidation() {
        let v = Validation<Int>()
        assertValid() {
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
        assertValid() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testValidationCollectionNotEmpty() {
        let v = ValidationCollectionNotEmpty<[Int]>()
        assertValid() {
            let result = try v.validate([1,2,3])
            XCTAssertEqual(result, [1,2,3])
        }
        assertValidationError("[] should not be empty.") {
            try v.validate([])
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testValidationStringNotEmpty() {
        let v = ValidationStringNotEmpty()
        assertValid() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValidationError("\"\" should not be empty.") {
            try v.validate("")
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testValidationRawValue() {
        enum Enum: Int {
            case Zero
            case One
            case Two
        }
        let v = ValidationRawValue<Enum>()
        assertValid() {
            let result = try v.validate(1)
            XCTAssertEqual(result, Enum.One)
        }
        assertValidationError("5 is invalid.") {
            try v.validate(5)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testValidationEqual() {
        let v = ValidationEqual(1)
        assertValid() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError("2 should be equal to 1.") {
            try v.validate(2)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testValidationNotEqual() {
        let v = ValidationNotEqual(1)
        assertValid() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertValidationError("1 should not be equal to 1.") {
            try v.validate(1)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testValidationElementOf() {
        let v = ValidationElementOf([1,2])
        assertValid() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValid() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertValidationError("3 should be in [1, 2].") {
            try v.validate(3)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testValidationRangeWithMaximum() {
        let v = ValidationRange(maximum: 2)
        assertValid() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValid() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertValidationError("3 should be less or equal to 2.") {
            try v.validate(3)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testValidationRangeWithMinimum() {
        let v = ValidationRange(minimum: 2)
        assertValid() {
            let result = try v.validate(3)
            XCTAssertEqual(result, 3)
        }
        assertValid() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertValidationError("1 should be greater or equal to 2.") {
            try v.validate(1)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testValidationRangeWithRange() {
        let v = ValidationRange(range: 2..<4)
        assertValid() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertValid() {
            let result = try v.validate(3)
            XCTAssertEqual(result, 3)
        }
        assertValidationError("1 should be in Range(2..<4).") {
            try v.validate(1)
        }
        assertValidationError("4 should be in Range(2..<4).") {
            try v.validate(4)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testRegularExpressionValidationFromPattern() {
        let v = ValidationRegularExpression(pattern: "foo")
        assertValid() {
            let result = try v.validate("xxxfooxxx")
            XCTAssertEqual(result, "xxxfooxxx")
        }
        assertValidationError("\"bar\" is invalid.") {
            try v.validate("bar")
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testRegularExpressionValidationFromRegularExpression() {
        let v = try! ValidationRegularExpression(NSRegularExpression(pattern: "^foo$", options: NSRegularExpressionOptions()))
        assertValid() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValidationError("\"xxxfooxxx\" is invalid.") {
            try v.validate("xxxfooxxx")
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testAnyValidationFromBlock() {
        let v = AnyValidation { (value: Int) -> Int in
            guard value != 10 else { throw ValidationError.Value(value: value, message: "should not be 10.") }
            return value
        }
        assertValid() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError("10 should not be 10.") {
            try v.validate(10)
        }
    }
    
    func testAnyValidationFromBaseValidation() {
        let v = AnyValidation(ValidationNotNil<Int>())
        assertValid() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testFlatMapOperator() {
        let v = ValidationNotNil<String>() >> { return $0.characters.count }
        assertValid() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, 3)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testComposedValidation() {
        let v = ValidationNotNil<String>() >> ValidationStringNotEmpty()
        assertValid() {
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
            guard value == "foo" else { throw ValidationError.Value(value: value, message: "should be foo.") }
            return 1
        } || AnyValidation { (value: String) -> Bool in
            guard value == "bar" else { throw ValidationError.Value(value: value, message: "should be bar.") }
            return true
        }
        assertValid() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValid() {
            let result = try v.validate("bar")
            XCTAssertEqual(result, "bar")
        }
        assertValidationError("\"qux\" should be foo. \"qux\" should be bar.") {
            try v.validate("qux")
        }
    }
    
    func testAndValidation() {
        let v = AnyValidation { (value: Int) -> String in
            guard value % 2 == 1 else { throw ValidationError.Value(value: value, message: "should be odd.") }
            return "foo"
        } && AnyValidation { (value: Int) -> Bool in
            guard value <= 10 else { throw ValidationError.Value(value: value, message: "should be less than 10.") }
            return true
        }
        assertValid() {
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
