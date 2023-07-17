//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireSyncEngine

private struct CallActionsViewInput: CallActionsViewInputType {
    var allowPresentationModeUpdates: Bool
    var videoGridPresentationMode: VideoGridPresentationMode
    var permissions: CallPermissionsConfiguration
    let canToggleMediaType, isVideoCall, isMuted: Bool
    let mediaState: MediaState
    let variant: ColorSchemeVariant
    var cameraType: CaptureDevice
    let networkQuality: NetworkQuality = .normal
    let callState: CallStateExtending
}

class CallActionsViewTests: ZMSnapshotTestCase {

    fileprivate var sut: CallActionsView!
    fileprivate var widthConstraint: NSLayoutConstraint!

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .black
    }

    override func tearDown() {
        sut = nil
        widthConstraint = nil
        super.tearDown()
    }

    private func createSut(for layoutSize: CallActionsView.LayoutSize) {
        sut = CallActionsView()

        switch layoutSize {
        case .compact:
            sut.frame = CGRect(origin: .zero, size: CGSize(width: 800, height: 150))
        case .regular:
            sut.translatesAutoresizingMaskIntoConstraints = false
            widthConstraint = sut.widthAnchor.constraint(equalToConstant: 340)
            widthConstraint.isActive = true
            sut.setNeedsLayout()
            sut.layoutIfNeeded()
        }
    }

    func testCallActionsView_Compact() {
        // Given
       createSut(for: .compact)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // When
        sut.update(with: input)
        sut.updateToLayoutSize(.compact)

        // Then
        verify(view: sut)
    }

    // MARK: - Call State: Incoming

    func testCallActionsView_StateIncoming_Audio() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.incoming
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateIncoming_Video() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.incoming
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    // MARK: - Call State: Outgoing

    func testCallActionsView_StateOutgoing_Audio() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.outgoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateOutgoing_Video() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo,
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.outgoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    // MARK: Call State: - Ongoing

    func testCallActionsView_StateOngoing_Audio() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateOngoing_Audio_Muted() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: true,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateOngoing_Audio_SpeakerUnavailable() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanNotBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateOngoing_Video() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo,
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateOngoing_Video_PresentationMode_AllVideoStreams() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo,
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateOngoing_Video_PresentationMode_ActiveSpeakers() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .activeSpeakers,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo,
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    // MARK: Call State: - Terminating

    func testCallActionsView_StateTerminating_Audio() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.terminating
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateTerminating_Video() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo,
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.terminating
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    // MARK: - Permissions

    func testCallActionsView_Permissions_NotDetermined() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoPendingApproval,
            canToggleMediaType: false,
            isVideoCall: true,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_Permissions_NotAllowed() {
        // Given
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoDeniedForever,
            canToggleMediaType: false,
            isVideoCall: true,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

}
