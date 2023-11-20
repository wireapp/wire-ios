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
import WireTesting
@testable import WireRequestStrategy

class ConversationParticipantsServiceTests: MessagingTestBase {

    // MARK: - Properties

    var sut: ConversationParticipantsService!
    var mockProteusParticipantsService: MockProteusConversationParticipantsServiceInterface!
    var mockMLSParticipantsService: MockMLSConversationParticipantsServiceInterface!
    var selfUser: ZMUser!
    var conversation: ZMConversation!
    var user: ZMUser!

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()

        // Set mocks for Proteus participants service
        mockProteusParticipantsService = MockProteusConversationParticipantsServiceInterface()

        mockProteusParticipantsService.removeParticipantFromCompletion_MockMethod = { _, _, completion in
            completion(.success(()))
        }

        mockProteusParticipantsService.addParticipantsToCompletion_MockMethod = { _, _, completion in
            completion(.success(()))
        }

        // Set mocks for MLS participants service
        mockMLSParticipantsService = MockMLSConversationParticipantsServiceInterface()

        mockMLSParticipantsService.removeParticipantFromCompletion_MockMethod = { _, _, completion in
            completion(.success(()))
        }

        mockMLSParticipantsService.addParticipantsToCompletion_MockMethod = { _, _, completion in
            completion(.success(()))
        }

        // Set users and conversation stubs
        selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = .create()

        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        user = ZMUser.insertNewObject(in: uiMOC)

        // Set up sut
        sut = ConversationParticipantsService(
            context: uiMOC,
            proteusParticipantsService: mockProteusParticipantsService,
            mlsParticipantsService: mockMLSParticipantsService
        )
    }

    override func tearDown() {
        mockProteusParticipantsService = nil
        mockMLSParticipantsService = nil
        selfUser = nil
        conversation = nil
        user = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Adding Participants

    func test_AddParticipants_InvalidOperation_WrongConversationType() {
        // GIVEN
        conversation.conversationType = .oneOnOne

        // WHEN / THEN
        assertMethodCompletesWithError(.invalidOperation) {
            sut.addParticipants([user], to: conversation, completion: $0)
        }
    }

    func test_AddParticipants_InvalidOperation_SelfUser() {
        assertMethodCompletesWithError(.invalidOperation) {
            sut.addParticipants([selfUser], to: conversation, completion: $0)
        }
    }

    func test_AddParticipants_Proteus() {
        // GIVEN
        conversation.messageProtocol = .proteus

        // WHEN
        sut.addParticipants([user], to: conversation, completion: { _ in })

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.addParticipantsToCompletion_Invocations.count, 1)
        XCTAssertEqual(mockMLSParticipantsService.addParticipantsToCompletion_Invocations.count, 0)
    }

    func test_AddParticipants_MLS() {
        // GIVEN
        conversation.messageProtocol = .mls

        // WHEN
        sut.addParticipants([user], to: conversation, completion: { _ in })

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.addParticipantsToCompletion_Invocations.count, 0)
        XCTAssertEqual(mockMLSParticipantsService.addParticipantsToCompletion_Invocations.count, 1)
    }

    func test_AddParticipants_Mixed() {
        // GIVEN
        conversation.messageProtocol = .mixed

        // WHEN
        sut.addParticipants([user], to: conversation, completion: { _ in })

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.addParticipantsToCompletion_Invocations.count, 1)
        XCTAssertEqual(mockMLSParticipantsService.addParticipantsToCompletion_Invocations.count, 1)
    }

    // MARK: - Removing Participants

    func test_RemoveParticipants_InvalidOperation() {
        conversation.conversationType = .oneOnOne

        assertMethodCompletesWithError(.invalidOperation) {
            sut.removeParticipant(user, from: conversation, completion: $0)
        }
    }

    func test_RemoveParticipants_Proteus() {
        // GIVEN
        conversation.messageProtocol = .proteus

        // WHEN
        sut.removeParticipant(user, from: conversation, completion: { _ in })

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.removeParticipantFromCompletion_Invocations.count, 1)
        XCTAssertEqual(mockMLSParticipantsService.removeParticipantFromCompletion_Invocations.count, 0)
    }

    func test_RemoveParticipants_Mixed() {
        // GIVEN
        conversation.messageProtocol = .mixed

        // WHEN
        sut.removeParticipant(user, from: conversation, completion: { _ in })

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.removeParticipantFromCompletion_Invocations.count, 1)
        XCTAssertEqual(mockMLSParticipantsService.removeParticipantFromCompletion_Invocations.count, 0)
    }

    func test_RemoveParticipants_MLS_forSelfUser() {
        // GIVEN
        conversation.messageProtocol = .mls

        // WHEN
        sut.removeParticipant(selfUser, from: conversation, completion: { _ in })

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.removeParticipantFromCompletion_Invocations.count, 1)
        XCTAssertEqual(mockMLSParticipantsService.removeParticipantFromCompletion_Invocations.count, 0)
    }

    func test_RemoveParticipants_MLS_forOtherUsers() {
        // GIVEN
        conversation.messageProtocol = .mls

        // WHEN
        sut.removeParticipant(user, from: conversation, completion: { _ in })

        // THEN
        XCTAssertEqual(mockProteusParticipantsService.removeParticipantFromCompletion_Invocations.count, 0)
        XCTAssertEqual(mockMLSParticipantsService.removeParticipantFromCompletion_Invocations.count, 1)
    }
}
