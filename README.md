GRValidation
============

GRValidation is a validation toolkit for Swift 2.

It lets you validate both simple values and complex models, and won't let you down when your validations leave the trivial zone.

**August 25, 2015: GRValidation 0.2.0 is out** - [Release notes](CHANGELOG.md). Follow [@groue](http://twitter.com/groue) on Twitter for release announcements and usage tips.


Features
--------

- Type safety
- Value validation
- Value reparation
- Complex model validation
- Detailed error messages

Missing features so far:

- Localization of validation errors
- Introspection of validation errors


Value Validation vs. Model Validation
-------------------------------------

GRValidation distinguishes *Value Validation* from *Model Validation*.

Precisely speaking, **Value Validation** throws errors like "12 should be greater than 18", and is responsible for:

- **Value Checking**, as in "is this string empty?"
- **Value Reparation**: for example, let's trim, validate, and format this user-provided phone number.
- **Composition**: several validations can be composed in a single more complex one, as in "this string should be nil, or not empty".

**Model validation**, on the other side, throws errors like "age should be greater than 18". It is built on top of value validation and provides:

- **Property validation**, as in "name should not be empty."
- **Global validation**, as in "Please provide an email or a phone number."
- **Mutating validations**. This is value reparation, put to some use: for example, after successful validation of a user-provided phone number, one wants to store its formatted version.


Documentation
-------------

- [Value Validation](#value-validation)
    - [The ValidationType Protocol](#the-validationtype-protocol)
    - [ValidationError vs Boolean Check](#validationerror-vs-boolean-check)
    - [Built-in Value Validations](#built-in-value-validations)
    - [Composed Validations](#composed-validations)
- [Model Validation](#model-validation)
    - [The Validable Protocol](#the-validable-protocol)


## Value Validation

### The ValidationType Protocol

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
try v.validate(1)   // OK: 1
try v.validate(nil) // ValidationError: nil should be greater than or equal to 0.
try v.validate(-1)  // ValidationError: -1 should be greater than or equal to 0.
```

The returned value may be different from the input:

```swift
enum Color : Int {
    case Red
    case White
    case Rose
}
let v = ValidationRawValue<Color>()
try v.validate(0)   // OK: Color.Red
try v.validate(3)   // ValidationError: 3 is an invalid Color.
```


### ValidationError vs Boolean Check

The validate() method may throw a ValidationError:

```swift
let positiveInt = ValidationRange(minimum: 0)
try positiveInt.validate(-1)    // Throws a ValidationError
```

You may also perform a simple boolean check with the `~=` operator, or via pattern matching:

```swift
positiveInt ~= 10  // true
positiveInt ~= -1  // false

switch int {
case positiveInt:
    // int passes validation
    ...
}
```


### Built-in Value Validations

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

Basic Value Validations can be chained, or composed using boolean operators:

- `v1 >>> v2`
    
    Chains two validations. Returns the value returned by v2.
    
    ```swift
    // Checks that a string matches a regular expression, after trimming:
    let v = ValidationTrim() >>> ValidationRegularExpression(pattern: "^[0-9]+$")
    try v.validate(" 123 ") // "123"
    try v.validate("foo")   // ValidationError
    ```
    
- `v1 || v2`
    
    Checks that a value passes at least one validation. Returns the value returned by the first validation that passes, or the input value when output types don't match.
    
    ```swift
    // Checks that an Int is not nil and equal to 1 or 2:
    let v = ValidationEqual(1) || ValidationEqual(2)
    try v.validate(1) // 1
    try v.validate(2) // 2
    try v.validate(3) // ValidationError
    ```
    
- `v1 && v2`
    
    Checks that a value passes both validations. Returns the value returned by v2.
    
    ```swift
    // Checks that an Int is nil, or not 1, and not 2:
    let v = ValidationNotEqual(1) && ValidationNotEqual(2)
    try v.validate(1) // ValidationError
    try v.validate(2) // ValidationError
    try v.validate(3) // 3
    ```
    
- `!v1`

    Inverts a validation. Returns the input value, or throws a generic "is invalid." error.
    
    ```swift
    // Checks that an Int is not 1.
    let v = !ValidationEqual(1)
    try v.validate(1) // ValidationError
    try v.validate(2) // 2
    ```


## Model Validation

### The Validable Protocol

The **Validable** protocol provides methods that help validating models.

Let's start with a simple model:

```swift
struct Person: Validable {
    var name: String?
    
    func validate() throws {
        // Name should not be nil or empty.
        try validate(property: "name", with: name >>> ValidationStringLength(minimum: 1))
    }
}

let person = Person(name: "Arthur")
try person.validate()   // OK

let person = Person(name: nil)
try person.validate()
// Invalid Person(name: nil): name should not be empty.
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
                name = try validate(
                    property: "name",
                    with: name >>> nameValidation)
            }
            .append {
                // Age should be nil, or positive:
                let ageValidation = ValidationNil() || ValidationRange(minimum: 0)
                try validate(
                    property: "age",
                    with: age >>> ageValidation)
            }
            .append {
                // Email should be nil, or contain @ after whitespace trimming:
                let emailValidation = ValidationNil() || (ValidationTrim() >>> ValidationRegularExpression(pattern:"@"))
                email = try validate(
                    property: "email",
                    with: email >>> emailValidation)
            }
            .append {
                // Phone number should be nil, or be a valid phone number.
                // ValidationPhoneNumber applies international formatting.
                let phoneNumberValidation = ValidationNil() || (ValidationTrim() >>> ValidationPhoneNumber(format: .International))
                phoneNumber = try validate(
                    property: "phoneNumber",
                    with: phoneNumber >>> phoneNumberValidation)
            }
            .append {
                // An email or a phone number is required.
                try validate(
                    properties: ["email", "phoneNumber"],
                    message: "Please provide an email or a phone number.",
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
// Invalid Person: name should not be empty.

var person = Person(name: "Arthur", age: -1, email: "foo@bar.com", phoneNumber: nil)
try person.validate()
// Invalid Person: age should be greater than or equal to 0.

var person = Person(name: "Arthur", age: 35, email: nil, phoneNumber: nil)
try person.validate()
// Invalid Person: Please provide an email or a phone number.

var person = Person(name: "Arthur", age: 35, email: "foo", phoneNumber: nil)
try person.validate()
// Invalid Person: email is invalid.
```
