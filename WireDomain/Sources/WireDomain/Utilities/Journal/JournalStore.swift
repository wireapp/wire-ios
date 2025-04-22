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

/// An object that facilitates access to the persistent
/// journal entries for a particular user.

public struct JournalStore {

    let directoryURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - Init

    public init(directoryURL: URL) throws {
        self.directoryURL = directoryURL
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    /// Fetch the entry for a partiular type.
    ///
    /// - Parameter type: The entry type to fetch.
    /// - Returns: The persisted entry, or the default value if none exists.

    public func fetchEntry<T: JournalEntry>(_ type: T.Type) throws -> T {
        if entryExists(for: type) {
            let fileURL = fileURL(for: type)
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(T.self, from: data)
        } else {
            let defaultValue = T.defaultValue
            try storeEntry(defaultValue)
            return defaultValue
        }
    }

    /// Store a journal entry.
    ///
    /// - Parameter entry: The entry to store.

    public func storeEntry<T: JournalEntry>(_ entry: T) throws {
        let data = try encoder.encode(entry)
        let fileURL = fileURL(for: T.self)
        try data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Private helpers

    private func entryExists<T: JournalEntry>(for type: T.Type) -> Bool {
        let fileURL = fileURL(for: type)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    private func fileURL<T: JournalEntry>(for type: T.Type) -> URL {
        directoryURL.appendingPathComponent("\(T.uniqueName).json")
    }

}
