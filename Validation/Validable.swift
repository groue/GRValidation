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



/// A protocol for validation of complex values
public protocol Validable {}

extension Validable {
    /**
    Validates a property:
    
        struct Person : Validable {
            let name: String?
    
            func validate() throws {
                try validate(name, forName: "name", with: ValidationNotNil())
            }
        }
    */
    public func validateProperty<V: ValidationType where V.TestedType == Void>(name: String, with validation: V) throws -> V.ValidType {
        return try validation.named(name).owned(self).validate()
    }
    
    /**
    Validates globally:
    
        struct Person : Validable {
            let firstName: String?
            let lastName: String?
    
            func validate() throws {
                try validate(
                    "First and last name can't be both empty.",
                    with: (firstName >>> ValidationStringNotEmpty() || lastName >>> ValidationStringNotEmpty()))
            }
        }
    */
    public func validate<V: ValidationType where V.TestedType == Void>(description: String, with validation: V) throws {
        try validation.global(description).owned(self).validate()
    }
}
