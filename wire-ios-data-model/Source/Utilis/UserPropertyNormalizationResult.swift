//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

/// The result of a property normalization operation.
public struct UserPropertyNormalizationResult<Value> {
    // MARK: Lifecycle

    public init(isValid: Bool, normalizedValue: Value, validationError: Error?) {
        self.isValid = isValid
        self.normalizedValue = normalizedValue
        self.validationError = validationError
    }

    // MARK: Public

    /// Whether the value is valid.
    public var isValid: Bool

    /// The value that was normalized during the operation.
    public var normalizedValue: Value

    /// The error that reprsents the reason why the property is not valid.
    public var validationError: Error?
}
