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


## ValidationType

A validation checks a value of type TestedType, and eventually returns a value of type ValidType, or throws a ValidationError:

```swift
public protocol ValidationType {
    typealias TestedType
    typealias ValidType
    func validate(value: TestedType) throws -> ValidType
}
```


## Value Validation

```swift
// Positive integer
let v = ValidationRange(minimum: 0)
try v.validate(1)          // OK
try v.validate(nil)        // ValidationError: nil should be greater than or equal to 0.
try v.validate(-1)         // ValidationError: -1 should be greater than or equal to 0.
```

See the full list of [built-in validations](#built-in-validations) and the ways to [compose](#composed-validations) them.


## Model Validation

**Model validation** is different from value validation:

- **One needs to know which property is invalid.**
    
    For example: "name should not be empty."
    
- **One needs to validate a model as a whole.**
    
    For example: "Please provide an email or a phone number."
    
- **Validating a model may be a *mutating* operation.**
    
    For example, if a person's name must not be empty after whitespace trimming, one wants to update the name with the validated trimmed input.

Those three use cases are given by the Validable protocol:

```swift
public protocol Validable {}
extension Validable {
    /// Property validation. Returns the validated value:
    public func validateProperty(name: String, with: Validation) throws -> Validation.ValidType
    
    /// Global validation:
    public func validate(description: String, with: Validation) throws
}
```

A simple model:

```swift
struct Person: Validable {
    var name: String?
    
    func validate() throws {
        // Name should not be nil or empty.
        try validateProperty("name", with: name >>> ValidationStringLength(minimum: 1))
    }
}

let person = Person(name: "Arthur")
try person.validate()   // OK

let person = Person(name: nil)
try person.validate()
// Person validation error: name should not be empty.
```

A less simple model:

```swift
struct Person : Validable {
    var name: String?
    var age: Int?
    var email: String?
    var phoneNumber: String?
    
    mutating func validate() throws {
        // ValidationPlan doesn't fail on the first validation error. Instead,
        // it gathers all of them, and eventually throws a single ValidationError.
        try ValidationPlan()
            .append {
                // Name should not be empty after whitespace trimming:
                let nameValidation = ValidationTrim() >>> ValidationStringLength(minimum: 1)
                name = try validateProperty(
                    "name",
                    with: name >>> nameValidation)
            }
            .append {
                // Age should be nil, or positive:
                let ageValidation = ValidationNil() || ValidationRange(minimum: 0)
                try validateProperty(
                    "age",
                    with: age >>> ageValidation)
            }
            .append {
                // Email should be nil, or contain @ after whitespace trimming:
                let emailValidation = ValidationNil() || (ValidationTrim() >>> ValidationRegularExpression(pattern:"@"))
                email = try validateProperty(
                    "email",
                    with: email >>> emailValidation)
            }
            .append {
                // Phone number should be nil, or be a valid phone number.
                // ValidationPhoneNumber applies international formatting.
                let phoneNumberValidation = ValidationNil() || (ValidationTrim() >>> ValidationPhoneNumber(format: .International))
                phoneNumber = try validateProperty(
                    "phoneNumber",
                    with: phoneNumber >>> phoneNumberValidation)
            }
            .append {
                // An email or a phone number is required.
                try validate(
                    "Please provide an email or a phone number.",
                    with: email >>> ValidationNotNil() || phoneNumber >>> ValidationNotNil())
            }
            .validate()
    }
}

var person = Person(name: " Arthur ", age: 35, email: nil, phoneNumber: "0123456789  ")
try person.validate()   // OK
person.name!            // "Arthur" (trimmed)
person.phoneNumber!     // "+33 1 23 45 67 89" (trimmed & formatted)

var person = Person(name: nil, age: nil, email: "foo@bar.com", phoneNumber: nil)
try person.validate()
// Person validation error: name should not be empty.

var person = Person(name: "Arthur", age: -1, email: "foo@bar.com", phoneNumber: nil)
try person.validate()
// Person validation error: age should be greater than or equal to 0.

var person = Person(name: "Arthur", age: 35, email: nil, phoneNumber: nil)
try person.validate()
// Person validation error: Please provide an email or a phone number.

var person = Person(name: "Arthur", age: 35, email: "foo", phoneNumber: nil)
try person.validate()
// Person validation error: email is invalid.
```


### Built-in Validations

| Validation type              | TestedType      | ValidType       |            |
|:---------------------------- |:--------------- |:--------------- |:---------- |
| Validation                   | T               | T               | All values pass. |
| ValidationFailure            | T               | T               | All values fail. |
| ValidationNil                | T?              | T?              | Checks that input is nil. |
| ValidationNotNil             | T?              | T               | Checks that input is not nil. |
| ValidationTrim               | String?         | String?         | All strings pass. Non nil strings are trimmed. |
| ValidationStringLength       | String?         | String          | Checks that a string is not nil and has length in a specific range. |
| ValidationRegularExpression  | String?         | String          | Checks that a string is not nil and matches a regular expression. |
| ValidationCollectionNotEmpty | CollectionType? | CollectionType  | Checks that a collection is not nil and not empty. |
| ValidationCollectionEmpty    | CollectionType? | CollectionType? | Checks that a collection is nil or empty. |
| ValidationEqual              | T? where T:Equatable | T          | Checks that a value is not nil and equal to a reference value. |
| ValidationNotEqual           | T? where T:Equatable | T?         | Checks that a value is nil or not equal to a reference value. |
| ValidationElementOf          | T? where T:Equatable | T          | Checks that a value is not nil and member of a reference collection. |
| ValidationNotElementOf       | T? where T:Equatable | T?         | Checks that a value is nil or not member of a reference collection. |
| ValidationRawValue           | T.RawValue? where T: RawRepresentable | T | Checks that a value is not nil and a valid raw value for type T. |
| ValidationRange              | T? where T: ForwardIndexType, T: Comparable | T | Checks that a value is not nil and in a specific range. |


### Composed Validations

| Operator |           |
|:-------- |:--------- |
| `||`     | Returns the value returned by the first validation that passes. |
| `&&`     | Checks that a value passes all validations. The returned value is the input value. |
| `>>>`    | Chains two validations. Returns the value returned by the right validation. |

Examples:

```swift
// Checks that an Int is not nil and equal to 1 or 2:
let v = ValidationEqual(1) || ValidationEqual(2)
v.validate(1)   // OK: 1
v.validate(3)   // OK: 3
v.validate(nil) // ValidationError

// Checks that an Int is nil, not 1, and not 2:
let v = ValidationNotEqual(1) && ValidationNotEqual(2)
v.validate(3)   // OK: 3
v.validate(nil) // OK: nil
v.validate(1)   // ValidationError

// Checks that a string matches a regular expression, after trimming:
let v = ValidationTrim() >>> ValidationRegularExpression(pattern: "^a+$")
v.validate(" aaa ") // OK: "aaa"
```

