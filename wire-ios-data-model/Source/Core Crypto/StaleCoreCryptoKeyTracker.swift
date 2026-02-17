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

import WireFoundation

// sourcery: AutoMockable
public protocol StaleCoreCryptoKeysTrackerProtocol {
    func addKey(id: UUID)
    func getAll() -> [UUID]
    func clear()
    func removeKey(id: UUID)
}

public struct StaleCoreCryptoKeysTracker: StaleCoreCryptoKeysTrackerProtocol {

    private let defaults: UserDefaultsProtocol

    let key = "staleCoreCryptoKeyIds"

    public init(defaults: UserDefaultsProtocol) {
        self.defaults = defaults
    }

    /// Add a stale key ID to the list
    public func addKey(id: UUID) {
        var ids = Set(getAll())
        ids.insert(id)
        save(ids: ids)
    }

    /// Retrieve all stale key IDs
    public func getAll() -> [UUID] {
        let strings = defaults.stringArray(forKey: key) ?? []
        return strings.compactMap { UUID(uuidString: $0) }
    }

    /// Clear all stale key IDs
    public func clear() {
        defaults.removeObject(forKey: key)
    }

    /// Remove a specific key from the stale list
    public func removeKey(id: UUID) {
        var ids = Set(getAll())
        ids.remove(id)
        save(ids: ids)
    }

    private func save(ids: Set<UUID>) {
        defaults.set(ids.map(\.uuidString), forKey: key)
    }
}
