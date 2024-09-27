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

import WireSyncEngine
import XCTest
@testable import Wire

func == (lhs: CallInfoViewControllerInput, rhs: CallInfoViewControllerInput) -> Bool {
    lhs.isEqual(toConfiguration: rhs)
}

// MARK: - CallInfoConfigurationTests

final class CallInfoConfigurationTests: ZMSnapshotTestCase {
    // MARK: Internal

    var mockUsers: [MockUserType]!
    var selfUser: ZMUser!
    var otherUser: ZMUser!

    override func setUp() {
        super.setUp()

        mockUsers = SwiftMockLoader.mockUsers()
        CallingConfiguration.config = .largeConferenceCalls

        otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = UUID()
        otherUser.name = "Bruno"

        selfUser = ZMUser.selfUser(in: uiMOC)
    }

    override func tearDown() {
        mockUsers = nil
        selfUser = nil
        otherUser = nil
        CallingConfiguration.testHelper_resetDefaultConfig()

        super.tearDown()
    }

    func assertEquals(
        _ lhsConfig: CallInfoViewControllerInput,
        _ rhsConfig: CallInfoViewControllerInput,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            lhsConfig.accessoryType == rhsConfig.accessoryType,
            "\n\(lhsConfig)\n\nis not equal to\n\n\(rhsConfig)",
            file: file,
            line: line
        )

        XCTAssertTrue(
            lhsConfig.degradationState == rhsConfig.degradationState,
            "\n\(lhsConfig)\n\nis not equal to\n\n\(rhsConfig)",
            file: file,
            line: line
        )

        XCTAssertTrue(
            lhsConfig.videoPlaceholderState == rhsConfig.videoPlaceholderState,
            "\n\(lhsConfig)\n\nis not equal to\n\n\(rhsConfig)",
            file: file,
            line: line
        )

