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

public import Foundation

public extension String {
    static func formated(key: String.LocalizationValue, bundle: Bundle? = nil, _ arguments: any CVarArg...) -> String {
        String(format: .localized(key: key, bundle: bundle), arguments)
    }

    static func localizedAccessibilityLabel(key: String.LocalizationValue, bundle: Bundle? = nil) -> String {
        String(localized: key, table: "Accessibility", bundle: bundle)
    }

    ///
    /// Returns a localized string from the specified table.
    /// - parameter key: The key for the localized string.
    /// - parameter bundle: The bundle where the localized string is located. (default: .module)
    /// - returns: The localized string.
    ///
    /// Example:
    /// ```
    /// let localizedString: String = .localized(key: "key")
    /// ```
    /// - note: The default value for `bundle` is `.module`.
    static func localized(key: String.LocalizationValue, bundle: Bundle? = nil) -> String {
        String(localized: key, table: "Localizable", bundle: bundle)
    }
}
