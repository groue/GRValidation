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
A Validation Error
*/
public struct ValidationError : ErrorType {
    
    public init(value: Any?, message: String) {
        self.init(.Value(value: value, message: message))
    }
    
    
    // not public
    
    enum CompoundMode {
        case And
        case Or
    }
    
    indirect enum Type {
        /// Error on a value
        case Value(value: Any?, message: String)
        
        /// Error on a model
        case Model(model: Any, propertyNames: [String], globalDescription: String?, error: ValidationError)
        
        /// Compound errors
        case Compound(mode: CompoundMode, errors: [ValidationError])
    }
    
    let type: Type
    
    init(_ type: Type) {
        self.type = type
    }
}

extension ValidationError : CustomStringConvertible {
    public var description: String {
        return description(nil)
    }
    
    private func description(valueDescription: String?) -> String {
        switch type {
        case .Value(let value, let message):
            if let valueDescription = valueDescription {
                return "\(valueDescription) \(message)"
            } else if let value = value {
                return "\(String(reflecting: value)) \(message)"
            } else {
                return "nil \(message)"
            }
        case .Model(let model, let propertyNames, let globalDescription, let error):
            if let globalDescription = globalDescription {
                return "Invalid \(String(reflecting: model)): \(globalDescription)"
            } else {
                let properties = ", ".join(propertyNames)
                return "Invalid \(String(reflecting: model)): \(error.description(properties))"
            }
        case .Compound(let mode, let errors):
            switch mode {
            case .Or:
                return errors.last!.description(valueDescription)
            case .And:
                // Avoid duplicated descriptions
                var found = Set<String>()
                var uniq = [String]()
                for error in errors {
                    let description = error.description(valueDescription)
                    if !found.contains(description) {
                        uniq.append(description)
                        found.insert(description)
                    }
                }
                return " ".join(uniq)
            }
        }
    }
}

extension ValidationError {
    /// If errors is empty, returns nil. If error contains a single error,
    /// returns this error. Otherwise, returns a compound error.
    public static func compound(errors: [ValidationError]) -> ValidationError? {
        return compound(errors, mode: .And)
    }
    
    static func compound(errors: [ValidationError], mode: CompoundMode) -> ValidationError? {
        switch errors.count {
        case 0:
            return nil
        case 1:
            return errors.first
        default:
            return ValidationError(.Compound(mode: mode, errors: errors))
        }
    }
}

extension ValidationError {
    /// Returns all errors for a given name.
    public func errorsFor(name name: String) -> [ValidationError] {
        switch type {
        case .Value:
            return []
        case .Model(_, let propertyNames, _, _):
            if propertyNames.contains(name) {
                return [self]
            } else {
                return []
            }
        case .Compound(_, let errors):
            return errors.flatMap { $0.errorsFor(name: name) }
        }
    }
}