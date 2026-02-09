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
import WireTesting
@testable import WireDataModel

class DatabaseBaseTest: ZMTBaseTest {

    var accountID: UUID = .create()

    public static var applicationContainer: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("StorageStackTests")
    }

    // MARK: - Init

    public override func setUp() async throws {
        try await super.setUp()
        clearStorageFolder()
        try! FileManager.default.createDirectory(at: Self.applicationContainer, withIntermediateDirectories: true)
    }

    public override func tearDown() {
        clearStorageFolder()
        super.tearDown()
    }

    // MARK: - Cleanup

    /// Clears the current storage folder and the legacy locations
    public func clearStorageFolder() {
        let url = Self.applicationContainer
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - CoreData Stack

    /// Create storage stack
    func createStorageStackAndWaitForCompletion(
        userID: UUID = UUID(),
        localDomain: String = "wire.com",
        isFederationEnabled: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> CoreDataStack {

        // we use backgroundActivity during the setup so we need to mock it for tests
        let manager = MockBackgroundActivityManager()
        BackgroundActivityFactory.shared.activityManager = manager

        let account = Account(userName: "", userIdentifier: userID)
        let stack = CoreDataStack(
            account: account,
            applicationContainer: Self.applicationContainer,
            inMemoryStore: false,
            dispatchGroup: dispatchGroup,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )

        try await stack.load()

        BackgroundActivityFactory.shared.activityManager = nil
        XCTAssertFalse(BackgroundActivityFactory.shared.isActive, file: file, line: line)

        return stack
    }
}
