//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public final class PrivateUserDefaults<Key: DefaultsKey> {

    // MARK: - Properties

    let userID: UUID
    let storage: UserDefaults

    // MARK: - Life cycle

    public init(
        userID: UUID,
        storage: UserDefaults = .standard
    ) {
        self.userID = userID
        self.storage = storage
    }

    // MARK: - Methods

    private func scopeKey(_ key: Key) -> String {
        return "\(userID.uuidString)_\(key.rawValue)"
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
        return storage.bool(forKey: scopeKey(key))
    }

    public func set(_ value: Any?, forKey key: Key) {
        storage.set(value, forKey: scopeKey(key))
    }

    public func object(forKey key: Key) -> Any? {
        return storage.object(forKey: scopeKey(key))
    }

    public func set(_ value: Int, forKey key: Key) {
        storage.set(value, forKey: scopeKey(key))
    }

    public func integer(forKey key: Key) -> Int {
        return storage.integer(forKey: scopeKey(key))
    }

}

public protocol DefaultsKey {

    var rawValue: String { get }

}
