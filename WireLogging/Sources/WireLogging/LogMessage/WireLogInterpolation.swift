//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

/// A string interpolation type that restricts automatic conversion of values to strings.
///
/// `WireLogInterpolation` is designed to prevent accidental logging of sensitive data by prohibiting
/// automatic string interpolation of dynamic values. Only `StaticString` values can be interpolated
/// by default, ensuring that compile-time constants are safe to log.
///
/// ## Security Model
///
/// By default, only `StaticString` can be interpolated in log messages. Any attempt to interpolate
/// other types (such as `String`, `Int`, custom types, etc.) will fail to compile:
///
/// ```swift
/// // ✅ This compiles - StaticString is allowed
/// logger.info("User logged in")
///
/// // ✅ This compiles - StaticString interpolation is allowed
/// let name = "World" as StaticString
/// logger.info("Hello, \(name)!")
///
/// // ❌ This fails to compile - String is not allowed
/// let userId = "12345"
/// logger.info("User ID: \(userId)") // Compile error!
///
/// // ❌ This fails to compile - Int is not allowed
/// let count = 42
/// logger.info("Count: \(count)") // Compile error!
/// ```
///
/// ## Extending for Custom Types
///
/// To log custom types, you must explicitly extend `WireLogInterpolation` and implement
/// `appendInterpolation` methods. This ensures that logging of sensitive data is intentional
/// and that appropriate obfuscation can be applied:
///
/// ```swift
/// extension WireLogInterpolation {
///     mutating func appendInterpolation(_ userID: UUID) {
///         // Obfuscate sensitive data
///         let obfuscated = String(userID.uuidString.prefix(8)) + "***"
///         writeText(obfuscated)
///
///         // Optionally add structured attributes
///         writeAttribute(.selfUserID(userID))
///     }
/// }
/// ```
///
/// When implementing `appendInterpolation`, consider:
/// - Whether the value contains sensitive information that should be obfuscated
/// - Whether structured attributes should be added for better log analysis
/// - Using `writeText(_:)` for content that should appear in the log message
/// - Using `writeAttribute(_:)` for structured metadata

public struct WireLogInterpolation: StringInterpolationProtocol {

    private(set) var content = ""
    private(set) var attributes = [WireLogAttribute]()

    public init(literalCapacity: Int, interpolationCount _: Int) {
        content.reserveCapacity(literalCapacity)
    }

    public mutating func appendLiteral(_ literal: StaticString) {
        writeText("\(literal)")
    }

    public mutating func appendInterpolation(_ literal: StaticString) {
        writeText("\(literal)")
    }

    /// Adds a structured attribute to the log message.
    ///
    /// Attributes are separate from the message content and can be used for structured log analysis.
    /// Depending on the logging system, attributes might be formatted differently (e.g., prepended in brackets
    /// or appended separately).
    ///
    /// - Parameter attribute: The attribute to add, containing a key-value pair.
    ///
    /// ## Example
    ///
    /// ```swift
    /// extension WireLogInterpolation {
    ///     mutating func appendInterpolation(_ userID: UUID) {
    ///         writeText("User: \(userID.uuidString.prefix(8))***")
    ///         writeAttribute(.selfUserID(userID))
    ///     }
    /// }
    /// ```

    public mutating func writeAttribute(_ attribute: WireLogAttribute) {
        attributes.append(attribute)
    }

    /// Adds text content to the log message.
    ///
    /// **Important:** The provided text is **not automatically obfuscated**. When logging sensitive data,
    /// ensure you obfuscate or sanitize the value before passing it to this method.
    ///
    /// - Parameter text: The text to add to the log message content.
    ///
    /// ## Example
    ///
    /// ```swift
    /// extension WireLogInterpolation {
    ///     mutating func appendInterpolation(_ email: String) {
    ///         // Obfuscate before writing
    ///         let obfuscated = String(email.prefix(3)) + "***@***"
    ///         writeText(obfuscated)
    ///     }
    /// }
    /// ```

    public mutating func writeText(_ text: String) {
        content += text
    }

}
