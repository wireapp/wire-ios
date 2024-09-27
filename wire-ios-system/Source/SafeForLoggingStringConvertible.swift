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

// MARK: - SafeForLoggingStringConvertible

/// Object can implement this protocol to allow creating the privacy-enabled object description.
/// Things to consider when implementing is to exclude any kind of personal information from the object description:
/// No user name, login, email, etc., or any kind of backend object ID.
public protocol SafeForLoggingStringConvertible {
    var safeForLoggingDescription: String { get }
}

// MARK: - SafeValueForLogging

public struct SafeValueForLogging<T: CustomStringConvertible>: SafeForLoggingStringConvertible {
    // MARK: Lifecycle

    public init(_ value: T) {
        self.value = value
    }

    // MARK: Public

    public let value: T

    public var safeForLoggingDescription: String {
        value.description
    }
}

// MARK: - Array + SafeForLoggingStringConvertible

extension Array: SafeForLoggingStringConvertible where Array.Element: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        String(describing: map(\.safeForLoggingDescription))
    }
}

// MARK: - Dictionary + SafeForLoggingStringConvertible

extension Dictionary: SafeForLoggingStringConvertible where Key: SafeForLoggingStringConvertible,
    Value: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        let result = enumerated().map { _, element in
            (element.key.safeForLoggingDescription, element.value.safeForLoggingDescription)
        }

        let dictionary = [String: String](uniqueKeysWithValues: result)
        return String(describing: dictionary)
    }
}
