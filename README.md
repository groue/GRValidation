GRValidation
============

Experiments with validation in Swift 2.


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
