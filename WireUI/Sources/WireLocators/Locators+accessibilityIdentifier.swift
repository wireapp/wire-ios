//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import SwiftUI

public extension View {

    /// Adds an accessibility identifier to a view for testing purposes. To be used with `Locators.swift'
    ///
    /// This method allows you to specify a testable ID for SwiftUI views, which is particularly useful in automated
    /// testing scenarios such as XCUITest. It accepts any `RawRepresentable` type whose `RawValue` is a `String`,
    /// providing flexibility in how you pass the identifier.
    ///
    /// - Parameter id: A value conforming to `RawRepresentable` where the `RawValue` is a `String`. For example, you
    /// can pass a simple `String`, or an `Enum` with a `String` raw value.
    /// - Returns: A view with the accessibility identifier set.
    ///
    /// ### Usage Examples
    ///
    /// ```swift
    /// // Using a plain string
    /// Text("Hello")
    ///     .accessibilityIdentifier("greeting")
    ///
    /// // Using an enum with raw values
    /// Button(action: { /* ... */ }) {
    ///     Text("Submit")
    /// }
    /// .accessibilityIdentifier(TestId.submitButton)
    ///
    /// enum TestId: String {
    ///     case submitButton = "submitButton"
    /// }
    /// ```
    func accessibilityIdentifier<T: RawRepresentable>(_ id: T) -> some View where T.RawValue == String {
        accessibilityIdentifier(id.rawValue)
    }
}
