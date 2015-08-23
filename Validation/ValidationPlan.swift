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


/**
A Navigation Plan helps validating a Validable value as a whole.

It is able to gather many validation errors and turn them into a single one:

Compare:

    struct Person : Validable {
        let name: String?
        let age: Int?
        var phoneNumber: String?
        
        // This method stops after the first validation error:
        func validate1() throws {
            try validate(name, forName: "name", with: ValidationStringNotEmpty())
            try validate(age, forName: "age", with: ValidationRange(minimum: 0))
            try validate(phoneNumber, forName: "phoneNumber", with: PhoneNumberValidation())
        }

        // This method is able to return all validation errors found in Person.
        func validate2() throws {
            try ValidationPlan()
                .append { try validate(name, forName: "name", with: ValidationStringNotEmpty()) }
                .append { try validate(age, forName: "age", with: ValidationRange(minimum: 0)) }
                .append { try validate(phoneNumber, forName: "phoneNumber", with: PhoneNumberValidation()) }
                .validate()
        }
    }
*/
public class ValidationPlan {
    private var errors = [ValidationError]()
    
    public init() { }
    
    public func append(@noescape block: () throws -> ()) rethrows -> ValidationPlan {
        do {
            try block()
        } catch let error as ValidationError {
            errors.append(error)
        }
        return self
    }
    
    public func validate() throws {
        if let error = ValidationError.compound(errors) {
            throw error
        }
    }
}
