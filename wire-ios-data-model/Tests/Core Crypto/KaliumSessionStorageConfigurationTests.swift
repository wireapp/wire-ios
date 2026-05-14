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

final class KaliumSessionStorageConfigurationTests: XCTestCase {

    private var sharedContainerURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()

        sharedContainerURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("SharedContainer", isDirectory: true)

        try FileManager.default.createDirectory(
            at: sharedContainerURL,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        if let sharedContainerURL {
            try? FileManager.default.removeItem(at: sharedContainerURL)
        }

        sharedContainerURL = nil
        try super.tearDownWithError()
    }

    func test_itBuildsLegacyIosStoragePathsAndKaliumStoragePaths() throws {
        // GIVEN
        let accountUUID = try XCTUnwrap(UUID(uuidString: "11111111-2222-3333-4444-555555555555"))
        let userId = "self-user-id"
        let domain = "wire.example"
        let clientId = "client-id"

        // WHEN
        let sut = KaliumSessionStorageConfigurationFactory.make(
            appGroupContainerURL: sharedContainerURL,
            accountUUID: accountUUID,
            userId: userId,
            domain: domain,
            clientId: clientId
        )

        // THEN
        let legacyAccountDirectory = sharedContainerURL
            .appendingPathComponent("AccountData")
            .appendingPathComponent(accountUUID.uuidString)
        let kaliumRootURL = sharedContainerURL.appendingPathComponent("Kalium", isDirectory: true)
        let sqlDelightStorageURL = kaliumRootURL
            .appendingPathComponent(domain, isDirectory: true)
            .appendingPathComponent(userId, isDirectory: true)
            .appendingPathComponent("storage", isDirectory: true)

        XCTAssertEqual(sut.appGroupContainerURL, sharedContainerURL)
        XCTAssertEqual(sut.accountUUID, accountUUID)
        XCTAssertEqual(sut.userId, userId)
        XCTAssertEqual(sut.domain, domain)
        XCTAssertEqual(sut.clientId, clientId)
        XCTAssertEqual(sut.legacyAccountDirectory, legacyAccountDirectory)
        XCTAssertEqual(
            sut.coreDataStoreURL,
            legacyAccountDirectory
                .appendingPathComponent("store")
                .appendingPathComponent("store.wiredatabase")
        )
        XCTAssertEqual(
            sut.eventStoreURL,
            legacyAccountDirectory
                .appendingPathComponent("events")
                .appendingPathComponent("ZMEventModel.sqlite")
        )
        XCTAssertEqual(
            sut.legacyCoreCryptoOpenInPlacePath,
            legacyAccountDirectory.appendingPathComponent("corecrypto").path
        )
        XCTAssertEqual(sut.kaliumRootPath, kaliumRootURL.path)
        XCTAssertEqual(sut.suggestedKaliumSQLDelightStoragePath, sqlDelightStorageURL.path)
        XCTAssertEqual(
            sut.suggestedKaliumSQLDelightDatabasePath,
            sqlDelightStorageURL.appendingPathComponent("user-db-\(userId)-\(domain)").path
        )
    }
}
