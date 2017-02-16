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


import Foundation


// MARK: - Standard Validation Messages

public func ValidationFailedMessage() -> String {
    return "is invalid."
}
public func ValidationNotNilFailedMessage() -> String {
    return "should not be nil."
}
public func ValidationNilFailedMessage() -> String {
    return "should be nil."
}
public func ValidationNotEmptyFailedMessage() -> String {
    return "should not be empty."
}
public func ValidationEmptyFailedMessage() -> String {
    return "should be empty."
}
public func ValidationEqualFailedMessage<T: Equatable>(_ value: T) -> String {
    return "should be equal to \(String(reflecting: value))."
}
public func ValidationNotEqualFailedMessage<T: Equatable>(_ value: T) -> String {
    return "should not be equal to \(String(reflecting: value))."
}
public func ValidationStringLengthMinimumFailedMessage(_ length: Int) -> String {
    if length == 1 {
        return ValidationNotEmptyFailedMessage()
    } else {
        return "should contain at least \(length) characters."
    }
}
public func ValidationStringLengthMaximumFailedMessage(_ length: Int) -> String {
    switch length {
    case 0:
        return ValidationEmptyFailedMessage()
    case 1:
        return "should contain at most \(length) character."
    default:
        return "should contain at most \(length) characters."
    }
}
public func ValidationStringLengthRangeFailedMessage(_ range: Range<Int>) -> String {
    return "length should be in \(range)."
}
public func ValidationElementFailedMessage<C>(_ collection: C) -> String where C: Collection {
    return "should be in \(collection)."
}
public func ValidationNotElementFailedMessage<C>(_ collection: C) -> String where C: Collection {
    return "should not be in \(collection)."
}
public func ValidationMinimumFailedMessage<T>(_ value: T) -> String where T: Comparable, T: Comparable {
    return "should be greater than or equal to \(String(reflecting: value))."
}
public func ValidationMaximumFailedMessage<T>(_ value: T) -> String where T: Comparable, T: Comparable {
    return "should be less than or equal to \(String(reflecting: value))."
}
public func ValidationRangeFailedMessage<T>(_ range: Range<T>) -> String where T: Comparable, T: Comparable {
    return "should be in \(String(reflecting: range))."
}
public func ValidationRawValueFailedMessage<T>(_ type: T.Type) -> String where T:RawRepresentable {
    return "is an invalid \(type)."
}


// MARK: - Validation

public protocol ValidationType {
    associatedtype TestedType
    associatedtype ValidType
    func validate(_ value: TestedType) throws -> ValidType
}

extension ValidationType {
    public func validateNotNil<T>(_ value: T?, message: String = ValidationNotNilFailedMessage()) throws -> T {
        guard let value = value else {
            throw ValidationError(.value(value: nil, message: message))
        }
        return value
    }
}

/// A type-erased validation.
public struct AnyValidation<TestedType, ValidType> : ValidationType {
    /// Wrap and forward operations to `base`.
    public init<V: ValidationType>(_ base: V) where V.TestedType == TestedType, V.ValidType == ValidType {
        self.init { return try base.validate($0) }
    }
    /// Create a validation whose `validate()` method forwards to `block`.
    public init(_ block: @escaping (TestedType) throws -> ValidType) {
        self.block = block
    }
    public func validate(_ value: TestedType) throws -> ValidType {
        return try block(value)
    }
    fileprivate let block: (TestedType) throws -> ValidType
}


// MARK: - Boolean check

public func ~=<Validation: ValidationType>(left: Validation, right: Validation.TestedType) -> Bool {
    do {
        try left.validate(right)
        return true
    } catch is ValidationError {
        return false
    } catch {
        fatalError("Unexpected error \(error)")
    }
}


public prefix func !<Validation: ValidationType>(validation: Validation) -> AnyValidation<Validation.TestedType, Validation.TestedType> {
    return AnyValidation {
        if validation ~= $0 {
            throw ValidationError(value: $0, message: ValidationFailedMessage())
        } else {
            return $0
        }
    }
}


// MARK: - Composed Validations

