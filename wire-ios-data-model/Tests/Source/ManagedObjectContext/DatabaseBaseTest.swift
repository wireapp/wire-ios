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

import Foundation
@testable import WireDataModel
import WireTesting

class DatabaseBaseTest: ZMTBaseTest {

    var accountID: UUID = UUID.create()

    public static var applicationContainer: URL {
        URL.applicationSupportDirectory
            .appendingPathComponent("StorageStackTests")
    }

    // MARK: - Init

    override public func setUp() {
        super.setUp()
        self.clearStorageFolder()
        try! FileManager.default.createDirectory(at: Self.applicationContainer, withIntermediateDirectories: true)
    }

    override public func tearDown() {
        self.clearStorageFolder()
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
    func createStorageStackAndWaitForCompletion(userID: UUID = UUID(), file: StaticString = #file, line: UInt = #line) -> CoreDataStack {

        // we use backgroundActivity during the setup so we need to mock it for tests
        let manager = MockBackgroundActivityManager()
        BackgroundActivityFactory.shared.activityManager = manager

        let account = Account(userName: "", userIdentifier: userID)
        let stack = CoreDataStack(account: account,
                                  applicationContainer: Self.applicationContainer,
                                  inMemoryStore: false,
                                  dispatchGroup: dispatchGroup)

        let exp = self.customExpectation(description: "should wait for loadStores to finish")
        stack.setup(onStartMigration: {
            // do nothing
        }, onFailure: { error in
            XCTAssertNil(error, file: file, line: line)
            exp.fulfill()
        }, onCompletion: { _ in
            exp.fulfill()
        })

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 1.0), file: file, line: line)

        BackgroundActivityFactory.shared.activityManager = nil
        XCTAssertFalse(BackgroundActivityFactory.shared.isActive, file: file, line: line)

        return stack
    }
}
