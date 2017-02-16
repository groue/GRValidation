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
public struct ValidationError : Error {
    
    public init(value: Any?, message: String? = nil) {
        self.init(.value(value: value, message: message ?? ValidationFailedMessage()))
    }
    
    public init(value: Any, message: String, propertyNames: [String]) {
        self.init(.model(value: value, message: message, propertyNames: propertyNames, error: nil))
    }
    
    
    // not public
    
    enum CompoundMode {
        case and
        case or
    }
    
    indirect enum GRType {
        /// Error on a value
        case value(value: Any?, message: String)
        
        // TODO: the Model and Property cases are a conceptual mess.
        
        /// Error on a model
        case model(value: Any, message: String, propertyNames: [String], error: ValidationError?)
        
        /// Error on a property
        case property(value: Any, propertyName: String, error: ValidationError)
        
        /// Compound errors
        case compound(mode: CompoundMode, errors: [ValidationError])
    }
    
    let type: GRType
    
    init(_ type: GRType) {
        self.type = type
    }
}

extension ValidationError : CustomStringConvertible {
    public var description: String {
        return description(nil)
    }
    
    fileprivate func description(_ valueDescription: String?) -> String {
        switch type {
        case .value(let value, let message):
            if let valueDescription = valueDescription {
                return "\(valueDescription) \(message)"
            } else if let value = value {
                return "\(String(reflecting: value)) \(message)"
            } else {
                return "nil \(message)"
            }
        case .property(let value, let propertyName, let error):
            return "Invalid \(String(reflecting: value)): \(error.description(propertyName))"
        case .model(let value, let message, _, _):
            return "Invalid \(String(reflecting: value)): \(message)"
        case .compound(let mode, let errors):
            switch mode {
            case .or:
                return errors.last!.description(valueDescription)
            case .and:
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
                return uniq.joined(separator: " ")
            }
        }
    }
}

extension ValidationError {
    /// If errors is empty, returns nil. If error contains a single error,
    /// returns this error. Otherwise, returns a compound error.
    public static func compound(_ errors: [ValidationError]) -> ValidationError? {
        return compound(errors, mode: .and)
    }
    
    static func compound(_ errors: [ValidationError], mode: CompoundMode) -> ValidationError? {
        switch errors.count {
        case 0:
            return nil
        case 1:
            return errors.first
        default:
            return ValidationError(.compound(mode: mode, errors: errors))
        }
    }
}

extension ValidationError {
    /// Returns all errors for a given property name.
    public func propertyErrors(_ propertyName: String) -> [ValidationError] {
        switch type {
        case .value:
            return []
        case .property(_, let name, _):
            if name == propertyName {
                return [self]
            } else {
                return []
            }
        case .model(_, _, let propertyNames, _):
            if propertyNames.contains(propertyName) {
                return [self]
            } else {
                return []
            }
        case .compound(_, let errors):
            return errors.flatMap { $0.propertyErrors(propertyName) }
        }
    }
    
    /// Returns all errors for the model as a whole.
    public func modelErrors() -> [ValidationError] {
        switch type {
        case .value:
            return []
        case .property:
            return []
        case .model:
            return [self]
        case .compound(_, let errors):
            return errors.flatMap { $0.modelErrors() }
        }
    }
}
