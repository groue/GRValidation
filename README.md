GRValidation
============

Experiments with validation in Swift 2.

- [X] validation of values
- [X] validation of object properties
- [X] custom validations
- [ ] built-in error localization
- [ ] custom localization of built-in errors
- [X] global validation of an object (like "Please provide a phone number or an email")
- [X] full list of validation errors in a value ("Value should be odd. Value should be less than 10.")
- [X] full list of validation errors in an object ("Email is empty. Password is empty.")
- [ ] full list of validation errors for a property name
- [X] Validate that a value may be missing (nil), but, if present, must conform to some rules.
- [ ] Distinguish property validation error from named validation error ("User has invalid name" vs. "Name is invalid" which applies to UITextFields for example)
- [X] A model should be able, in the same time, to 1. store transformed properties (through a phone number validation that returns an internationally formatted phone number) 2. get a full list of validation errors on the model. Without having to write a complex do catch dance.


## Value validation

```swift
// Positive integer
let v = ValidationRange(minimum: 0)
try v.validate(1)          // OK
try v.validate(nil)        // ValidationError
try v.validate(-1)         // ValidationError

// String that contains "foo" and "bar"
let v = ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar")
try v.validate("foobar")   // OK
try v.validate(nil)        // ValidationError
try v.validate("baz")      // ValidationError

// String that is nil, or not empty:
let v = ValidationNil<String>() || ValidationStringNotEmpty()
try v.validate(nil)        // OK
try v.validate("Foo")      // OK
try v.validate("")         // ValidationError
```


## Model validation

```swift
struct Person : Validable {
    let name: String?
    
    func validate() throws {
        try validate(name, forName: "name", with: ValidationNotNil())
    }
}

let person = Person(name: nil)
try! person.validate()
// ValidationError "Person validation error: name should not be nil."
```
