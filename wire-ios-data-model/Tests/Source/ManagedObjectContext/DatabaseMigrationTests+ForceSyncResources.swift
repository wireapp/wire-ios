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

final class DatabaseMigrationTests_ForceSyncResources: XCTestCase {

    private let bundle = Bundle(for: ZMManagedObject.self)
    private let teamId = UUID()
    private let tmpStoreURL =
        URL(fileURLWithPath: "\(NSTemporaryDirectory())DatabaseMigrationTests_ForceSyncResources/")
    private let helper = DatabaseMigrationHelper()

    override func setUpWithError() throws {
        try super.setUpWithError()
        try FileManager.default.createDirectory(at: tmpStoreURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpStoreURL)
        try super.tearDownWithError()
    }

    func testThatItPerformsMigrationFrom119Version_ToCurrentModelVersion() async throws {
        let initialVersion = "2.119.0"

        try await helper.migrateStoreToCurrentVersion(
            sourceVersion: initialVersion,
            preMigrationAction: { _ in
                // nothing
            },
            postMigrationAction: { context in
                try context.performAndWait {
                    // verify
                    XCTAssertTrue(context.readMigrationNeedsSyncResourcesFlag())
                }
            },
            for: self
        )
    }
}
