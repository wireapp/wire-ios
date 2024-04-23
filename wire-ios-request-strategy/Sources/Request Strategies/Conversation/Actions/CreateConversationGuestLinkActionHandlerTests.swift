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
import WireDataModelSupport
@testable import WireRequestStrategy

final class CreateConversationGuestLinkActionHandlerTests: ActionHandlerTestBase<CreateConversationGuestLinkAction, CreateConversationGuestLinkActionHandler> {

    // MARK: - Properties

    private var stack: CoreDataStack!
    private let coreDataStackHelper = CoreDataStackHelper()
    private var conversationID: UUID!

    private var syncContext: NSManagedObjectContext {
        return stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()

        await syncContext.perform { [self] in

            conversationID = UUID()

            self.action = CreateConversationGuestLinkAction(password: nil, conversationID: conversationID)
            self.handler = CreateConversationGuestLinkActionHandler(context: syncContext)
        }
    }

    override func tearDown() async throws {
        stack = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    func testCreateConversationGuestLinkRequestGeneration_APIV4() throws {
        let conversationID = try XCTUnwrap(conversationID)
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v4/conversations/\(conversationID.transportString())/code",
            expectedMethod: .post,
            apiVersion: .v4
        )
    }

    func testCreateConversationGuestLinkRequestGeneration_APIV5() throws {
        let conversationID = try XCTUnwrap(conversationID)
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v5/conversations/\(conversationID.transportString())/code",
            expectedMethod: .post,
            apiVersion: .v5
        )
    }

    func testCreateConversationGuestLinkRequestGeneration_APIV6() throws {
        let conversationID = try XCTUnwrap(conversationID)
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v6/conversations/\(conversationID.transportString())/code",
            expectedMethod: .post,
            apiVersion: .v6
        )
    }

    func testCreateConversationGuestLinkSuccess() throws {
        // GIVEN
        let statusCode = 200

        let payload: [AnyHashable: Any] = [
            "code": "SOME-UNIQUE-CODE",
            "has_password": false,
            "key": "sampleKey123",
            "uri": "https://fakeurlfortest.com"
        ]

        // WHEN && THEN
        test_itHandlesSuccess(
            status: statusCode,
            payload: payload as ZMTransportData,
            apiVersion: .v4
        )
    }

    func testCreateConversationGuestLinkFailure() throws {
        // GIVEN
        let statusCode = 400

        let payload: [AnyHashable: Any] = [
            "code": "SOME-UNIQUE-CODE",
            "has_password": false,
            "key": "sampleKey123"
        ]

        // WHEN && THEN
        test_itHandlesFailure(.failure(status: statusCode, error: .unknown))
    }
}
