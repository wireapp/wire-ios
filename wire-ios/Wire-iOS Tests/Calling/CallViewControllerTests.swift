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
@testable import Wire

extension XCTestCase {
    func verifyDeallocation<T: AnyObject>(of instanceGenerator: () -> (T)) {
        weak var weakInstance: T?
        var instance: T?

        autoreleasepool {
            instance = instanceGenerator()
            // then
            weakInstance = instance
            XCTAssertNotNil(weakInstance)
            // when
            instance = nil
        }

        XCTAssertNil(instance)
        XCTAssertNil(weakInstance)
    }
}

// MARK: - CallViewControllerTests

final class CallViewControllerTests: ZMSnapshotTestCase {
    var mockVoiceChannel: MockVoiceChannel!
    var conversation: ZMConversation!
    var sut: CallViewController!
    var userSession: UserSessionMock!
    var selfUser: ZMUser!
    var otherUser: ZMUser!

    override func setUp() {
        super.setUp()
        selfUser = ZMUser.selfUser(in: uiMOC)
        otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = UUID()
        otherUser.name = "Bruno"
        userSession = UserSessionMock()
        conversation = createOneOnOneConversation(selfUser: selfUser, otherUser: otherUser, messageProtocol: .proteus)
        mockVoiceChannel = MockVoiceChannel(conversation: conversation)
        mockVoiceChannel.mockVideoState = VideoState.started
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockCallState = CallState.established

        let userClient = MockUserClient()
        userClient.remoteIdentifier = UUID().transportString()

        let mockSelfUser = MockUser.mockUsers()[0]
        MockUser.setMockSelf(mockSelfUser)
        MockUser.mockSelf()?.remoteIdentifier = UUID()
        MockUser.mockSelf()?.clients = [userClient]
        MockUser.mockSelf()?.isSelfUser = true

        sut = createCallViewController(selfUser: MockUser.mockSelf(), mediaManager: ZMMockAVSMediaManager())
    }

    override func tearDown() {
        selfUser = nil
        otherUser = nil
        userSession = nil
        sut = nil
        conversation = nil
        mockVoiceChannel = nil
        super.tearDown()
    }

    private func createCallViewController(
        selfUser: UserType,
        mediaManager: ZMMockAVSMediaManager
    ) -> CallViewController {
        let proximityManager = ProximityMonitorManager()
        let callController = CallViewController(
            voiceChannel: mockVoiceChannel,
            selfUser: selfUser,
            proximityMonitorManager: proximityManager,
            mediaManager: mediaManager,
            userSession: userSession
        )

        return callController
    }

    private func participants(amount: Int) -> [CallParticipant] {
        var participants = [CallParticipant]()

        for _ in 0 ..< amount {
            participants.append(
                CallParticipant(
                    user: MockUserType(),
                    userId: AVSIdentifier.stub,
                    clientId: UUID().transportString(),
                    state: .connected(videoState: .started, microphoneState: .unmuted),
                    activeSpeakerState: .inactive
                )
            )
        }

        return participants
    }

    func testThatVideoGridPresentationMode_IsUpdatedToAllVideoStreams_WhenUnderThreeParticipants() {
        // Given
        mockVoiceChannel.videoGridPresentationMode = .activeSpeakers

        // When
        sut.callParticipantsDidChange(conversation: conversation, participants: participants(amount: 2))

        // Then
        XCTAssertEqual(mockVoiceChannel.videoGridPresentationMode, VideoGridPresentationMode.allVideoStreams)
    }

    func testThatVideoGridPresentationMode_IsNotUpdated_WhenOverTwoParticipants() {
        // Given
        mockVoiceChannel.videoGridPresentationMode = .activeSpeakers

        // When
        sut.callParticipantsDidChange(conversation: conversation, participants: participants(amount: 3))

        // Then
        XCTAssertEqual(mockVoiceChannel.videoGridPresentationMode, VideoGridPresentationMode.activeSpeakers)
    }

    func testThatCallGridViewControllerDelegate_ForwardsVideoStreamsRequestToVoiceChannel() {
        // Given
        let configuration = MockCallGridViewControllerInput()
        let viewController = CallGridViewController(
            voiceChannel: mockVoiceChannel,
            configuration: configuration
        )
        let clients = [
            AVSClient(userId: AVSIdentifier.stub, clientId: UUID().transportString()),
            AVSClient(userId: AVSIdentifier.stub, clientId: UUID().transportString()),
        ]

        // When
        sut.callGridViewController(viewController, perform: .requestVideoStreamsForClients(clients))

        // Then
        XCTAssertEqual(mockVoiceChannel.requestedVideoStreams, clients)
    }

    func testThatItDeallocates() {
        // when & then
        verifyDeallocation { () -> CallViewController in
            // given
            let callController = createCallViewController(
                selfUser: MockUserType.createSelfUser(name: "Alice"),
                mediaManager: ZMMockAVSMediaManager()
            )
            // Simulate user click
            callController.startOverlayTimer()
            return callController
        }
    }

    // MARK: - Mock ZMConversation

    func createOneOnOneConversation(
        selfUser: ZMUser,
        otherUser: ZMUser,
        messageProtocol: MessageProtocol
    ) -> ZMConversation {
        let mockConversation = ZMConversation.insertNewObject(in: uiMOC)
        mockConversation.messageProtocol = messageProtocol
        mockConversation.addParticipantAndUpdateConversationState(user: selfUser)

        mockConversation.conversationType = .oneOnOne
        mockConversation.remoteIdentifier = UUID.create()
        mockConversation.oneOnOneUser = otherUser

        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = otherUser
        connection.status = .accepted

        return mockConversation
    }
}
