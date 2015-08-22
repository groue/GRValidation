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
        assertValidationError("nil should not be empty.") {
            try v.validate(nil)
        }
    }
    
    func testValidationTrim() {
        do {
            let v = ValidationTrim()
            assertValid() {
                let result = try v.validate(" foo ")
                XCTAssertEqual(result, "foo")
            }
            assertValid() {
                let result = try v.validate(" \t\n")
                XCTAssertEqual(result, "")
            }
            assertValid() {
                let result = try v.validate(nil)
                XCTAssertTrue(result == nil)
            }
        }
        do {
            let v = ValidationTrim(characterSet: NSCharacterSet(charactersInString: "<>"))
            assertValid() {
                let result = try v.validate("<foo>")
                XCTAssertEqual(result, "foo")
            }
            assertValid() {
                let result = try v.validate("><><")
                XCTAssertEqual(result, "")
            }
            assertValid() {
                let result = try v.validate(nil)
                XCTAssertTrue(result == nil)
            }
        }
    }
    
    func testValidationStringLengthMinimum1() {
        do {
            let v = ValidationStringLength(minimum: 1)
            assertValid() {
                let result = try v.validate("foo")
                XCTAssertEqual(result, "foo")
            }
            assertValidationError("\"\" should not be empty.") {
                try v.validate("")
            }
            assertValidationError("nil should not be empty.") {
                try v.validate(nil)
            }
        }
    }
    
    func testValidationStringLengthMinimum2() {
        do {
            let v = ValidationStringLength(minimum: 2)
            assertValid() {
                let result = try v.validate("foo")
                XCTAssertEqual(result, "foo")
            }
            assertValidationError("\"\" should contain at least 2 characters.") {
                try v.validate("")
            }
            assertValidationError("nil should contain at least 2 characters.") {
                try v.validate(nil)
            }
        }
    }
    
    func testValidationStringLengthMaximum0() {
        do {
            let v = ValidationStringLength(maximum: 0)
            assertValid() {
                let result = try v.validate("")
                XCTAssertEqual(result, "")
            }
            assertValidationError("\"foo\" should be empty.") {
                try v.validate("foo")
            }
            assertValidationError("nil should be empty.") {
                try v.validate(nil)
            }
        }
    }
    
    func testValidationStringLengthMaximum1() {
        do {
            let v = ValidationStringLength(maximum: 1)
            assertValid() {
                let result = try v.validate("f")
                XCTAssertEqual(result, "f")
            }
            assertValidationError("\"foo\" should contain at most 1 character.") {
                try v.validate("foo")
            }
            assertValidationError("nil should contain at most 1 character.") {
                try v.validate(nil)
            }
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
        assertValidationError("nil is invalid.") {
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
        assertValidationError("nil should be equal to 1.") {
            try v.validate(nil)
        }
    }
    
    func testValidationNotEqual() {
        let v = ValidationNotEqual(1)
        assertValid() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertValid() {
            try v.validate(nil)
        }
        assertValidationError("1 should not be equal to 1.") {
            try v.validate(1)
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
        assertValidationError("nil should be in [1, 2].") {
            try v.validate(nil)
        }
    }
    
    func testValidationNotElementOf() {
        let v = ValidationNotElementOf([1,2])
        assertValid() {
            let result = try v.validate(0)
            XCTAssertEqual(result, 0)
        }
        assertValid() {
            let result = try v.validate(nil)
            XCTAssertTrue(result == nil)
        }
        assertValidationError("1 should not be in [1, 2].") {
            try v.validate(1)
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
        assertValidationError("3 should be less than or equal to 2.") {
            try v.validate(3)
        }
        assertValidationError("nil should be less than or equal to 2.") {
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
        assertValidationError("1 should be greater than or equal to 2.") {
            try v.validate(1)
        }
        assertValidationError("nil should be greater than or equal to 2.") {
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
        assertValidationError("nil should be in Range(2..<4).") {
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
        assertValidationError("nil is invalid.") {
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
        assertValidationError("nil is invalid.") {
            try v.validate(nil)
        }
    }
    
    func testAnyValidationFromBlock() {
        let v = AnyValidation { (value: Int) -> Int in
            guard value != 10 else { throw ValidationError(value: value, message: "should not be 10.") }
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
        let v = ValidationNotNil<String>() >>> { return $0.characters.count }
        assertValid() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, 3)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testComposedValidation() {
        let v = ValidationNotNil() >>> ValidationStringLength(minimum: 1)
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
        let v = ValidationNil<String>() || ValidationStringLength(minimum: 1)
        assertValid() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValid() {
            let result = try v.validate(nil)
            XCTAssertTrue(result == nil)
        }
        assertValidationError("\"\" should not be empty.") {
            try v.validate("")
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