infix operator >>> { associativity left precedence 160 }

public func >>> <Left : ValidationType, Right : ValidationType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Right.ValidType> where Left.ValidType == Right.TestedType {
    return AnyValidation { try right.validate(left.validate($0)) }
}

public func >>> <Left : ValidationType, Right : ValidationType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Right.ValidType> where Right.TestedType == Optional<Left.ValidType> {
    return AnyValidation { try right.validate(left.validate($0)) }
}

/**
Example:

    "foo" >>> ValidationNotNil()
*/
public func >>> <T, Right : ValidationType>(left: T, right: Right) -> AnyValidation<Void, Right.ValidType> where Right.TestedType == T {
    return AnyValidation { try right.validate(left) }
}

/**
Example:

    ValidationNil<String>() || ValidationStringLength(minimum: 1)
*/
public func ||<Left : ValidationType, Right : ValidationType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Left.ValidType> where Left.TestedType == Right.TestedType, Left.ValidType == Right.ValidType {
    return AnyValidation {
        do {
            return try left.validate($0)
        } catch let leftError as ValidationError {
            do {
                return try right.validate($0)
            } catch let rightError as ValidationError {
                throw ValidationError(.compound(mode: .or, errors: [leftError, rightError]))
            }
        }
    }
}

/**
Example:

    ValidationNil() || ValidationRange(minimum: 0)
*/
public func ||<Left : ValidationType, Right : ValidationType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Left.ValidType> where Left.TestedType == Right.TestedType, Left.ValidType == Optional<Right.ValidType> {
    return AnyValidation {
        do {
            return try left.validate($0)
        } catch let leftError as ValidationError {
            do {
                return try right.validate($0)
            } catch let rightError as ValidationError {
                throw ValidationError(.compound(mode: .or, errors: [leftError, rightError]))
            }
        }
    }
}

/**
Example:

    ValidationRange(minimum: 0) || ValidationNil()
*/
public func ||<Left : ValidationType, Right : ValidationType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Right.ValidType> where Left.TestedType == Right.TestedType, Right.ValidType == Optional<Left.ValidType> {
    return AnyValidation {
        do {
            return try left.validate($0)
        } catch let leftError as ValidationError {
            do {
                return try right.validate($0)
            } catch let rightError as ValidationError {
                throw ValidationError(.compound(mode: .or, errors: [leftError, rightError]))
            }
        }
    }
}

/**
Example:

    name >>> ValidationNotNil() || integers >>> ValidationCollectionNotEmpty()
*/
public func ||<Left : ValidationType, Right : ValidationType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Left.TestedType> where Left.TestedType == Right.TestedType {
    return AnyValidation {
        do {
            try left.validate($0)
            return $0
        } catch let leftError as ValidationError {
            do {
                try right.validate($0)
                return $0
            } catch let rightError as ValidationError {
                throw ValidationError(.compound(mode: .or, errors: [leftError, rightError]))
            }
        }
    }
}

/**
Example:

    ValidationNotEqual(1) && ValidationNotEqual(2)
*/
public func &&<Left : ValidationType, Right : ValidationType>(left: Left, right: Right) -> AnyValidation<Right.TestedType, Right.ValidType> where Left.TestedType == Right.TestedType {
    return AnyValidation {
        var errors = [ValidationError]()
        
        do {
            try left.validate($0)
        } catch let error as ValidationError {
            errors.append(error)
        }
        
        var result: Right.ValidType? = nil
        do {
            result = try right.validate($0)
        } catch let error as ValidationError {
            errors.append(error)
        }
        
        if let error = ValidationError.compound(errors) {
            throw error
        } else {
            return result!
        }
    }
}


// MARK: - Validations for any type

/// A validation for type T which always succeeds.
public struct Validation<T> : ValidationType {
    public init() { }
    public init(type: T.Type) { }   // Allows protocol extensions to instanciate Validation of type Self
    public func validate(_ value: T) throws -> T {
        return value
    }
}

/// A validation for type T which always fails.
public struct ValidationFailure<T> : ValidationType {
    public init() { }
    public func validate(_ value: T) throws -> T {
        throw ValidationError(value: value, message: ValidationFailedMessage())
    }
}

