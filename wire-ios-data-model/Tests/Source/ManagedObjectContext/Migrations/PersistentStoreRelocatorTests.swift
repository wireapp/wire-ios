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

import XCTest
@testable import WireDataModel

class PersistentStoreRelocatorTests: DatabaseBaseTest {
    func testThatItFindsPreviousStoreInCachesDirectory() {
        // given
        createLegacyStore(path: .cachesDirectory)

        // new store is located in documents directory
        let sut = PersistentStoreRelocator(
            sharedContainerURL: sharedContainerDirectoryURL,
            newStoreURL: StorageStack.accountFolder(
                accountIdentifier: UUID(),
                applicationContainer: sharedContainerDirectoryURL
            )
        )

        // then
        XCTAssertEqual(sut.previousStoreLocation, FileManager.storeURL(in: .cachesDirectory))
    }

    func testThatItFindsPreviousStoreInApplicationSupportDirectory() {
        // given
        createLegacyStore(path: .applicationSupportDirectory)

        // new store is located in documents directory
        let sut = PersistentStoreRelocator(
            sharedContainerURL: sharedContainerDirectoryURL,
            newStoreURL: FileManager.currentStoreURLForAccount(
                with: UUID(), in: sharedContainerDirectoryURL
            )
        )

        // then
        XCTAssertEqual(sut.previousStoreLocation, FileManager.storeURL(in: .applicationSupportDirectory))
    }

    func testThatIsNecessaryToRelocateStoreIfItsLocatedInAPreviousLocation_and_newStoreAlreadyExists() {
        // given
        let cachesStoreURL = FileManager.storeURL(in: .cachesDirectory)
        createLegacyStore(path: .documentDirectory)
        createDirectoryForStore(at: cachesStoreURL)
        createExternalSupportFileForDatabase(at: cachesStoreURL)

        // new store is located in documents directory
        let sut = PersistentStoreRelocator(
            sharedContainerURL: sharedContainerDirectoryURL,
            newStoreURL: FileManager.currentStoreURLForAccount(
                with: UUID(), in: sharedContainerDirectoryURL
            )
        )

        // then
        XCTAssertNotNil(sut.previousStoreLocation)
    }

    func testThatIsNotNecessaryToRelocateStoreIfNotPreviousStoreExists() {
        // given new store is located in documents directory
        let sut = PersistentStoreRelocator(
            sharedContainerURL: sharedContainerDirectoryURL,
            newStoreURL: FileManager.currentStoreURLForAccount(
                with: UUID(), in: sharedContainerDirectoryURL
            )
        )

        // then
        XCTAssertNil(sut.previousStoreLocation)
    }

    func testThatIsNotNecessaryToRelocateStoreIfItsLocatedInAPreviousLocation_and_newStoreIsTheSame() {
        // given
        let accountId = UUID()
        createDatabase(in: .documentDirectory, accountIdentifier: accountId)

        // new store is also located in caches directory
        let sut = PersistentStoreRelocator(
            sharedContainerURL: sharedContainerDirectoryURL,
            newStoreURL: FileManager.currentStoreURLForAccount(
                with: accountId,
                in: sharedContainerDirectoryURL
            )
        )

        // then
        XCTAssertNil(sut.previousStoreLocation)
    }
}
