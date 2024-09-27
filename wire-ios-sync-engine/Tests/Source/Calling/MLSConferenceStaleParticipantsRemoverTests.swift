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
import WireDataModelSupport
import WireTesting
import XCTest
@testable import WireSyncEngine

class MLSConferenceStaleParticipantsRemoverTests: MessagingTest {
    private let domain = "example.domain.com"
    private let groupID = MLSGroupID.random()
    private let connectedState = CallParticipantState.connected(
        videoState: .stopped,
        microphoneState: .muted
    )

    private var mlsService: MockMLSServiceInterface!
    private var sut: MLSConferenceStaleParticipantsRemover!
    private var selfUserID: AVSIdentifier!

    override func setUp() {
        super.setUp()

        mlsService = .init()
        sut = MLSConferenceStaleParticipantsRemover(
            mlsService: mlsService,
            syncContext: uiMOC,
            removalTimeout: 0.4
        )

        selfUserID = AVSIdentifier(identifier: UUID(), domain: domain)
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
            createMLSParticipant(state: connectedState),
            createMLSParticipant(state: connectedState),
        ]

        // mock subconversation members
        mlsService.subconversationMembersFor_MockMethod = { _ in
            participants.map(\.mlsClientID)
        }

        // set expectations
        let expectations = expectations(from: participants)
        mlsService.removeMembersFromConversationWithFor_MockMethod = { clientIDs, _ in
            guard let id = clientIDs.first else { return }
            expectations[id]?.fulfill()
        }

        // WHEN
        _ = sut.receive(
            MLSConferenceParticipantsInfo(
                participants: participants.map(\.callParticipant),
                selfUserID: selfUserID,
                subconversationID: groupID
            )
        )
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 1))

        // THEN
        wait(for: Array(expectations.values), timeout: 1)
    }

    func test_ItDoesntRemoveParticipantsThatReconnectedBeforeTimeout() {
        // GIVEN

        // create call participants
        let participants = [
            createMLSParticipant(state: .connecting),
            createMLSParticipant(state: .connecting),
            createMLSParticipant(state: .connecting),
        ]

        // mock subconversation members
        mlsService.subconversationMembersFor_MockMethod = { _ in
            participants.map(\.mlsClientID)
        }

        // WHEN
        _ = sut.receive(
            MLSConferenceParticipantsInfo(
                participants: participants.map(\.callParticipant),
                selfUserID: selfUserID,
                subconversationID: groupID
            )
        )

        participants[0].updateState(connectedState)
        participants[1].updateState(connectedState)

        let expectations = expectations(from: participants)
        mlsService.removeMembersFromConversationWithFor_MockMethod = { clientIDs, _ in
            guard let id = clientIDs.first else { return }
            expectations[id]?.fulfill()
        }

        _ = sut.receive(
            MLSConferenceParticipantsInfo(
                participants: participants.map(\.callParticipant),
                selfUserID: selfUserID,
                subconversationID: groupID
            )
        )
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        wait(for: Array(expectations.values), timeout: 0.5)
    }

    func test_ItDoesntRemoveStaleParticipantIfTheyAreNotInConversation() {
        // GIVEN

        // create call participants
        let participants = [
            createMLSParticipant(state: .connecting),
            createMLSParticipant(state: .connecting),
        ]

        // mock subconversation members
        mlsService.subconversationMembersFor_MockMethod = { _ in
            []
        }

        // set expectations
        let expectation = XCTestExpectation().inverted()

        // fulfill expectation
        mlsService.removeMembersFromConversationWithFor_MockMethod = { _, _ in
            expectation.fulfill()
        }

        // WHEN
        _ = sut.receive(
            MLSConferenceParticipantsInfo(
                participants: participants.map(\.callParticipant),
                selfUserID: selfUserID,
                subconversationID: groupID
            )
        )

        // THEN
        wait(for: [expectation], timeout: 0.5)
    }

    func test_CancelPendingRemovals_CancelsRemovals() {
        // GIVEN

        // create call participants
        let participants = [
            createMLSParticipant(state: .connecting),
        ]

        // mock subconversation members
        mlsService.subconversationMembersFor_MockMethod = { _ in
            participants.map(\.mlsClientID)
        }

        // mock remove members
        let expectation = XCTestExpectation().inverted()
        mlsService.removeMembersFromConversationWithFor_MockMethod = { _, _ in
            expectation.fulfill()
        }

        // notify sut of stale participants
        _ = sut.receive(
            MLSConferenceParticipantsInfo(
                participants: participants.map(\.callParticipant),
                selfUserID: selfUserID,
                subconversationID: groupID
            )
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // WHEN
        sut.cancelPendingRemovals()

        // THEN
        wait(for: [expectation], timeout: 0.5)
    }

    // MARK: - Helpers

    private func expectations(
        from participants: [MLSParticipant]
    ) -> [MLSClientID: XCTestExpectation] {
        participants.reduce(into: [MLSClientID: XCTestExpectation]()) { expectations, participant in
            var expectation = switch participant.callParticipant.state {
            case .connecting:
                XCTestExpectation(description: "removed stale participant (\(participant.mlsClientID))")
            default:
                XCTestExpectation(description: "did not remove participant (\(participant.mlsClientID))").inverted()
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
        callParticipant = CallParticipant(
            user: callParticipant.user as! ZMUser,
            clientId: callParticipant.clientId,
            state: state,
            activeSpeakerState: callParticipant.activeSpeakerState
        )
    }
}