/// Validates that the tested value is nil.
public struct ValidationNil<T> : ValidationType {
    public init() { }
    public func validate(_ value: T?) throws -> T? {
        guard value == nil else {
            throw ValidationError(value: value, message: ValidationNilFailedMessage())
        }
        return nil
    }
}

/// Validates that the tested value is not nil.
/// Returns the unwrapped value.
public struct ValidationNotNil<T> : ValidationType {
    public init() { }
    public func validate(_ value: T?) throws -> T {
        return try validateNotNil(value)
    }
}


// MARK: - String Validations

// TODO: check for performance penalty using only ForwardIndexType, and see whether RandomAccessIndexType performs better.
public enum ValidRange<T> where T: Comparable, T: Comparable {
    case minimum(T)
    case maximum(T)
    case range(Swift.Range<T>)
}

/// Validation that always pass.
public struct ValidationTrim: ValidationType {
    let characterSet: CharacterSet
    public init(characterSet: CharacterSet = CharacterSet.whitespacesAndNewlines) {
        self.characterSet = characterSet
    }
    public func validate(_ string: String?) throws -> String? {
        guard let string = string else {
            return nil
        }
        return (string as NSString).trimmingCharacters(in: characterSet)
    }
}

/// Validates the length of the tested string, with optional trimming
public struct ValidationStringLength : ValidationType {
    let range: ValidRange<Int>
    public init(minimum: Int) {
        self.range = ValidRange.minimum(minimum)
    }
    public init(maximum: Int) {
        self.range = ValidRange.maximum(maximum)
    }
    public init(range: Range<Int>) {
        self.range = ValidRange.range(range)
    }
    public func validate(_ string: String?) throws -> String? {
        switch range {
        case .minimum(let minimum):
            let string = try validateNotNil(string, message: ValidationStringLengthMinimumFailedMessage(minimum))
            guard string.characters.count >= minimum else {
                throw ValidationError(value: string, message: ValidationStringLengthMinimumFailedMessage(minimum))
            }
            return string
        case .maximum(let maximum):
            let string = try validateNotNil(string, message: ValidationStringLengthMaximumFailedMessage(maximum))
            guard string.characters.count <= maximum else {
                throw ValidationError(value: string, message: ValidationStringLengthMaximumFailedMessage(maximum))
            }
            return string
        case.range(let range):
            let string = try validateNotNil(string, message: ValidationStringLengthRangeFailedMessage(range))
            guard range ~= string.characters.count else {
                throw ValidationError(value: string, message: ValidationStringLengthRangeFailedMessage(range))
            }
            return string
        }
    }
}

/// Validates the tested string against a regular expression.
public struct ValidationRegularExpression : ValidationType {
    public let regex: NSRegularExpression
    public init(_ regex: NSRegularExpression) {
        self.regex = regex
    }
    public init(pattern: String) {
        try! self.init(NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options()))
    }
    public func validate(_ string: String?) throws -> String {
        let string = try validateNotNil(string, message: ValidationFailedMessage())
        let nsString = string as NSString
        let match = regex.rangeOfFirstMatch(in: string, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: nsString.length))
        guard match.location != NSNotFound else {
            throw ValidationError(value: string, message: ValidationFailedMessage())
        }
        return string
    }
}


// MARK: - CollectionType Validations

/// Validates that the tested collection is not empty.
public struct ValidationCollectionNotEmpty<C: Collection> : ValidationType {
    public init() { }
    public func validate(_ collection: C?) throws -> C {
        let collection = try validateNotNil(collection, message: ValidationNotEmptyFailedMessage())
        guard collection.count > 0 else {
            throw ValidationError(value: collection, message: ValidationNotEmptyFailedMessage())
        }
        return collection
    }
}

/// Validates that the tested collection is nil or empty.
public struct ValidationCollectionEmpty<C: Collection> : ValidationType {
    public init() { }
    public func validate(_ collection: C?) throws -> C? {
        guard let collection = collection else {
            return nil
        }
        guard collection.count == 0 else {
            throw ValidationError(value: collection, message: ValidationEmptyFailedMessage())
        }
        return collection
    }
}


