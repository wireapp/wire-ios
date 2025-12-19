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

    let userID = UUID()
    let storage = UserDefaults.temporary()

    lazy var sut = Journal(
        userID: userID,
        storage: storage
    )

    @Test("Store returns default entry when no entry found")
    func returnsDefaultValueWhenNoEntryFound() {
        // When
        let entry = sut[.isSyncV2Enabled]

        // Then
        #expect(entry == JournalKey<Bool>.isSyncV2Enabled.defaultValue)
    }

    @Test("Store an entry, then fetch it.")
    func storeAndFetchAnEntry() {
        // Given
        #expect(sut[.isSyncV2Enabled] == false)

        // When
        sut[.isSyncV2Enabled] = true

        // Then
        #expect(sut[.isSyncV2Enabled] == true)
    }

    @Test("Erasing the journal only erases its values")
    func erasingTheJournal() {
        // Given
        sut[.isSyncV2Enabled] = true
        storage.set(true, forKey: "notAJournalKey")

        // When
        sut.erase()

        // Then
        #expect(storage.object(forKey: sut.rawKey(for: .isSyncV2Enabled)) == nil)
        #expect(storage.object(forKey: "notAJournalKey") != nil)
    }

    @Test("Values contain all declared values")
    func values() {
        // Given
        let exhaustiveKeysCount = 11
        sut[.isSyncV2Enabled] = true

        // When
        let result = sut.values()

        // Then
        #expect(result.keys.count == exhaustiveKeysCount)
    }

}
