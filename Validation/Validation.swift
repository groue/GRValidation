//
//  Validation.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

import Foundation


// MARK: - Validation

public protocol ValidationType {
    typealias TestedType
    typealias ValidType
    func validate(value: TestedType) throws -> ValidType
}

/// A type-erased validation.
public struct AnyValidation<TestedType, ValidType> : ValidationType {
    /// Wrap and forward operations to `base`.
    public init<V: ValidationType where V.TestedType == TestedType, V.ValidType == ValidType>(_ base: V) {
        self.init { return try base.validate($0) }
    }
    /// Create a validation whose `validate()` method forwards to `block`.
    public init(_ block: (TestedType) throws -> ValidType) {
        self.block = block
    }
    public func validate(value: TestedType) throws -> ValidType {
        return try block(value)
    }
    private let block: (TestedType) throws -> ValidType
}


// MARK: - Model Validations

public struct PropertyValidation<T> : ValidationType {
    let block: (T) throws -> T
    public init<Validation: ValidationType where Validation.TestedType == T>(_ propertyName: String, _ validation: Validation) {
        self.block = {
            do {
                try validation.validate($0)
                return $0
            } catch let error as ValidationError {
                throw ValidationError.Property(owner: $0, propertyName: propertyName, error: error)
            }
        }
    }
    public func validate(value: T) throws -> T {
        return try block(value)
    }
}

public struct GlobalValidation<T> : ValidationType {
    let block: (T) throws -> T
    public init<Validation: ValidationType where Validation.TestedType == T>(_ description: String, _ validation: Validation) {
        self.block = {
            do {
                try validation.validate($0)
                return $0
            } catch let error as ValidationError {
                throw ValidationError.Global(owner: $0, description: description, error: error)
            }
        }
    }
    public func validate(value: T) throws -> T {
        return try block(value)
    }
}


// MARK: - Composed Validations

// V(T -> U) >> V(U -> V)
public func >> <Left : ValidationType, Right : ValidationType where Left.ValidType == Right.TestedType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Right.ValidType> {
    return AnyValidation { try right.validate(left.validate($0)) }
}
// V(T -> U) >> V(U? -> V)
public func >> <Left : ValidationType, Right : ValidationType where Right.TestedType == Optional<Left.ValidType>>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Right.ValidType> {
    return AnyValidation { try right.validate(left.validate($0)) }
}

// ValidationNotNil() >> { $0... }
// TODO: is it a flatMap?
public func >> <Left : ValidationType, ValidType>(left: Left, right: (Left.ValidType) -> ValidType) -> AnyValidation<Left.TestedType, ValidType> {
    return AnyValidation { try right(left.validate($0)) }
}

// { $0.name } >> ValidationNotNil()
public func >> <T, Right : ValidationType>(left: (T) -> Right.TestedType, right: Right) -> AnyValidation<T, Right.ValidType> {
    return AnyValidation { try right.validate(left($0)) }
}

public func ||<Left : ValidationType, Right : ValidationType where Left.TestedType == Right.TestedType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Left.TestedType> {
    return AnyValidation {
        do {
            try left.validate($0)
        } catch let leftError as ValidationError {
            do {
                try right.validate($0)
            } catch let rightError as ValidationError {
                throw ValidationError.Multiple([leftError, rightError])
            }
        }
        
        return $0
    }
}

public func &&<Left : ValidationType, Right : ValidationType where Left.TestedType == Right.TestedType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Left.TestedType> {
    return AnyValidation {
        var errors = [ValidationError]()
        
        do {
            try left.validate($0)
        } catch let error as ValidationError {
            errors.append(error)
        }
        
        do {
            try right.validate($0)
        } catch let error as ValidationError {
            errors.append(error)
        }
        
        switch errors.count {
        case 0:
            return $0
        case 1:
            throw errors.first!
        default:
            throw ValidationError.Multiple(errors)
        }
    }
}


// MARK: - Concrete Validations

// TODO: check for performance penalty using only ForwardIndexType, and see whether RandomAccessIndexType performs better.
public enum ValidRange<T where T: ForwardIndexType, T: Comparable> {
    case Minimum(T)
    case Maximum(T)
    case Range(Swift.Range<T>)
}

public struct Validation<T> : ValidationType {
    public init() { }
    public func validate(value: T) throws -> T {
        return value
    }
}

public struct ValidationFailure<T> : ValidationType {
    public init() { }
    public func validate(value: T) throws -> T {
        throw ValidationError.Value(value: value, message: "is invalid.")
    }
}

public struct ValidationNil<T> : ValidationType {
    public init() { }
    public func validate(value: T?) throws -> T? {
        guard value == nil else {
            throw ValidationError.Value(value: value, message: "should be nil.")
        }
        return nil
    }
}

public struct ValidationNotNil<T> : ValidationType {
    public init() { }
    public func validate(value: T?) throws -> T {
        guard let notNilValue = value else {
            throw ValidationError.Value(value: value, message: "should not be nil.")
        }
        return notNilValue
    }
}

