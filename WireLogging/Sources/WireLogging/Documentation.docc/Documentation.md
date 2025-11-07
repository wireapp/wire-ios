# ``WireLogging``

A secure logging framework that prevents accidental logging of sensitive data by restricting string interpolation.

## Overview

The `WireLogging` framework provides a type-safe logging API that prevents accidental exposure of sensitive information in logs. Unlike standard Swift string interpolation, `WireLogMessage` only allows `StaticString` values to be interpolated by default, ensuring that dynamic values cannot be accidentally logged without explicit handling.

## Security Model

The core principle of `WireLogging` is that **only compile-time constants (`StaticString`) can be interpolated directly**. Any attempt to interpolate dynamic values will fail at compile time:

```swift
// ✅ Allowed - StaticString
logger.info("User logged in")

// ✅ Allowed - StaticString interpolation
let name = "World" as StaticString
logger.info("Hello, \(name)!")

// ❌ Compile error - String is not allowed
let userId = "12345"
logger.info("User ID: \(userId)") // Error: no matching appendInterpolation

// ❌ Compile error - Int is not allowed
let count = 42
logger.info("Count: \(count)") // Error: no matching appendInterpolation
```

## Extending for Custom Types

To log custom types or dynamic values, you must explicitly extend `WireLogInterpolation` and implement `appendInterpolation` methods. This ensures that:

1. Logging of sensitive data is intentional
2. Appropriate obfuscation can be applied
3. Structured attributes can be added for better log analysis

### Example: Logging a UUID

```swift
extension WireLogInterpolation {
    mutating func appendInterpolation(_ userID: UUID) {
        // Obfuscate sensitive data
        let obfuscated = String(userID.uuidString.prefix(8)) + "***"
        writeText(obfuscated)
        
        // Add structured attribute for log analysis
        writeAttribute(.selfUserID(userID))
    }
}

// Now this compiles and safely logs the UUID
let userId = UUID()
logger.info("Processing request for user: \(userId)")
```

### Example: Logging a Custom Type

```swift
struct User {
    let id: UUID
    let email: String
    let password: String // Sensitive!
}

extension WireLogInterpolation {
    mutating func appendInterpolation(_ user: User) {
        // Only log safe information
        writeText("User(id: \(user.id.uuidString.prefix(8))***)")
        
        // Never log sensitive fields like password
        // Add structured attributes for analysis using predefined methods
        writeAttribute(.selfUserID(user.id))
    }
}
```

## Building Log Messages

When implementing `appendInterpolation`, use:

- **`writeText(_:)`** - Adds text content to the log message. The provided value is **not obfuscated**, so ensure sensitive data is handled before calling this method.
- **`writeAttribute(_:)`** - Adds structured attributes that can be used for log analysis. Attributes are separate from the message content and may be formatted differently by the logging handler. Prefer using predefined static methods on `WireLogAttribute` (e.g., `.selfUserID(_:)`) rather than initializing new instances directly.

## Topics
    