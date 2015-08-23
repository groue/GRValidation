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

class ValidationTestCase: XCTestCase {

    func assertNoError(block: () throws -> ()) {
        do {
            try block()
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func assertValidationError(expectedErrorDescription: String, block: () throws -> ()) {
        do {
            try block()
            XCTFail("ValidationError expected")
        } catch let error as ValidationError {
            XCTAssertEqual(error.description, expectedErrorDescription)
            if error.description != expectedErrorDescription {
                // for debugging breakpoint
                error.description
            }
        } catch {
            XCTFail("ValidationError expected")
        }
    }
    
}