        XCTAssertTrue(
            lhsConfig.disableIdleTimer == rhsConfig.disableIdleTimer,
            "\n\(lhsConfig)\n\nis not equal to\n\n\(rhsConfig)",
            file: file,
            line: line
        )
    }

    // MARK: - OneToOne Audio

    @MainActor
    func testOneToOneIncomingAudioRinging() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: [otherUser]
        )

        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneIncomingAudioRinging, configuration)
    }

    @MainActor
    func testOneToOneOutgoingAudioRinging() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = selfUser

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneOutgoingAudioRinging, configuration)
    }

    @MainActor
    func testOneToOneProteusConversationIncomingAudioDegraded() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: [otherUser]
        )

        ((mockConversation.sortedActiveParticipants.first as Any) as? MockUser)?.isTrusted = true
        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: true)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockFirstDegradedUser = otherUser

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneIncomingAudioDegraded, configuration)
    }

    @MainActor
    func testOneToOneProteusConversationOutgoingAudioDegraded() {
        // given
        let mockConversation = createOneOnOneConversation()

        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: [otherUser]
        )

        ((mockConversation.sortedActiveParticipants.first as Any) as? MockUser)?.isTrusted = true
        mockVoiceChannel.mockCallState = .outgoing(degraded: true)
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockFirstDegradedUser = otherUser

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneOutgoingAudioDegraded, configuration)
    }

    @MainActor
    func testOneToOneMlsConversationOutgoingAudioDegraded() {
        // given
        let mockConversation = createOneOnOneConversation(messageProtocol: .mls)

        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: [otherUser]
        )

        mockVoiceChannel.mockCallState = .outgoing(degraded: true)
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockFirstDegradedUser = otherUser

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneMlsOutgoingAudioDegraded, configuration)
    }

    @MainActor
    func testOneToOneAudioConnecting() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: [otherUser]
        )

        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = otherUser

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneAudioConnecting, configuration)
    }

    @MainActor
    func testOneToOneAudioEstablishedUpgradedToVideo() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.videoState = .started
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: 2,
            state: .connected(
                videoState: .started,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneVideoEstablished, configuration)
    }

    @MainActor
    func testOneToOneAudioEstablished() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: 2,
            state: .connected(
                videoState: .stopped,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneAudioEstablished, configuration)
    }

    @MainActor
    func testOneToOneAudioEstablishedCBR() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockIsConstantBitRateAudioActive = true
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: 2,
            state: .connected(
                videoState: .stopped,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: true,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneAudioEstablishedCBR, configuration)
    }

    @MainActor
    func testOneToOneAudioEstablishedVBR() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockIsConstantBitRateAudioActive = false
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: 2,
            state: .connected(
                videoState: .stopped,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: true,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneAudioEstablishedVBR, configuration)
    }

    // MARK: - OneToOne Video

    @MainActor
    func testOneToOneIncomingVideoRinging() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneIncomingVideoRinging, configuration)
    }

    @MainActor
    func testOneToOneIncomingVideoRingingVideoTurnedOff() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: [otherUser]
        )

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .stopped

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .statusTextHidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneIncomingVideoRingingVideoTurnedOff, configuration)
    }

    @MainActor
    func testOneToOneOutgoingVideoRinging() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneOutgoingVideoRinging, configuration)
    }

    @MainActor
    func testOneToOneVideoConnecting() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneVideoConnecting, configuration)
    }

    @MainActor
    func testOneToOneVideoEstablished() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: 2,
            state: .connected(
                videoState: .started,
                microphoneState: .unmuted
            )
        )

        let permissions = MockCallPermissions()
        permissions.canAcceptVideoCalls = true
        permissions.isPendingVideoPermissionRequest = false

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneVideoEstablished, configuration)
    }

    @MainActor
    func testOneToOneVideoEstablishedWithScreenSharing() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .screenSharing
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: 2,
            state: .connected(
                videoState: .started,
                microphoneState: .unmuted
            )
        )

        let permissions = MockCallPermissions()
        permissions.canAcceptVideoCalls = true
        permissions.isPendingVideoPermissionRequest = false

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneVideoEstablished, configuration)
    }

    @MainActor
    func testOneToOneVideoEstablishedDowngradedToAudio() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .stopped
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: 2,
            state: .connected(
                videoState: .stopped,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneAudioEstablished, configuration)
    }

    // MARK: - Group Audio

    @MainActor
    func testGroupIncomingAudioRinging() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsConferenceCall = true

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.groupIncomingAudioRinging, configuration)
    }

    @MainActor
    func testGroupOutgoingAudioRinging() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockIsConferenceCall = true

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.groupOutgoingAudioRinging, configuration)
    }

    @MainActor
    func testGroupAudioConnecting() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)
        selfUser.teamIdentifier = UUID()

        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = otherUser

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.groupAudioConnecting, configuration)
    }

    @MainActor
    func testGroupAudioEstablished() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)
        selfUser.teamIdentifier = UUID()

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: fixture.groupSize.rawValue,
            state: .connected(
                videoState: .stopped,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.groupAudioEstablished(mockUsers: mockUsers), configuration)
    }

    @MainActor
    func testGroupAudioEstablishedNonTeamUser() {
        // given
        let mockConversation = createGroupConversation()

        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)

        otherUser.teamIdentifier = nil
        selfUser.teamIdentifier = nil

        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: fixture.groupSize.rawValue,
            state: .connected(
                videoState: .stopped,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(
            fixture.groupAudioEstablishedVideoUnavailable(mockUsers: mockUsers),
            configuration
        ) // canToggleMediaType
    }

    @MainActor
    func testGroupAudioEstablishedNonTeamUserRemoteTurnedVideoOn() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: fixture.groupSize.rawValue,
            state: .connected(
                videoState: .started,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.groupAudioEstablishedRemoteTurnedVideoOn(mockUsers: mockUsers), configuration)
    }

    @MainActor
    func testGroupAudioEstablishedLargeGroup() {
        // given
        let fixture = CallInfoTestFixture(
            otherUser: otherUser,
            selfUser: selfUser,
            groupSize: .large,
            mockUsers: mockUsers
        )

        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)

        selfUser.teamIdentifier = UUID()

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: fixture.groupSize.rawValue,
            state: .connected(
                videoState: .stopped,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.groupAudioEstablishedVideoUnavailable(mockUsers: mockUsers), configuration)
    }

    @MainActor
    func testOneToOneIncomingVideoRingingWithVideoPermissionsDeniedForever() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoDeniedForever,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneIncomingVideoRingingWithPermissionsDeniedForever, configuration)
    }

    @MainActor
    func testOneToOneIncomingVideoRingingWithUndeterminedVideoPermissions() {
        // given
        let mockConversation = createOneOnOneConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(
            otherUser: mockConversation.connectedUser!,
            selfUser: selfUser,
            mockUsers: mockUsers
        )

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockVideoState = .started

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoPendingApproval,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.oneToOneIncomingVideoRingingWithUndeterminedVideoPermissions, configuration)
    }

    // MARK: - Group Video

    @MainActor
    func testGroupIncomingVideoRinging() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.groupIncomingVideoRinging, configuration)
    }

    @MainActor
    func testGroupOutgoingVideoRinging() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.groupOutgoingVideoRinging, configuration)
    }

    @MainActor
    func testGroupVideoConnecting() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.groupVideoConnecting, configuration)
    }

    @MainActor
    func testGroupVideoEstablished() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.videoState = .started
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: fixture.groupSize.rawValue,
            state: .connected(
                videoState: .started,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        assertEquals(fixture.groupVideoEstablished(mockUsers: mockUsers), configuration)
    }

    // MARK: - Video Placeholder

    @MainActor
    func testVideoPermissionsPlaceholderRespectsPreferenceInIncomingVideoCall() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: true, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: fixture.groupSize.rawValue,
            state: .connected(
                videoState: .started,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .statusTextHidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .statusTextHidden)
    }

    @MainActor
    func testVideoPermissionsPlaceholderHiddenInIncomingAudioCall() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)

        mockVoiceChannel.mockCallState = .incoming(video: false, shouldRing: true, degraded: false)
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = false
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: fixture.groupSize.rawValue,
            state: .connected(
                videoState: .started,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .statusTextHidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .hidden)
    }

    @MainActor
    func testVideoPermissionsPlaceholderHiddenInEstablishedVideoCall() {
        // given
        let mockConversation = createGroupConversation()
        let mockVoiceChannel = MockVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser, selfUser: selfUser, mockUsers: mockUsers)

        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = otherUser
        mockVoiceChannel.mockIsVideoCall = true
        mockVoiceChannel.mockParticipants = mockCallParticipants(
            mockUsers: mockUsers,
            count: fixture.groupSize.rawValue,
            state: .connected(
                videoState: .started,
                microphoneState: .unmuted
            )
        )

        // when
        let configuration = CallInfoConfiguration(
            voiceChannel: mockVoiceChannel,
            preferedVideoPlaceholderState: .statusTextHidden,
            permissions: CallPermissions(),
            cameraType: .front,
            userEnabledCBR: false,
            selfUser: selfUser
        )

        // then
        XCTAssertEqual(configuration.videoPlaceholderState, .hidden)
    }

    // MARK: Private

    private func mockCallParticipants(
        mockUsers: [MockUserType],
        count: Int,
        state: CallParticipantState
    ) -> [CallParticipant] {
        mockUsers[0 ..< count].map {
            CallParticipant(
                user: $0,
                userId: AVSIdentifier.stub,
                clientId: "123",
                state: state,
                activeSpeakerState: .inactive
            )
        }
    }

    // MARK: - Mock ZMConversation

    private func createOneOnOneConversation(messageProtocol: MessageProtocol = .proteus) -> ZMConversation {
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

    private func createGroupConversation(messageProtocol: MessageProtocol = .proteus) -> ZMConversation {
        let mockConversation = ZMConversation.insertNewObject(in: uiMOC)
        mockConversation.messageProtocol = messageProtocol
        mockConversation.remoteIdentifier = UUID.create()
        mockConversation.conversationType = .group

        let role = Role(context: uiMOC)
        role.name = ZMConversation.defaultAdminRoleName
        mockConversation.addParticipantsAndUpdateConversationState(users: [selfUser], role: role)

        return mockConversation
    }
}
