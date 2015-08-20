//
//  Validation.swift
//  Validation
//
//  Created by Gwendal Roué on 20/08/2015.
//  Copyright © 2015 Gwendal Roué. All rights reserved.
//

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


extension Validation {
    public func flatMap<Result>(block: (OutputType) -> Result) -> AnyValidation<InputType, Result> {
        return AnyValidation { value in
            return try block(self.validate(value))
        }
    }
}

public struct ComposedValidation<V1 : Validation, V2 : Validation where V1.OutputType == V2.InputType> : Validation {
    let left: V1
    let right: V2
    
    public func validate(value: V1.InputType) throws -> V2.OutputType {
        return try right.validate(left.validate(value))
    }
}

infix operator >>> { associativity left }
public func >>> <V1 : Validation, V2 : Validation where V1.OutputType == V2.InputType>(left: V1, right: V2) -> ComposedValidation<V1, V2> {
    return ComposedValidation(left: left, right: right)
}

public struct OrValidation<V1 : Validation, V2 : Validation where V1.InputType == V2.InputType, V1.OutputType == V2.OutputType> : Validation {
    let left: V1
    let right: V2
    
    public func validate(value: V1.InputType) throws -> V1.OutputType {
        do {
            return try left.validate(value)
        } catch {
            return try right.validate(value)
        }
    }
}

public func ||<V1 : Validation, V2 : Validation where V1.InputType == V2.InputType, V1.OutputType == V2.OutputType>(left: V1, right: V2) -> OrValidation<V1, V2> {
    return OrValidation(left: left, right: right)
}

public struct ValidationNotNil<T> : Validation {
    public init() { }
    public func validate(value: T?) throws -> T {
        guard let notNilValue = value else {
            throw ValidationError(value: value, description: "should not be nil")
        }
        return notNilValue
    }
}

// TODO: should not only apply to string
public struct ValidationNotEmpty: Validation {
    public init() { }
    public func validate(string: String) throws -> String {
        guard string.characters.count > 0 else {
            throw ValidationError(value: string, description: "should not be empty")
        }
        return string
    }
}

public struct ValidationGreaterThanOrEqual<T where T:Comparable> : Validation {
    public let minimum: T
    public init(_ minimum: T) {
        self.minimum = minimum
    }
    public func validate(value: T) throws -> T {
        guard value > minimum else {
            throw ValidationError(value: value, description: "should be greater than \(minimum)")
        }
        return value
    }
}

public struct ValidationLessThanOrEqual<T where T:Comparable> : Validation {
    public let maximum: T
    public init(_ maximum: T) {
        self.maximum = maximum
    }
    public func validate(value: T) throws -> T {
        guard value < maximum else {
            throw ValidationError(value: value, description: "should be less than \(maximum)")
        }
        return value
    }
}
