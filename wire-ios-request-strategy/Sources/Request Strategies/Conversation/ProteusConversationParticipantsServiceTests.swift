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

import WireDataModelSupport
import XCTest
@testable import WireRequestStrategy

class ProteusConversationParticipantsServiceTests: MessagingTestBase {
    // MARK: - Properties

    var sut: ProteusConversationParticipantsService!
    var conversation: ZMConversation!
    var user: ZMUser!

    override func setUp() {
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.domain = "domain.com"
        conversation.remoteIdentifier = .create()

        user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = .create()
        user.domain = "domain.com"

        sut = ProteusConversationParticipantsService(context: uiMOC)

        super.setUp()
    }

    override func tearDown() {
        sut = nil
        user = nil
        conversation = nil
        super.tearDown()
    }

    // MARK: - Add Participants

    func test_AddParticipants_Succeeds() async throws {
        // GIVEN
        let mockHandler = MockActionHandler<AddParticipantAction>(
            result: .success(()),
            context: uiMOC.notificationContext
        )

        // WHEN
        try await sut.addParticipants([user], to: conversation)

        // THEN
        XCTAssertEqual(mockHandler.performedActions.count, 1)
    }

    func test_AddParticipants_Fails() async {
        // GIVEN
        let handler = MockActionHandler<AddParticipantAction>(
            result: .failure(.unknown),
            context: uiMOC.notificationContext
        )

        // THEN
        await assertItThrows(error: ConversationAddParticipantsError.unknown) {
            // WHEN
            try await sut.addParticipants([user], to: conversation)
        }
        withExtendedLifetime(handler) {}
    }

    func test_AddParticipants_MapsFederationErrors_UnreachableDomains() async {
        // GIVEN
        let domains = Set(["domain.com"])

        let handler = MockActionHandler<AddParticipantAction>(
            result: .failure(.unreachableDomains(domains)),
            context: uiMOC.notificationContext
        )

        // THEN
        await assertItThrows(error: FederationError.unreachableDomains(domains)) {
            // WHEN
            try await sut.addParticipants([user], to: conversation)
        }
        withExtendedLifetime(handler) {}
    }

    func test_AddParticipants_MapsFederationErrors_NonFederatingDomains() async {
        // GIVEN
        let domains = Set(["domain.com"])

        let handler = MockActionHandler<AddParticipantAction>(
            result: .failure(.nonFederatingDomains(domains)),
            context: uiMOC.notificationContext
        )

        // THEN
        await assertItThrows(error: FederationError.nonFederatingDomains(domains)) {
            // WHEN
            try await sut.addParticipants([user], to: conversation)
        }
        withExtendedLifetime(handler) {}
    }

    // MARK: - Remove Participant

    func test_RemoveParticipant_Succeeds() async throws {
        // GIVEN
        let mockHandler = MockActionHandler<RemoveParticipantAction>(
            result: .success(()),
            context: uiMOC.notificationContext
        )

        // WHEN
        try await sut.removeParticipant(user, from: conversation)

        // THEN
        XCTAssertEqual(mockHandler.performedActions.count, 1)
    }

    func test_RemoveParticipant_Fails() async {
        // GIVEN
        let handler = MockActionHandler<RemoveParticipantAction>(
            result: .failure(.unknown),
            context: uiMOC.notificationContext
        )

        // THEN
        await assertItThrows(error: ConversationRemoveParticipantError.unknown) {
            // WHEN
            try await sut.removeParticipant(user, from: conversation)
        }
        withExtendedLifetime(handler) {}
    }
}
