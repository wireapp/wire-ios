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
import WireAPISupport
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireDomain

final class UserLegalHoldDisableEventProcessorTests: XCTestCase {

    var sut: UserLegalholdDisableEventProcessor!

    var coreDataStack: CoreDataStack!
    var coreDataStackHelper: CoreDataStackHelper!
    var modelHelper: ModelHelper!

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = UserLegalholdDisableEventProcessor(
            repository: UserRepository(
                context: context,
                usersAPI: MockUsersAPI()
            )
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Disables_Legal_Hold_Status() async throws {
        // Given

        await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(
                id: Scaffolding.userID,
                domain: nil,
                in: context
            )

            let legalHoldRequest = Scaffolding.legalHoldRequest
            selfUser.userDidReceiveLegalHoldRequest(Scaffolding.legalHoldRequest)

            XCTAssertEqual(selfUser.legalHoldStatus, .pending(legalHoldRequest))
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)
            XCTAssertEqual(selfUser.legalHoldStatus, .disabled)
        }
    }

}

extension UserLegalHoldDisableEventProcessorTests {
    enum Scaffolding {
        nonisolated(unsafe) static let event = UserLegalholdDisableEvent(
            userID: userID
        )

        static let userID = UUID()

        nonisolated(unsafe) static let legalHoldRequest = LegalHoldRequest(
            target: userID,
            requester: UUID(),
            clientIdentifier: "eca3c87cfe28be49",
            lastPrekey: LegalHoldRequest.Prekey(
                id: 65_535,
                key: Data(base64Encoded: "pQABAQoCoQBYIPEFMBhOtG0dl6gZrh3kgopEK4i62t9sqyqCBckq3IJgA6EAoQBYIC9gPmCdKyqwj9RiAaeSsUI7zPKDZS+CjoN+sfihk/5VBPY=")!
            )
        )
    }
}
