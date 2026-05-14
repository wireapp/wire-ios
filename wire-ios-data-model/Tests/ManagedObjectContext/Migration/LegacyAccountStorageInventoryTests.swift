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

import Foundation
import XCTest
@testable import WireDataModel

final class LegacyAccountStorageInventoryTests: XCTestCase {

    private var temporaryDirectories = [URL]()

    override func tearDownWithError() throws {
        for directory in temporaryDirectories {
            try? FileManager.default.removeItem(at: directory)
        }

        temporaryDirectories.removeAll()
        try super.tearDownWithError()
    }

    func testCompleteFixtureReportsAllLegacyStorageItems() throws {
        // GIVEN
        let accountDirectory = try makeAccountDirectory()
        try createCompleteFixture(in: accountDirectory)

        // WHEN
        let inventory = LegacyAccountStorageInventory(accountDirectory: accountDirectory)

        // THEN
        XCTAssertTrue(inventory.messageStore.exists)
        XCTAssertTrue(inventory.messageStoreWAL.exists)
        XCTAssertTrue(inventory.messageStoreSHM.exists)
        XCTAssertTrue(inventory.eventStore.exists)
        XCTAssertTrue(inventory.coreCryptoDirectory.exists)
        XCTAssertTrue(inventory.hasRequiredItems)
        XCTAssertEqual(inventory.missingRequiredItems, [])
        XCTAssertEqual(inventory.checklist.count, 5)
    }

    func testFixtureWithoutCoreCryptoReportsMissingCoreCryptoDirectory() throws {
        // GIVEN
        let accountDirectory = try makeAccountDirectory()
        try createCompleteFixture(in: accountDirectory, includesCoreCrypto: false)

        // WHEN
        let inventory = LegacyAccountStorageInventory(accountDirectory: accountDirectory)

        // THEN
        XCTAssertTrue(inventory.messageStore.exists)
        XCTAssertTrue(inventory.eventStore.exists)
        XCTAssertFalse(inventory.coreCryptoDirectory.exists)
        XCTAssertFalse(inventory.hasRequiredItems)
        XCTAssertEqual(inventory.missingRequiredItems.map(\.name), ["core crypto directory"])
    }

    func testFixtureWithoutStoreReportsMissingStoreButKeepsOptionalSidecarsIndependent() throws {
        // GIVEN
        let accountDirectory = try makeAccountDirectory()
        try createCompleteFixture(in: accountDirectory, includesStore: false)

        // WHEN
        let inventory = LegacyAccountStorageInventory(accountDirectory: accountDirectory)

        // THEN
        XCTAssertFalse(inventory.messageStore.exists)
        XCTAssertTrue(inventory.messageStoreWAL.exists)
        XCTAssertTrue(inventory.messageStoreSHM.exists)
        XCTAssertTrue(inventory.eventStore.exists)
        XCTAssertTrue(inventory.coreCryptoDirectory.exists)
        XCTAssertFalse(inventory.hasRequiredItems)
        XCTAssertEqual(inventory.missingRequiredItems.map(\.name), ["message store"])
    }

    // MARK: - Helpers

    private func makeAccountDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LegacyAccountStorageInventoryTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        temporaryDirectories.append(url)
        return url
    }

    private func createCompleteFixture(
        in accountDirectory: URL,
        includesStore: Bool = true,
        includesCoreCrypto: Bool = true
    ) throws {
        let storeDirectory = accountDirectory.appendingPathComponent("store")
        let eventsDirectory = accountDirectory.appendingPathComponent("events")
        let coreCryptoDirectory = accountDirectory.appendingPathComponent("corecrypto")
        let storeURL = storeDirectory.appendingPathComponent("store.wiredatabase")

        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: eventsDirectory, withIntermediateDirectories: true)

        if includesStore {
            try Data().write(to: storeURL)
        }

        try Data().write(to: storeURL.appendingSidecarSuffix("-wal"))
        try Data().write(to: storeURL.appendingSidecarSuffix("-shm"))
        try Data().write(to: eventsDirectory.appendingPathComponent("ZMEventModel.sqlite"))

        if includesCoreCrypto {
            try FileManager.default.createDirectory(at: coreCryptoDirectory, withIntermediateDirectories: true)
        }
    }

}

private extension URL {

    func appendingSidecarSuffix(_ suffix: String) -> URL {
        deletingLastPathComponent().appendingPathComponent(lastPathComponent + suffix)
    }

}
