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

import WireUtilities

/**
 * The result of normalizing a value.
 */

public enum NormalizationResult<Value> {

    /// The value is valid, but was potentially changed during normalization. You should use the
    /// value provided as a side-effect here for any further usage.
    case valid(Value)

    /// The value is invalid, because of the given reason.
    case invalid(ZMManagedObjectValidationErrorCode)

    /// The value was not marked valid, but no reason was provided.
    case unknownError

    /// Returns whether the value is valid.
    public var isValid: Bool {
        if case .valid = self {
            return true
        }

        return false
    }
}
