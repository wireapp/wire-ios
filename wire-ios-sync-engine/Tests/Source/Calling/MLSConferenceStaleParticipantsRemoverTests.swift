//
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

import Foundation
import XCTest
@testable import WireSyncEngine

class MLSConferenceStaleParticipantsRemoverTests: MessagingTest {

    private let domain = "example.domain.com"
    private let groupID = MLSGroupID.random()
    private let connectedState = CallParticipantState.connected(
        videoState: .stopped,
        microphoneState: .muted
    )

    private var mlsService: MockMLSService!
    private var sut: MLSConferenceStaleParticipantsRemover!

    override func setUp() {
        super.setUp()
        mlsService = MockMLSService()
        sut = MLSConferenceStaleParticipantsRemover(
            mlsService: mlsService,
            context: uiMOC,
            removalTimeout: 0.4
        )
    }

    override func tearDown() {
        mlsService = nil
        sut = nil
        super.tearDown()
    }

    func test_ItRemovesStaleParticipantsAfterTimeout() {
        // GIVEN

        // create call participants
        let participants = [
            createMLSParticipant(state: .connecting),
            createMLSParticipant(state: .connecting),
            createMLSParticipant(state: connectedState),
            createMLSParticipant(state: connectedState)
        ]

        // mock subconversation members
        mlsService.mockSubconversationMembers = { _ in
            return participants.map(\.mlsClientID)
        }

        // set expectations
        let expectations = expectations(from: participants)
        mlsService.mockRemoveMembersFromConversation = { clientIDs, _ in
            guard let id = clientIDs.first else { return }
            expectations[id]?.fulfill()
        }

        // WHEN
        _ = sut.receive(
            MLSConferenceParticipantsInfo(
                participants: participants.map(\.callParticipant),
                subconversationID: groupID
            )
        )

        // THEN
        wait(for: Array(expectations.values), timeout: 0.5)
    }

    func test_ItDoesntRemoveParticipantsThatReconnectedBeforeTimeout() {
        // GIVEN

        // create call participants
        let participants = [
            createMLSParticipant(state: .connecting),
            createMLSParticipant(state: .connecting),
            createMLSParticipant(state: .connecting)
        ]

        // mock subconversation members
        mlsService.mockSubconversationMembers = { _ in
            return participants.map(\.mlsClientID)
        }

        // create input for the subscriber
        let input = MLSConferenceParticipantsInfo(
            participants: participants.map(\.callParticipant),
            subconversationID: groupID
        )

        // WHEN
        _ = sut.receive(
            MLSConferenceParticipantsInfo(
                participants: participants.map(\.callParticipant),
                subconversationID: groupID
            )
        )

        participants[0].updateState(connectedState)
        participants[1].updateState(connectedState)

        let expectations = expectations(from: participants)
        mlsService.mockRemoveMembersFromConversation = { clientIDs, _ in
            guard let id = clientIDs.first else { return }
            expectations[id]?.fulfill()
        }

        _ = sut.receive(
            MLSConferenceParticipantsInfo(
                participants: participants.map(\.callParticipant),
                subconversationID: groupID
            )
        )

        // THEN
        wait(for: Array(expectations.values), timeout: 0.5)
    }

    func test_ItDoesntRemoveStaleParticipantIfTheyAreNotInConversation() {
        // GIVEN

        // create call participants
        let participants = [
            createMLSParticipant(state: .connecting),
            createMLSParticipant(state: .connecting)
        ]

        // mock subconversation members
        mlsService.mockSubconversationMembers = { _ in
            return []
        }

        // set expectations
        let expectation = XCTestExpectation()
        expectation.isInverted = true

        // fulfill expectation
        mlsService.mockRemoveMembersFromConversation = { _, _ in
            expectation.fulfill()
        }

        // WHEN
        _ = sut.receive(
            MLSConferenceParticipantsInfo(
                participants: participants.map(\.callParticipant),
                subconversationID: groupID
            )
        )

        // THEN
        wait(for: [expectation], timeout: 0.5)
    }

    func test_PerformPendingRemovals_RemovesParticipantsBeforeTimeout() {
        // GIVEN
        let participants = [
            createMLSParticipant(state: .connecting)
        ]

        mlsService.mockSubconversationMembers = { _ in
            return participants.map(\.mlsClientID)
        }

        var removedMembers = [MLSClientID]()
        let expectation = XCTestExpectation()
        mlsService.mockRemoveMembersFromConversation = { clientIDs, _ in
            removedMembers = clientIDs
            expectation.fulfill()
        }

        _ = sut.receive(
            MLSConferenceParticipantsInfo(
                participants: participants.map(\.callParticipant),
                subconversationID: groupID
            )
        )

        // WHEN
        sut.performPendingRemovals()

        // THEN
        // pending removals should be executed immediately but it's still async so we wait for .1 second
        // another reason to wait for .1s is because the removal timeout is .4 seconds and we want to assert removals are triggered right away
        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(participants.map(\.mlsClientID), removedMembers)
    }

    // MARK: - Helpers

    private func expectations(
        from participants: [MLSParticipant]
    ) -> [MLSClientID: XCTestExpectation] {
        return participants.reduce(into: [MLSClientID: XCTestExpectation]()) { expectations, participant in
            var expectation: XCTestExpectation

            switch participant.callParticipant.state {
            case .connecting:
                expectation = XCTestExpectation(description: "removed stale participant (\(participant.mlsClientID))")
            default:
                expectation = XCTestExpectation(description: "did not remove participant (\(participant.mlsClientID))")
                expectation.isInverted = true
            }

            expectations[participant.mlsClientID] = expectation
        }
    }

    private func createMLSParticipant(state: CallParticipantState) -> MLSParticipant {
        let userID = UUID()

        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = userID
        user.domain = domain

        let clientID = UUID().transportString()

        let callParticipant = CallParticipant(
            user: user,
            clientId: clientID,
            state: state,
            activeSpeakerState: .inactive
        )

        let mlsClientID = MLSClientID(
            userID: userID.transportString(),
            clientID: clientID,
            domain: domain
        )

        return MLSParticipant(
            callParticipant: callParticipant,
            mlsClientID: mlsClientID
        )
    }
}

private class MLSParticipant {
    var callParticipant: CallParticipant
    var mlsClientID: MLSClientID

    init(callParticipant: CallParticipant, mlsClientID: MLSClientID) {
        self.callParticipant = callParticipant
        self.mlsClientID = mlsClientID
    }

    func updateState(_ state: CallParticipantState) {
        self.callParticipant = CallParticipant(
            user: callParticipant.user as! ZMUser,
            clientId: callParticipant.clientId,
            state: state,
            activeSpeakerState: callParticipant.activeSpeakerState
        )
    }
}
