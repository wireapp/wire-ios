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
import WireAPI
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireDomain

final class TeamDeleteEventProcessorTests: XCTestCase {

    var sut: TeamDeleteEventProcessor!

    var coreDataStack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = TeamDeleteEventProcessor(
            context: context
        )
        try await super.setUp()
    }

    override func tearDown() async throws {
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Tests

    func testProcessEvent_It_Receives_Account_Deletion_Notification() async throws {
        let expectation = XCTestExpectation()
        let notificationName = AccountDeletedNotification.notificationName

        NotificationCenter.default.addObserver(
            forName: notificationName,
            object: nil,
            queue: nil
        ) { notification in

            XCTAssertNotNil(notification.userInfo?[notificationName] as? AccountDeletedNotification)

            // Then

            expectation.fulfill()
        }

        // When

        try await sut.processEvent()
    }

}
