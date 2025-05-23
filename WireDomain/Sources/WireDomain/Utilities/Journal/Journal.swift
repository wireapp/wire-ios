//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// A storage mechanism scoped to a single user for keeping
/// track of various bits of information.
///
/// For instance, the journal can be used to keep track of various
/// flags, such as whether a particular migration is required and/or
/// completed.
///
/// The Journal users a scoped `UserDefaults` suite that is accessible
/// within the app group.

import WireFoundation

public class Journal: JournalProtocol {

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
        set {
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
        set {
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

    /// Remove a single value from a Set<String> .
    ///
    /// - Parameters:
    ///   - value: The string to remove.
    ///   - key: The journal key associated with the Set<String>.

    public func removeValue(_ value: String, for key: JournalKey<Set<String>>) {
        var currentSet = self[key]
        currentSet.remove(value)
        self[key] = currentSet
    }

    /// Adds a single value to a Set<String>.
    ///
    /// - Parameters:
    ///   - value: The string to insert.
    ///   - key: The journal key associated with the Set<String>.

    public func addValue(_ value: String, for key: JournalKey<Set<String>>) {
        var currentSet = self[key]
        currentSet.insert(value)
        self[key] = currentSet
    }

    /// Adds multiple values to a Set<String>.
    ///
    /// - Parameters:
    ///   - values: A set of strings to insert.
    ///   - key: The journal key associated with the Set<String>.
    public func addValue(_ values: Set<String>, for key: JournalKey<Set<String>>) {
        var currentSet = self[key]
        currentSet.formUnion(values)
        self[key] = currentSet
    }

}
