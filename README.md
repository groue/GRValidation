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
- [ ] It is possible to identify the properties involved in a failed global validation (and, for example, select the email text field after the "Please provide a phone number or an email" error).
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

// Phone number
let v = ValidationPhoneNumber(format: .International)   //
let validPhoneNumber = try v.validate("044 668 18 00")
```


## Model validation

```swift
struct Person : Validable {
    var name: String?
    var age: Int?
    var email: String?
    var phoneNumber: String?
    
    mutating func validate() throws {
        // Name should not be empty after whitespace trimming:
        let nameValidation = ValidationTrim() >>> ValidationStringLength(minimum: 1)
        name = try validateProperty(
            "name",
            with: name >>> nameValidation)
        
        // Age should be nil, or positive:
        let ageValidation = ValidationNil() || ValidationRange(minimum: 0)
        try validateProperty(
            "age",
            with: age >>> ageValidation)
        
        // Email should be nil, or contain @ after whitespace trimming:
        let emailValidation = ValidationNil() || (ValidationTrim() >>> ValidationRegularExpression(pattern:"@"))
        email = try validateProperty(
            "email",
            with: email >>> emailValidation)
        
        // Phone number should be nil, or be a valid phone number.
        // ValidationPhoneNumber applies international formatting.
        let phoneNumberValidation = ValidationNil() || (ValidationTrim() >>> ValidationPhoneNumber(format: .International))
        phoneNumber = try validateProperty(
            "phoneNumber",
            with: phoneNumber >>> phoneNumberValidation)
        
        // An email or a phone number is required.
        try validate(
            "Please provide an email or a phone number.",
            with: email >>> ValidationNotNil() || phoneNumber >>> ValidationNotNil())
    }
}

var person = Person(name: " Arthur ", age: 35, email: nil, phoneNumber: "0123456789  ")
try person.validate()   // OK
person.name!            // "Arthur" (trimmed)
person.phoneNumber!     // "+33 1 23 45 67 89" (trimmed & formatted)

var person = Person(name: nil, age: nil, email: nil, phoneNumber: nil)
try person.validate()
// Person validation error: name should not be empty.

var person = Person(name: "Arthur", age: -1, email: nil, phoneNumber: nil)
try person.validate()
// Person validation error: age should be greater than or equal to 0.

var person = Person(name: "Arthur", age: 35, email: nil, phoneNumber: nil)
try person.validate()
// Person validation error: Please provide an email or a phone number.

var person = Person(name: "Arthur", age: 35, email: "foo", phoneNumber: nil)
try person.validate()
// Person validation error: email is invalid.
