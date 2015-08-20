//
//  Validation.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

import Foundation


// MARK: - Validation

public protocol Validation {
    typealias InputType
    typealias OutputType
    func validate(value: InputType) throws -> OutputType
}

/// A type-erased validation.
public struct AnyValidation<InputType, OutputType> : Validation {
    /// Wrap and forward operations to `base`.
    public init<V: Validation where V.InputType == InputType, V.OutputType == OutputType>(_ base: V) {
        self.init { return try base.validate($0) }
    }
    /// Create a validation whose `validate()` method forwards to `block`.
    public init(_ block: (InputType) throws -> OutputType) {
        self.block = block
    }
    public func validate(value: InputType) throws -> OutputType {
        return try block(value)
    }
    private let block: (InputType) throws -> OutputType
}


// MARK: - Composed Validations

extension Validation {
    public func flatMap<Result>(block: (OutputType) -> Result) -> AnyValidation<InputType, Result> {
        return AnyValidation { try block(self.validate($0)) }
    }
}

infix operator >>> { associativity left }
public func >>> <Left : Validation, Right : Validation where Left.OutputType == Right.InputType>(left: Left, right: Right) -> AnyValidation<Left.InputType, Right.OutputType> {
    return AnyValidation { return try right.validate(left.validate($0)) }
}

public func ||<Left : Validation, Right : Validation where Left.InputType == Right.InputType>(left: Left, right: Right) -> AnyValidation<Left.InputType, Left.InputType> {
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

public func &&<Left : Validation, Right : Validation where Left.InputType == Right.InputType>(left: Left, right: Right) -> AnyValidation<Left.InputType, Left.InputType> {
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

public struct ValidationSuccess<T>: Validation {
    public init() { }
    public func validate(value: T) throws -> T {
        return value
    }
}

public struct ValidationFailure<T>: Validation {
    public init() { }
    public func validate(value: T) throws -> T {
        throw ValidationError(value: value, message: "is invalid.")
    }
}

public struct ValidationNotNil<T> : Validation {
    public init() { }
    public func validate(value: T?) throws -> T {
        guard let notNilValue = value else {
            throw ValidationError(value: value, message: "should not be nil.")
        }
        return notNilValue
    }
}

public struct ValidationStringNotEmpty : Validation {
    public init() { }
    public func validate(string: String) throws -> String {
        guard string.characters.count > 0 else {
            throw ValidationError(value: string, message: "should not be empty.")
        }
        return string
    }
}

public struct ValidationNotEmpty<C: CollectionType>: Validation {
    public init() { }
    public func validate(collection: C) throws -> C {
        guard collection.count > 0 else {
            throw ValidationError(value: collection, message: "should not be empty.")
        }
        return collection
    }
}

public struct ValidationEqual<T where T: Equatable> : Validation {
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

public struct ValidationNotEqual<T where T: Equatable> : Validation {
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

public struct ValidationRawValue<T where T: RawRepresentable> : Validation {
    public init() { }
    public func validate(value: T.RawValue) throws -> T {
        guard let result = T(rawValue: value) else {
            throw ValidationError(value: value, message: "is invalid.")
        }
        return result
    }
}

public struct ValidationGreaterThanOrEqual<T where T: Comparable> : Validation {
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

public struct ValidationLessThanOrEqual<T where T: Comparable> : Validation {
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

public struct ValidationRange<T where T: ForwardIndexType, T: Comparable> : Validation {
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

public struct ValidationRegularExpression : Validation {
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
