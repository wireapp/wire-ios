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

final class UserLegalholdRequestEventProcessorTests: XCTestCase {

    var sut: UserLegalholdRequestEventProcessor!

    var coreDataStack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = UserLegalholdRequestEventProcessor(
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
    }

    // MARK: - Tests

    func testProcessEvent_It_Processes_Legalhold_Request_Event() async throws {
        // Given

        await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(
                id: Scaffolding.userID,
                domain: nil,
                in: context
            )
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let selfUser = try XCTUnwrap(ZMUser.fetch(with: Scaffolding.userID, in: context))

            XCTAssertEqual(selfUser.legalHoldStatus, .pending(Scaffolding.legalHoldRequest))
        }
    }

}

extension UserLegalholdRequestEventProcessorTests {
    enum Scaffolding {
        static let userID = UUID()
        static let clientID = UUID().uuidString
        static let lastPrekeyId = 65_535
        static let base64encodedString = "pQABAQoCoQBYIPEFMBhOtG0dl6gZrh3kgopEK4i62t9sqyqCBckq3IJgA6EAoQBYIC9gPmCdKyqwj9RiAaeSsUI7zPKDZS+CjoN+sfihk/5VBPY="

        static let legalHoldRequest = LegalHoldRequest(
            target: userID,
            requester: nil,
            clientIdentifier: clientID,
            lastPrekey: .init(
                id: lastPrekeyId,
                key: Data(base64Encoded: base64encodedString)!
            )
        )

        static let event = UserLegalholdRequestEvent(
            userID: userID,
            clientID: clientID,
            lastPrekey: Prekey(
                id: lastPrekeyId,
                base64EncodedKey: base64encodedString
            )
        )
    }
}