// MARK: - Equatable Validations

/// Validates equality.
public struct ValidationEqual<T> : ValidationType where T: Equatable {
    public let target: T
    public init(_ target: T) {
        self.target = target
    }
    public func validate(_ value: T?) throws -> T {
        let value = try validateNotNil(value, message: ValidationEqualFailedMessage(target))
        guard value == target else {
            throw ValidationError(value: value, message: ValidationEqualFailedMessage(target))
        }
        return value
    }
}

/// Validates inequality.
public struct ValidationNotEqual<T> : ValidationType where T: Equatable {
    public let target: T
    public init(_ target: T) {
        self.target = target
    }
    public func validate(_ value: T?) throws -> T? {
        guard let value = value else {
            return nil
        }
        guard value != target else {
            throw ValidationError(value: value, message: ValidationNotEqualFailedMessage(target))
        }
        return value
    }
}

/// Validates the inclusion of the tested value in a collection.
public struct ValidationElementOf<T: Equatable> : ValidationType {
    let block: (T?) throws -> T
    public init<C>(_ collection: C) where C: Collection, C.Iterator.Element == T {
        block = { (value: T?) -> T in
            guard let value = value else {
                throw ValidationError(value: nil, message: ValidationElementFailedMessage(collection))
            }
            guard collection.contains(value) else {
                throw ValidationError(value: value, message: ValidationElementFailedMessage(collection))
            }
            return value
        }
    }
    public func validate(_ value: T?) throws -> T {
        return try block(value)
    }
}

/// Validates that a tested value is not in a collection.
public struct ValidationNotElementOf<T: Equatable> : ValidationType {
    let block: (T?) throws -> T?
    public init<C>(_ collection: C) where C: Collection, C.Iterator.Element == T {
        block = { (value: T?) -> T? in
            guard let value = value else {
                return nil
            }
            guard !collection.contains(value) else {
                throw ValidationError(value: value, message: ValidationNotElementFailedMessage(collection))
            }
            return value
        }
    }
    public func validate(_ value: T?) throws -> T? {
        return try block(value)
    }
}


// MARK: - RawRepresentable Validations

/// Validates that the tested value is a raw representation of the tested type.
public struct ValidationRawValue<T> : ValidationType where T: RawRepresentable {
    public init() { }
    public func validate(_ value: T.RawValue?) throws -> T {
        let value = try validateNotNil(value, message: ValidationRawValueFailedMessage(T.self))
        guard let result = T(rawValue: value) else {
            throw ValidationError(value: value, message: ValidationRawValueFailedMessage(T.self))
        }
        return result
    }
}


// MARK: - Range Validations

/// Validates the inclusion of the tested value in a range.
public struct ValidationRange<T> : ValidationType where T: Comparable, T: Comparable {
    let range: ValidRange<T>
    public init(minimum: T) {
        self.range = ValidRange.minimum(minimum)
    }
    public init(maximum: T) {
        self.range = ValidRange.maximum(maximum)
    }
    public init(range: Range<T>) {
        self.range = ValidRange.range(range)
    }
    public func validate(_ value: T?) throws -> T {
        switch range {
        case .minimum(let minimum):
            let value = try validateNotNil(value, message: ValidationMinimumFailedMessage(minimum))
            guard value >= minimum else {
                throw ValidationError(value: value, message: ValidationMinimumFailedMessage(minimum))
            }
            return value
        case .maximum(let maximum):
            let value = try validateNotNil(value, message: ValidationMaximumFailedMessage(maximum))
            guard value <= maximum else {
                throw ValidationError(value: value, message: ValidationMaximumFailedMessage(maximum))
            }
            return value
        case.range(let range):
            let value = try validateNotNil(value, message: ValidationRangeFailedMessage(range))
            guard range ~= value else {
                throw ValidationError(value: value, message: ValidationRangeFailedMessage(range))
            }
            return value
        }
    }
}
