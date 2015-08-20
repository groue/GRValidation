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
    public init<Validation: ValidationType, PropertyType where Validation.TestedType == PropertyType>(_ propertyName: String, _ propertyBlock: (T) -> PropertyType, _ validation: Validation) {
        self.block = {
            do {
                try validation.validate(propertyBlock($0))
                return $0
            } catch let error as ValidationError {
                throw ValidationError(propertyName: propertyName, error: error)
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
                throw ValidationError(description: description, error: error)
            }
        }
    }
    public func validate(value: T) throws -> T {
        return try block(value)
    }
}


// MARK: - Composed Validations

extension ValidationType {
    // TODO: is it a real flatMap? Is ValidationType a Monad?
    public func flatMap<Result>(block: (ValidType) -> Result) -> AnyValidation<TestedType, Result> {
        return AnyValidation { try block(self.validate($0)) }
    }
}

infix operator >>> { associativity left }
public func >>> <Left : ValidationType, Right : ValidationType where Left.ValidType == Right.TestedType>(left: Left, right: Right) -> AnyValidation<Left.TestedType, Right.ValidType> {
    return AnyValidation { try right.validate(left.validate($0)) }
}

// ValidationNotNil() >>> { $0... }
// Identical to flatMap
// TODO: make a choice between operator and flatMap.
public func >>> <Left : ValidationType, ValidType>(left: Left, right: (Left.ValidType) -> ValidType) -> AnyValidation<Left.TestedType, ValidType> {
    return AnyValidation { try right(left.validate($0)) }
}

// { $0.name } >>> ValidationNotNil()
public func >>> <T, Right : ValidationType>(left: (T) -> Right.TestedType, right: Right) -> AnyValidation<T, Right.ValidType> {
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
                throw ValidationError(children: [leftError, rightError])
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
            throw ValidationError(children: errors)
        }
    }
}


// MARK: - Concrete Validations

public struct Validation<T> : ValidationType {
    public init() { }
    public func validate(value: T) throws -> T {
        return value
    }
}

public struct ValidationFailure<T> : ValidationType {
    public init() { }
    public func validate(value: T) throws -> T {
        throw ValidationError(value: value, message: "is invalid.")
    }
}

public struct ValidationNotNil<T> : ValidationType {
    public init() { }
    public func validate(value: T?) throws -> T {
        guard let notNilValue = value else {
            throw ValidationError(value: value, message: "should not be nil.")
        }
        return notNilValue
    }
}

public struct ValidationStringNotEmpty : ValidationType {
    public init() { }
    public func validate(string: String) throws -> String {
        guard string.characters.count > 0 else {
            throw ValidationError(value: string, message: "should not be empty.")
        }
        return string
    }
}

public struct ValidationNotEmpty<C: CollectionType> : ValidationType {
    public init() { }
    public func validate(collection: C) throws -> C {
        guard collection.count > 0 else {
            throw ValidationError(value: collection, message: "should not be empty.")
        }
        return collection
    }
}

public struct ValidationEqual<T where T: Equatable> : ValidationType {
    public let target: T
    public init(_ target: T) {
        self.target = target
    }
    public func validate(value: T) throws -> T {
        guard value == target else {
            throw ValidationError(value: value, message: "should be equal to \(String(reflecting: target)).")
        }
        return value
    }
}

public struct ValidationNotEqual<T where T: Equatable> : ValidationType {
    public let target: T
    public init(_ target: T) {
        self.target = target
    }
    public func validate(value: T) throws -> T {
        guard value != target else {
            throw ValidationError(value: value, message: "should not be equal to \(String(reflecting: target)).")
        }
        return value
    }
}

public struct ValidationRawValue<T where T: RawRepresentable> : ValidationType {
    public init() { }
    public func validate(value: T.RawValue) throws -> T {
        guard let result = T(rawValue: value) else {
            throw ValidationError(value: value, message: "is invalid.")
        }
        return result
    }
}

public struct ValidationGreaterThanOrEqual<T where T: Comparable> : ValidationType {
    public let minimum: T
    public init(_ minimum: T) {
        self.minimum = minimum
    }
    public func validate(value: T) throws -> T {
        guard value >= minimum else {
            throw ValidationError(value: value, message: "should be greater or equal to \(String(reflecting: minimum)).")
        }
        return value
    }
}

public struct ValidationLessThanOrEqual<T where T: Comparable> : ValidationType {
    public let maximum: T
    public init(_ maximum: T) {
        self.maximum = maximum
    }
    public func validate(value: T) throws -> T {
        guard value <= maximum else {
            throw ValidationError(value: value, message: "should be less or equal to \(String(reflecting: maximum)).")
        }
        return value
    }
}

public struct ValidationRange<T where T: ForwardIndexType, T: Comparable> : ValidationType {
    public let range: Range<T>
    public init(_ range: Range<T>) {
        self.range = range
    }
    public func validate(value: T) throws -> T {
        guard range ~= value else {
            throw ValidationError(value: value, message: "should be in \(String(reflecting: range)).")
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
    public func validate(string: String) throws -> String {
        let nsString = string as NSString
        let match = regex.rangeOfFirstMatchInString(string, options: NSMatchingOptions(), range: NSRange(location: 0, length: nsString.length))
        guard match.location != NSNotFound else {
            throw ValidationError(value: string, message: "is invalid.")
        }
        return string
    }
}
