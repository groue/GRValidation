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

class ValidationTypeTests: ValidationTestCase {
    
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
}
