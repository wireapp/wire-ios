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
import Testing

@testable import WireDomain

@Suite("JournalStore tests", .serialized)
class JournalStoreTests {

    let directoryURL: URL

    init() {
        directoryURL = FileManager.default.temporaryDirectory.appending(
            path: UUID().uuidString
        )
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    @Test("Store returns default entry when no entry found")
    func returnsDefaultValueWhenNoEntryFound() throws {
        // Given
        let sut = try JournalStore(directoryURL: directoryURL)

        // When
        let entry = try sut.fetchEntry(SyncV2JournalEntry.self)

        // Then
        #expect(entry == SyncV2JournalEntry.defaultValue)
    }

    @Test("Store an entry, then fetch it.")
    func storeAndFetchAnEntry() throws {
        // Given
        let sut = try JournalStore(directoryURL: directoryURL)
        let entry = SyncV2JournalEntry(
            isEnabled: true,
            didMigrateLegacyEvents: true
        )

        // When
        try sut.storeEntry(entry)
        let fetchedEntry = try sut.fetchEntry(SyncV2JournalEntry.self)

        // Then
        #expect(fetchedEntry == entry)
    }

}
