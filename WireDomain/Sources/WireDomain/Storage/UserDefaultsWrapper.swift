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

import Combine
import Foundation

/// Allows to match for optionals with generics that are defined as non-optional.
protocol AnyOptional {
    /// Returns `true` if `nil`, otherwise `false`.
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}

public extension UserDefault where Value: ExpressibleByNilLiteral {

    /// Creates a new User Defaults property wrapper for the given key.
    /// - Parameters:
    ///   - key: The key to use with the user defaults store.
    init(
        key: Key,
        _ container: UserDefaults = .standard,
        userID: UUID
    ) {
        self.init(
            key: key,
            defaultValue: nil,
            container: container,
            userID: userID
        )
    }
}

@propertyWrapper
public struct UserDefault<Key: RawRepresentable<String>, Value> {
    let key: Key
    let defaultValue: Value
    var container: UserDefaults = .standard
    let userID: UUID

    public init(
        key: Key,
        defaultValue: Value,
        container: UserDefaults,
        userID: UUID
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
        self.userID = userID
    }

    public var wrappedValue: Value {
        get {
            container.object(forKey: scopeKey(key)) as? Value ?? defaultValue
        }
        set {
            // Check whether we're dealing with an optional and remove the object if the new value is nil.
            if let optional = newValue as? AnyOptional, optional.isNil {
                container.removeObject(forKey: scopeKey(key))
            } else {
                container.set(newValue, forKey: scopeKey(key))
            }
        }
    }

    private func scopePrefix(userID: UUID) -> String {
        "\(userID.uuidString)_"
    }

    private func scopeKey(_ key: Key) -> String {
        "\(scopePrefix(userID: userID))\(key.rawValue)"
    }

}
