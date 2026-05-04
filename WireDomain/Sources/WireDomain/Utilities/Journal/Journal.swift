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
public import WireFoundation

/// A storage mechanism scoped to a single user for keeping
/// track of various bits of information.
///
/// For instance, the journal can be used to keep track of various
/// flags, such as whether a particular migration is required and/or
/// completed.
///
/// The Journal users a scoped `UserDefaults` suite that is accessible
/// within the app group.

public struct Journal: JournalProtocol {

    private let userID: UUID
    private let storage: any UserDefaultsProtocol

    private var namespace: String {
        "\(userID.uuidString).journal"
    }

    /// Create a new `Journal` for a particular user.
    ///
    /// - Parameters:
    ///   - userID: The id of the journal's user.
    ///   - storage: A user defaults instance to store the journal data.

    public init(
        userID: UUID,
        storage: any UserDefaultsProtocol
    ) {
        self.userID = userID
        self.storage = storage
    }

    /// Get or set a boolean value.

    public subscript(_ key: JournalKey<Bool>) -> Bool {
        get {
            (storage.object(forKey: rawKey(for: key)) as? Bool) ?? key.defaultValue
        }
        nonmutating set {
            storage.set(newValue, forKey: rawKey(for: key))
        }
    }

    /// Get or set an optional string value.

    public subscript(_ key: JournalKey<String?>) -> String? {
        get {
            storage.string(forKey: rawKey(for: key)) ?? key.defaultValue
        }
        nonmutating set {
            storage.set(newValue, forKey: rawKey(for: key))
        }
    }

    /// Get or set a list of string values.

    public subscript(_ key: JournalKey<Set<String>>) -> Set<String> {
        get {
            if let array = storage.object(forKey: rawKey(for: key)) as? [String] {
                Set(array)
            } else {
                key.defaultValue
            }
        }
        nonmutating set {
            storage.set(Array(newValue), forKey: rawKey(for: key))
        }
    }

    /// Delete all values in the journal.

    public func erase() {
        for key in storage.keys() where key.hasPrefix(namespace) {
            storage.removeObject(forKey: key)
        }
    }

    func rawKey(for key: JournalKey<some Any>) -> String {
        // Prefix to avoid possible namespace conflicts.
        "\(namespace).\(key.name)"
    }

}

public extension Journal {

    func removeValue(_ value: String, for key: JournalKey<Set<String>>) {
        var currentSet = self[key]
        currentSet.remove(value)
        self[key] = currentSet
    }

    func addValue(_ value: String, for key: JournalKey<Set<String>>) {
        var currentSet = self[key]
        currentSet.insert(value)
        self[key] = currentSet
    }

    func addValues(_ values: Set<String>, for key: JournalKey<Set<String>>) {
        var currentSet = self[key]
        currentSet.formUnion(values)
        self[key] = currentSet
    }

    /// - Note: This method is used to export values of journal to written logs
    func values() -> [String: String] {
        var result = [String: String]()

        [
            JournalKey.isConsumableNotificationsEnabled,
            JournalKey.isConversationSyncRequired,
            JournalKey.isCoreCryptoKeyMigrationToBytesRequired,
            JournalKey.isCoreCryptoKeyMigrationToScopedKeyRequired,
            JournalKey.isCoreCryptoKeyRotationRequired,
            JournalKey.isInitialSyncRequired,
            JournalKey.isSyncV2Enabled,
            JournalKey.isBackendMLSEnabled,
            JournalKey.isFederationMigrationRequired,
            JournalKey.isRepairFaultyMLSRemovalKeysRequired

        ].forEach {
            result[$0.name] = "\(self[$0] == true ? "Yes" : "No")"
        }
        let groups = Array(self[JournalKey.brokenMLSGroupIDs])
        result[JournalKey.brokenMLSGroupIDs.name] = groups.isEmpty ? "None" : groups.joined(separator: "\n")

        return result
    }
}
