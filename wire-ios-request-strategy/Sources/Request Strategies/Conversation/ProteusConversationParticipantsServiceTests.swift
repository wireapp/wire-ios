////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
@testable import WireRequestStrategy

class ProteusConversationParticipantsServiceTests: MessagingTestBase {

    // MARK: - Properties

    var sut: ProteusConversationParticipantsService!
    var conversation: ZMConversation!
    var user: ZMUser!

    // MARK: Life Cycle

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

    func test_AddParticipants_Succeeds() {
        // GIVEN
        _ = MockActionHandler<AddParticipantAction>(
            result: .success(()),
            context: uiMOC.notificationContext
        )

        // THEN
        assertMethodCompletesWithSuccess {
            // WHEN
            sut.addParticipants([user], to: conversation, completion: $0)
        }
    }

    func test_AddParticipants_Fails() {
        // GIVEN
        _ = MockActionHandler<AddParticipantAction>(
            result: .failure(.unknown),
            context: uiMOC.notificationContext
        )

        // THEN
        assertMethodCompletesWithError(.unknown) {
            // WHEN
            sut.addParticipants([user], to: conversation, completion: $0)
        }
    }

    // MARK: - Remove Participant

    func test_RemoveParticipant_Succeeds() {
        // GIVEN
        _ = MockActionHandler<RemoveParticipantAction>(
            result: .success(()),
            context: uiMOC.notificationContext
        )

        // THEN
        assertMethodCompletesWithSuccess {
            // WHEN
            sut.removeParticipant(user, from: conversation, completion: $0)
        }
    }

    func test_RemoveParticipant_Fails() {
        // GIVEN
        _ = MockActionHandler<RemoveParticipantAction>(
            result: .failure(.unknown),
            context: uiMOC.notificationContext
        )

        // THEN
        assertMethodCompletesWithError(.unknown) {
            // WHEN
            sut.removeParticipant(user, from: conversation, completion: $0)
        }
    }

}
