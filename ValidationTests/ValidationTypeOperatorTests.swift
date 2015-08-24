//
//  ValidationTypeOperatorTests.swift
//  Validation
//
//  Created by Gwendal Roué on 24/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

import XCTest
import Validation

class ValidationTypeOperatorTests: ValidationTestCase {
    
    func testChainOperator() {
        do {
            // public func >>> <Left : ValidationType, Right : ValidationType where Left.ValidType == Right.TestedType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Right.ValidType>
            let v1 = AnyValidation { (value: Int) -> String in
                guard value % 2 == 1 else { throw ValidationError(value: value, message: "should be odd.") }
                return "\(value)"
            }
            let v2 = AnyValidation { (value: String) -> Bool in
                guard value == "1" else { throw ValidationError(value: value, message: "should be 1.") }
                return true
            }
            let v = v1 >>> v2
            assertNoError {
                let result = try v.validate(1)
                XCTAssertEqual(result, true)
            }
            assertValidationError("2 should be odd.") {
                try v.validate(2)
            }
            assertValidationError("\"3\" should be 1.") {
                try v.validate(3)
            }
        }
        do {
            // public func >>> <Left : ValidationType, Right : ValidationType where Right.TestedType == Optional<Left.ValidType>>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Right.ValidType>
            let v1 = AnyValidation { (value: Int) -> String in
                guard value % 2 == 1 else { throw ValidationError(value: value, message: "should be odd.") }
                return "\(value)"
            }
            let v2 = AnyValidation { (value: String?) -> Bool in
                guard value == "1" else { throw ValidationError(value: value, message: "should be 1.") }
                return true
            }
            let v = v1 >>> v2
            assertNoError {
                let result = try v.validate(1)
                XCTAssertEqual(result, true)
            }
            assertValidationError("2 should be odd.") {
                try v.validate(2)
            }
            assertValidationError("\"3\" should be 1.") {
                try v.validate(3)
            }
        }
    }
    
    func testOrOperator() {
        do {
            // public func ||<Left : ValidationType, Right : ValidationType where Left.TestedType == Right.TestedType, Left.ValidType == Right.ValidType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Left.ValidType>
            let v1 = AnyValidation<Int, String>() { i in
                guard i == 1 else { throw ValidationError(value: i, message: "fails v1.") }
                return "v1"
            }
            let v2 = AnyValidation<Int, String>() { i in
                guard i == 2 else { throw ValidationError(value: i, message: "fails v2.") }
                return "v2"
            }
            let v = v1 || v2
            assertNoError {
                let result = try v.validate(1)
                XCTAssertEqual(result, "v1")
            }
            assertNoError {
                let result = try v.validate(2)
                XCTAssertEqual(result, "v2")
            }
            assertValidationError("3 fails v2.") {
                try v.validate(3)
            }
        }
        do {
            // public func ||<Left : ValidationType, Right : ValidationType where Left.TestedType == Right.TestedType, Left.ValidType == Optional<Right.ValidType>>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Left.ValidType>
            let v1 = AnyValidation<Int, String?>() { i in
                guard i == 1 else { throw ValidationError(value: i, message: "fails v1.") }
                return "v1"
            }
            let v2 = AnyValidation<Int, String>() { i in
                guard i == 2 else { throw ValidationError(value: i, message: "fails v2.") }
                return "v2"
            }
            let v = v1 || v2
            assertNoError {
                let result = try v.validate(1)
                XCTAssertEqual(result, "v1")
            }
            assertNoError {
                let result = try v.validate(2)
                XCTAssertEqual(result, "v2")
            }
            assertValidationError("3 fails v2.") {
                try v.validate(3)
            }
        }
        do {
            // public func ||<Left : ValidationType, Right : ValidationType where Left.TestedType == Right.TestedType, Right.ValidType == Optional<Left.ValidType>>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Right.ValidType>
            let v1 = AnyValidation<Int, String>() { i in
                guard i == 1 else { throw ValidationError(value: i, message: "fails v1.") }
                return "v1"
            }
            let v2 = AnyValidation<Int, String?>() { i in
                guard i == 2 else { throw ValidationError(value: i, message: "fails v2.") }
                return "v2"
            }
            let v = v1 || v2
            assertNoError {
                let result = try v.validate(1)
                XCTAssertEqual(result, "v1")
            }
            assertNoError {
                let result = try v.validate(2)
                XCTAssertEqual(result, "v2")
            }
            assertValidationError("3 fails v2.") {
                try v.validate(3)
            }
        }
        do {
            // public func ||<Left : ValidationType, Right : ValidationType where Left.TestedType == Right.TestedType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Left.TestedType>
            let v1 = AnyValidation<Int, String>() { i in
                guard i == 1 else { throw ValidationError(value: i, message: "fails v1.") }
                return "v1"
            }
            let v2 = AnyValidation<Int, Bool>() { i in
                guard i == 2 else { throw ValidationError(value: i, message: "fails v2.") }
                return true
            }
            let v = v1 || v2
            assertNoError {
                let result = try v.validate(1)
                XCTAssertEqual(result, 1)
            }
            assertNoError {
                let result = try v.validate(2)
                XCTAssertEqual(result, 2)
            }
            assertValidationError("3 fails v2.") {
                try v.validate(3)
            }
        }
    }
    
    func testAndOperator() {
        // public func &&<Left : ValidationType, Right : ValidationType where Left.TestedType == Right.TestedType>(left: Left, right: Right) -> AnyValidation<Right.TestedType, Right.ValidType>
        let v1 = AnyValidation { (value: Int) -> Bool in
            guard value % 2 == 1 else { throw ValidationError(value: value, message: "should be odd.") }
            return true
        }
        let v2 = AnyValidation { (value: Int) -> String in
            guard value <= 10 else { throw ValidationError(value: value, message: "should be less than 10.") }
            return "v2"
        }
        let v = v1 && v2
        assertNoError() {
            let result = try v.validate(5)
            XCTAssertEqual(result, "v2")
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
    
    func testNotOperator() {
        let v = !ValidationEqual(1)
        assertNoError() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertNoError() {
            try v.validate(nil)
        }
        assertValidationError("Optional(1) is invalid.") {
            try v.validate(1)
        }
    }
    
    func testMatchOperator() {
        let v = ValidationRange(range: 1..<10)
        
        // Operator
        XCTAssertTrue(v ~= 1)
        
        // Switch
        switch 1 {
        case v:
            break
        default:
            XCTFail("Expected 1 to match \(v)")
        }
    }
}
