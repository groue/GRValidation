GRValidation
============

Experiments with validation in Swift 2.

- [X] Type safety
- [X] Value validation
- [X] Object property validation
- [X] Custom validations
- [X] Validations may transform their input
- [ ] Built-in error localization
- [ ] Custom localization of built-in errors
- [X] Global validation of an object (like "Please provide a phone number or an email")
- [X] Full list of validation errors in a value ("Value should be odd. Value should be less than 10.")
- [X] Full list of validation errors in an object ("Email is empty. Password is empty.")
- [ ] Full list of validation errors for a property name
- [X] Validate that a value may be missing (nil), but, if present, must conform to some rules.
- [ ] Distinguish property validation error from named validation error ("User has invalid name" vs. "Name is invalid" which applies to UITextFields for example)
- [X] A model should be able, in the same time, to 1. store transformed properties (through a phone number validation that returns an internationally formatted phone number) 2. get a full list of validation errors on the model. Without having to write a complex do catch dance.


## Value validation

```swift
// Positive integer
let v = ValidationRange(minimum: 0)
try v.validate(1)          // OK
try v.validate(nil)        // ValidationError: nil should be greater than or equal to 0.
try v.validate(-1)         // ValidationError: -1 should be greater than or equal to 0.

// String that contains "foo" and "bar"
let v = ValidationRegularExpression(pattern: "foo") && ValidationRegularExpression(pattern: "bar")
try v.validate("foobar")   // OK
try v.validate(nil)        // ValidationError: nil is invalid.
try v.validate("baz")      // ValidationError: "baz" is invalid.

// String that is nil, or not empty:
let v = ValidationNil() || ValidationStringNotEmpty()
try v.validate(nil)        // OK
try v.validate("Foo")      // OK
try v.validate("")         // ValidationError: "" should not be empty.
```


## Model validation

```swift
struct Person : Validable {
    let name: String?
    
    func validate() throws {
        try validate(name, forName: "name", with: ValidationStringNotEmpty())
    }
}

let person = Person(name: nil)
try! person.validate()
// ValidationError: Person validation error: name should not be nil.
```
