//
//  ValidationTests.swift
//  ValidationTests
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

import XCTest
import Validation

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
        let v = ValidationNotEmpty()
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, "foo")
        }
        assertValidationError() {
            try v.validate("")
        }
    }
    
    func testAnyValidationFromBlock() {
        let v = AnyValidation { (value: Int) -> Int in
            guard value != 10 else { throw ValidationError(value: value, description: "should not be 10") }
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
    
    func testComposedValidation() {
        let v = ValidationNotNil<String>() >>> ValidationNotEmpty()
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
        let v = AnyValidation { (value: String) -> String in
            guard value == "foo" else { throw ValidationError(value: value, description: "should be foo") }
            return value
        } || AnyValidation { (value: String) -> String in
            guard value == "bar" else { throw ValidationError(value: value, description: "should be bar") }
            return value
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
    
    func testFlatMap() {
        let v = ValidationNotNil<String>()
            .flatMap { return $0.characters.count }
            >>> ValidationGreaterThanOrEqual(3)
        assertNoError() {
            let result = try v.validate("foobar")
            XCTAssertEqual(result, 6)
        }
        assertValidationError() {
            try v.validate("")
        }
    }
}
