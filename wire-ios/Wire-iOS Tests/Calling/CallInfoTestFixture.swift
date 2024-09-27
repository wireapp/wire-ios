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
@testable import Wire

extension CallStateMock {
    fileprivate static var connecting: CallStateMock { .outgoing }
}

// MARK: - CallInfoTestFixture

struct CallInfoTestFixture {
    enum GroupSize: Int {
        case large = 10
        case small = 4
    }

    let otherUser: UserType
    let selfUser: UserType
    let groupSize: GroupSize
    let mockUsers: [UserType]

    init(otherUser: UserType, selfUser: UserType, groupSize: GroupSize = .small, mockUsers: [UserType]) {
        self.otherUser = otherUser
        self.selfUser = selfUser
        self.groupSize = groupSize
        self.mockUsers = mockUsers
    }

    // MARK: - OneToOne Audio

    private var hashBoxOtherUser: HashBoxUser {
        HashBox(value: otherUser)
    }

    private var hashBoxSelfUser: HashBoxUser {
        HashBox(value: selfUser)
    }

    var oneToOneOutgoingAudioRinging: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxSelfUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.outgoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneIncomingAudioRinging: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallState.incoming(video: false, shouldRing: true, degraded: false),
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneOutgoingAudioDegraded: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .outgoing(reason: .degradedUser(user: hashBoxOtherUser)),
            accessoryType: .avatar(hashBoxSelfUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.outgoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneMlsOutgoingAudioDegraded: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .outgoing(reason: .invalidCertificate),
            accessoryType: .avatar(hashBoxSelfUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallState.outgoing(degraded: true),
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneIncomingAudioDegraded: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .incoming(reason: .degradedUser(user: hashBoxOtherUser)),
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneAudioConnecting: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.connecting,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneAudioEstablished: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: 2,
                videoState: .stopped,
                microphoneState: .unmuted,
                mockUsers: mockUsers
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneAudioEstablishedCBR: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: 2,
                videoState: .stopped,
                microphoneState: .unmuted,
                mockUsers: mockUsers
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: true,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneAudioEstablishedVBR: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: 2,
                videoState: .stopped,
                microphoneState: .unmuted,
                mockUsers: mockUsers
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneAudioEstablishedPoorNetwork: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .poor,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    // MARK: - OneToOne Video

    var oneToOneOutgoingVideoRinging: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.outgoing,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneIncomingVideoRinging: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneClassifiedIncomingVideoRinging: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .classified
        )
    }

    var oneToOneNotClassifiedIncomingVideoRinging: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .notClassified
        )
    }

    var oneToOneIncomingVideoRingingWithPermissionsDeniedForever: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoDeniedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneIncomingVideoRingingWithUndeterminedVideoPermissions: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoPendingApproval,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneIncomingVideoRingingVideoTurnedOff: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: CallVideoPlaceholderState.statusTextHidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: nil),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneVideoConnecting: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.connecting,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var oneToOneVideoEstablished: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: 2,
                videoState: .started,
                microphoneState: .unmuted,
                mockUsers: mockUsers
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    // MARK: - Group Audio

    var groupOutgoingAudioRinging: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxSelfUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.outgoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var groupIncomingAudioRinging: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: otherUser.name ?? ""),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var groupAudioConnecting: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .avatar(hashBoxOtherUser),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.connecting,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    func groupAudioEstablished(mockUsers: [UserType]) -> CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: groupSize.rawValue,
                videoState: .stopped,
                microphoneState: .unmuted,
                mockUsers: mockUsers
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    func groupAudioEstablishedRemoteTurnedVideoOn(mockUsers: [UserType]) -> CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: groupSize.rawValue,
                videoState: .started,
                microphoneState: .unmuted,
                mockUsers: mockUsers
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    func groupAudioEstablishedVideoUnavailable(mockUsers: [MockUserType]) -> CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: groupSize.rawValue,
                videoState: .stopped,
                microphoneState: .unmuted,
                mockUsers: mockUsers
            )),
            canToggleMediaType: false,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var groupAudioEstablishedCBR: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: groupSize.rawValue,
                mockUsers: SwiftMockLoader.mockUsers()
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: true,
            title: otherUser.name ?? "",
            isVideoCall: false,
            disableIdleTimer: false,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true,
            isForcedCBR: false,
            classification: .none
        )
    }

    // MARK: - Group Video

    var groupOutgoingVideoRinging: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.outgoing,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingOutgoing,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var groupIncomingVideoRinging: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: otherUser.name ?? ""),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var groupVideoConnecting: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.connecting,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .connecting,
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var groupVideoEstablishedScreenSharing: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: groupSize.rawValue,
                videoState: .screenSharing,
                mockUsers: SwiftMockLoader.mockUsers()
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var groupVideoEstablishedPoorConnection: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: groupSize.rawValue,
                videoState: .started,
                mockUsers: SwiftMockLoader.mockUsers()
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .poor,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    func groupVideoEstablished(mockUsers: [MockUserType]) -> CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: MockCallPermissions.videoAllowedForever,
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: groupSize.rawValue,
                videoState: .started,
                microphoneState: .unmuted,
                mockUsers: mockUsers
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: false,
            isForcedCBR: false,
            classification: .none
        )
    }

    var groupVideoEstablishedCBR: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: groupSize.rawValue,
                videoState: .started,
                mockUsers: SwiftMockLoader.mockUsers()
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: true,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true,
            isForcedCBR: false,
            classification: .none
        )
    }

    var groupVideoEstablishedVBR: CallInfoViewControllerInput {
        MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: .hidden,
            permissions: CallPermissions(),
            degradationState: .none,
            accessoryType: .participantsList(CallParticipantsListHelper.participants(
                count: groupSize.rawValue,
                videoState: .started,
                mockUsers: SwiftMockLoader.mockUsers()
            )),
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.ongoing,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .established(duration: 10),
            isConstantBitRate: false,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true,
            isForcedCBR: false,
            classification: .none
        )
    }

    var groupVideoIncomingUndeterminedPermissions: CallInfoViewControllerInput {
        let permissions = MockCallPermissions.videoPendingApproval
        return MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: permissions.preferredVideoPlaceholderState,
            permissions: permissions,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: otherUser.name ?? ""),
            isConstantBitRate: true,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true,
            isForcedCBR: false,
            classification: .none
        )
    }

    var groupVideoIncomingDeniedPermissions: CallInfoViewControllerInput {
        let permissions = MockCallPermissions.videoDeniedForever
        return MockCallInfoViewControllerInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            videoPlaceholderState: permissions.preferredVideoPlaceholderState,
            permissions: permissions,
            degradationState: .none,
            accessoryType: .none,
            canToggleMediaType: true,
            isMuted: false,
            callState: CallStateMock.incoming,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            state: .ringingIncoming(name: otherUser.name ?? ""),
            isConstantBitRate: true,
            title: otherUser.name ?? "",
            isVideoCall: true,
            disableIdleTimer: true,
            cameraType: .front,
            networkQuality: .normal,
            userEnabledCBR: true,
            isForcedCBR: false,
            classification: .none
        )
    }
}
