//
// GRValidation
// https://github.com/groue/GRValidation
// Copyright (c) 2015 Gwendal Roué
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import XCTest
import Validation

enum Enum: Int {
    case Zero
    case One
    case Two
}

class ValueValidationTests: ValidationTestCase {
    
    func testValidation() {
        let v = Validation<Int>()
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
    
    func testValidationCollectionNotEmpty() {
        let v = ValidationCollectionNotEmpty<[Int]>()
        assertNoError() {
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
            assertNoError() {
                let result = try v.validate(" foo ")
                XCTAssertEqual(result, "foo")
            }
            assertNoError() {
                let result = try v.validate(" \t\n")
                XCTAssertEqual(result, "")
            }
            assertNoError() {
                let result = try v.validate(nil)
                XCTAssertTrue(result == nil)
            }
        }
        do {
            let v = ValidationTrim(characterSet: NSCharacterSet(charactersInString: "<>"))
            assertNoError() {
                let result = try v.validate("<foo>")
                XCTAssertEqual(result, "foo")
            }
            assertNoError() {
                let result = try v.validate("><><")
                XCTAssertEqual(result, "")
            }
            assertNoError() {
                let result = try v.validate(nil)
                XCTAssertTrue(result == nil)
            }
        }
    }
    
    func testValidationStringLengthMinimum1() {
        do {
            let v = ValidationStringLength(minimum: 1)
            assertNoError() {
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
            assertNoError() {
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
            assertNoError() {
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
            assertNoError() {
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
        let v = ValidationRawValue<Enum>()
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, Enum.One)
        }
        assertValidationError("5 is an invalid Enum.") {
            try v.validate(5)
        }
        assertValidationError("nil is an invalid Enum.") {
            try v.validate(nil)
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
        assertValidationError("nil should be equal to 1.") {
            try v.validate(nil)
        }
    }
    
    func testValidationNotEqual() {
        let v = ValidationNotEqual(1)
        assertNoError() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertNoError() {
            try v.validate(nil)
        }
        assertValidationError("1 should not be equal to 1.") {
            try v.validate(1)
        }
    }
    
    func testValidationElementOf() {
        let v = ValidationElementOf([1,2])
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertNoError() {
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
        assertNoError() {
            let result = try v.validate(0)
            XCTAssertEqual(result, 0)
        }
        assertNoError() {
            let result = try v.validate(nil)
            XCTAssertTrue(result == nil)
        }
        assertValidationError("1 should not be in [1, 2].") {
            try v.validate(1)
        }
    }
    
    func testValidationRangeWithMaximum() {
        let v = ValidationRange(maximum: 2)
        assertNoError() {
            let result = try v.validate(1)
            XCTAssertEqual(result, 1)
        }
        assertNoError() {
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
        assertNoError() {
            let result = try v.validate(3)
            XCTAssertEqual(result, 3)
        }
        assertNoError() {
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
        assertNoError() {
            let result = try v.validate(2)
            XCTAssertEqual(result, 2)
        }
        assertNoError() {
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
        assertNoError() {
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
        assertNoError() {
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
    
    func testFlatMapOperator() {
        let v = ValidationNotNil<String>() >>> { return $0.characters.count }
        assertNoError() {
            let result = try v.validate("foo")
            XCTAssertEqual(result, 3)
        }
        assertValidationError("nil should not be nil.") {
            try v.validate(nil)
        }
    }
    
    func testChainOperator() {
        let v = ValidationNotNil() >>> ValidationStringLength(minimum: 1)
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
