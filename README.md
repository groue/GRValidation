GRValidation
============

GRValidation is a validation toolkit for Swift 2.

It lets you validate both simple values and complex models, and won't let you down when your validations leave the trivial zone.


Features
--------

- Type safety
- Value validation
- Value reparation
- Complex model validation

Missing features so far:

- Localization of validation errors
- Introspection of validation errors


Value Validation vs. Model Validation
-------------------------------------

GRValidation distinguishes *Value Validation* from *Model Validation*.

Precisely speaking, **Value Validation** throws errors like "12 should be greater than 10", and is responsible for:

- **Value Checking**, as in "is this string empty?"
- **Value Reparation**: lets check and format this phone number.
- **Composition**: several validations can be composed in a single more complex one, as in "this string should be nil, or not empty".

Model validation, on the other side, throws errors like "name should not be empty". It is built on top of value validation and provides:

- **Property validation**, as in "Name should not be empty."
- **Global validation**, as in "Please provide an email or a phone number."
- **Mutating validations**. Let's put value reparation to some use: for example, after successful validation of a user-provided phone number, one wants to update it with its formatted version.


Those two realms are represented by the two protocols `ValidationType` and `Validable`.


### ValidationType

**ValidationType** is a protocol that checks a value of type TestedType, and eventually returns a value of type ValidType, or throws a ValidationError:

```swift
public protocol ValidationType {
    typealias TestedType
    typealias ValidType
    func validate(value: TestedType) throws -> ValidType
}
```

For example:

```swift
// Positive integer
let v = ValidationRange(minimum: 0)
try v.validate(1)   // OK
try v.validate(nil) // ValidationError: nil should be greater than or equal to 0.
try v.validate(-1)  // ValidationError: -1 should be greater than or equal to 0.
```

See the full list of [built-in Value Validations](#built-in-value-validations) and the ways to [compose](#composed-validations) them.


### Validable

The **Validable** protocol provides two methods that help validating a property, or a full model as a whole:

```swift
public protocol Validable {}
extension Validable {
    /// Property validation. Returns the validated value:
    public func validateProperty(name: String, with: Validation) throws -> Validation.ValidType
    
    /// Global validation:
    public func validate(description: String, with: Validation) throws
}
```

Let's start with a simple model:

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


Feel at your ease, and don't hesitate building more complex validations:

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
person.name             // "Arthur" (trimmed)
person.phoneNumber      // "+33 1 23 45 67 89" (trimmed & formatted)

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


Built-in Value Validations
--------------------------

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


Composed Validations
--------------------

| Operator |           |
|:-------- |:--------- |
| `||`     | Returns the value returned by the first validation that passes. |
| `&&`     | Checks that a value passes all validations. The returned value is the input value. |
| `>>>`    | Chains two validations. Returns the value returned by the right validation. |

Examples:

```swift
// Checks that an Int is not nil and equal to 1 or 2:
let v = ValidationEqual(1) || ValidationEqual(2)

// Checks that an Int is nil, or not 1, and not 2:
let v = ValidationNotEqual(1) && ValidationNotEqual(2)

// Checks that a string matches a regular expression, after trimming:
let v = ValidationTrim() >>> ValidationRegularExpression(pattern: "^a+$")
```