public struct ValidationStringNotEmpty : ValidationType {
    public init() { }
    public func validate(string: String?) throws -> String {
        guard let string = string else {
            throw ValidationError.Value(value: nil, message: "should not be nil.")
        }
        guard string.characters.count > 0 else {
            throw ValidationError.Value(value: string, message: "should not be empty.")
        }
        return string
    }
}

public struct ValidationStringLength : ValidationType {
    let range: ValidRange<Int>
    public init(minimum: Int) {
        self.range = ValidRange.Minimum(minimum)
    }
    public init(maximum: Int) {
        self.range = ValidRange.Maximum(maximum)
    }
    public init(range: Range<Int>) {
        self.range = ValidRange.Range(range)
    }
    public func validate(string: String?) throws -> String {
        guard let string = string else {
            throw ValidationError.Value(value: nil, message: "should not be nil.")
        }
        let length = string.characters.count
        switch range {
        case .Minimum(let minimum):
            guard length >= minimum else {
                throw ValidationError.Value(value: string, message: "should contain at least \(minimum) characters.")
            }
        case .Maximum(let maximum):
            guard length <= maximum else {
                throw ValidationError.Value(value: string, message: "should contain at most \(maximum) characters.")
            }
        case.Range(let range):
            guard range ~= length else {
                throw ValidationError.Value(value: string, message: "length should be in \(range).")
            }
        }
        return string
    }
}

public struct ValidationNotEmpty<C: CollectionType> : ValidationType {
    public init() { }
    public func validate(collection: C?) throws -> C {
        guard let collection = collection else {
            throw ValidationError.Value(value: nil, message: "should not be nil.")
        }
        guard collection.count > 0 else {
            throw ValidationError.Value(value: collection, message: "should not be empty.")
        }
        return collection
    }
}

public struct ValidationEqual<T where T: Equatable> : ValidationType {
    public let target: T
    public init(_ target: T) {
        self.target = target
    }
    public func validate(value: T?) throws -> T {
        guard let value = value else {
            throw ValidationError.Value(value: nil, message: "should not be nil.")
        }
        guard value == target else {
            throw ValidationError.Value(value: value, message: "should be equal to \(String(reflecting: target)).")
        }
        return value
    }
}

public struct ValidationNotEqual<T where T: Equatable> : ValidationType {
    public let target: T
    public init(_ target: T) {
        self.target = target
    }
    public func validate(value: T?) throws -> T {
        guard let value = value else {
            throw ValidationError.Value(value: nil, message: "should not be nil.")
        }
        guard value != target else {
            throw ValidationError.Value(value: value, message: "should not be equal to \(String(reflecting: target)).")
        }
        return value
    }
}

public struct ValidationRawValue<T where T: RawRepresentable> : ValidationType {
    public init() { }
    public func validate(value: T.RawValue?) throws -> T {
        guard let value = value else {
            throw ValidationError.Value(value: nil, message: "should not be nil.")
        }
        guard let result = T(rawValue: value) else {
            throw ValidationError.Value(value: value, message: "is invalid.")
        }
        return result
    }
}

public struct ValidationRange<T where T: ForwardIndexType, T: Comparable> : ValidationType {
    let range: ValidRange<T>
    public init(minimum: T) {
        self.range = ValidRange.Minimum(minimum)
    }
    public init(maximum: T) {
        self.range = ValidRange.Maximum(maximum)
    }
    public init(range: Range<T>) {
        self.range = ValidRange.Range(range)
    }
    public func validate(value: T?) throws -> T {
        guard let value = value else {
            throw ValidationError.Value(value: nil, message: "should not be nil.")
        }
        switch range {
        case .Minimum(let minimum):
            guard value >= minimum else {
                throw ValidationError.Value(value: value, message: "should be greater or equal to \(String(reflecting: minimum)).")
            }
        case .Maximum(let maximum):
            guard value <= maximum else {
                throw ValidationError.Value(value: value, message: "should be less or equal to \(String(reflecting: maximum)).")
            }
        case.Range(let range):
            guard range ~= value else {
                throw ValidationError.Value(value: value, message: "should be in \(String(reflecting: range)).")
            }
        }
        return value
    }
}

public struct ValidationRegularExpression : ValidationType {
    public let regex: NSRegularExpression
    public init(_ regex: NSRegularExpression) {
        self.regex = regex
    }
    public init(pattern: String) {
        try! self.init(NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions()))
    }
    public func validate(string: String?) throws -> String {
        guard let string = string else {
            throw ValidationError.Value(value: nil, message: "should not be nil.")
        }
        let nsString = string as NSString
        let match = regex.rangeOfFirstMatchInString(string, options: NSMatchingOptions(), range: NSRange(location: 0, length: nsString.length))
        guard match.location != NSNotFound else {
            throw ValidationError.Value(value: string, message: "is invalid.")
        }
        return string
    }
}
