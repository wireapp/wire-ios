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

import Foundation

// MARK: - PrivateUserDefaults

public final class PrivateUserDefaults<Key: DefaultsKey> {
    // MARK: Lifecycle

    public init(
        userID: UUID,
        storage: UserDefaults = .standard
    ) {
        self.userID = userID
        self.storage = storage
    }

    // MARK: Internal

    // MARK: - Properties

    let userID: UUID
    let storage: UserDefaults

    // MARK: Private

    // MARK: - Methods

    private static func scopePrefix(userID: UUID) -> String {
        "\(userID.uuidString)_"
    }

    private func scopeKey(_ key: Key) -> String {
        "\(Self.scopePrefix(userID: userID))\(key.rawValue)"
    }
}

extension PrivateUserDefaults {
    public func setUUID(_ uuid: UUID?, forKey key: Key) {
        storage.set(uuid?.uuidString, forKey: scopeKey(key))
    }

    public func getUUID(forKey key: Key) -> UUID? {
        guard let uuidString = storage.string(forKey: scopeKey(key)) else { return nil }
        return UUID(uuidString: uuidString)
    }

    public func set(_ value: Bool, forKey key: Key) {
        storage.set(value, forKey: scopeKey(key))
    }

    public func bool(forKey key: Key) -> Bool {
        storage.bool(forKey: scopeKey(key))
    }

    public func set(_ value: Any?, forKey key: Key) {
        storage.set(value, forKey: scopeKey(key))
    }

    public func object(forKey key: Key) -> Any? {
        storage.object(forKey: scopeKey(key))
    }

    public func set(_ value: Int, forKey key: Key) {
        storage.set(value, forKey: scopeKey(key))
    }

    public func integer(forKey key: Key) -> Int {
        storage.integer(forKey: scopeKey(key))
    }

    public func set(_ value: Date, forKey key: Key) {
        storage.set(value, forKey: scopeKey(key))
    }

    public func date(forKey key: Key) -> Date? {
        storage.object(forKey: scopeKey(key)) as? Date
    }

    public func removeObject(forKey key: Key) {
        storage.removeObject(forKey: scopeKey(key))
    }
}

// MARK: - DefaultsKey

public protocol DefaultsKey {
    var rawValue: String { get }
}

// MARK: - Never + DefaultsKey

extension Never: DefaultsKey {
    public var rawValue: String { fatalError() }
}

extension PrivateUserDefaults where Key == Never {
    /// Removes all values for keys scoped to `userID` in `storage`.

    public static func removeAll(forUserID userID: UUID, in storage: UserDefaults) {
        let prefix = scopePrefix(userID: userID)
        let skopedKeys = storage.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
        for key in skopedKeys {
            storage.removeObject(forKey: key)
        }
    }
}
