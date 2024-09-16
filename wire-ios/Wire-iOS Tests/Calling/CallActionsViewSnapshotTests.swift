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

@testable import Wire
import WireSyncEngine
import WireTestingPackage
import XCTest

// MARK: - CallActionsViewInput

private struct CallActionsViewInput: CallActionsViewInputType {
    var allowPresentationModeUpdates: Bool
    var videoGridPresentationMode: VideoGridPresentationMode
    var permissions: CallPermissionsConfiguration
    let canToggleMediaType, isVideoCall, isMuted: Bool
    let mediaState: MediaState
    var cameraType: CaptureDevice
    let networkQuality: NetworkQuality = .normal
    let callState: CallStateExtending
}

// MARK: - CallStateMock

struct CallStateMock: CallStateExtending {
    var isConnected: Bool
    var isTerminating: Bool
    var canAccept: Bool
}

extension CallStateMock {
    static var incoming: CallStateMock {
        return CallStateMock(isConnected: false, isTerminating: false, canAccept: true)
    }

    static var outgoing: CallStateMock {
        return CallStateMock(isConnected: false, isTerminating: false, canAccept: false)
    }

    static var terminating: CallStateMock {
        return CallStateMock(isConnected: false, isTerminating: true, canAccept: false)
    }

    static var ongoing: CallStateMock {
        return CallStateMock(isConnected: true, isTerminating: false, canAccept: false)
    }
}

// MARK: - CallActionsViewSnapshotTests

final class CallActionsViewSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var sut: CallActionsView!
    private var widthConstraint: NSLayoutConstraint!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        widthConstraint = nil
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Helper method

    private func createSut(for layoutSize: CallActionsView.LayoutSize) {
        sut = CallActionsView()
        sut.backgroundColor = .black
        snapshotHelper = SnapshotHelper()

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

    // MARK: - Snapshot Tests

    func testCallActionsView_Compact() {
        // GIVEN
       createSut(for: .compact)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.compact)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: - Call State: Incoming

    func testCallActionsView_StateIncoming_Audio() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.incoming
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testCallActionsView_StateIncoming_Video() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.incoming
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: - Call State: Outgoing

    func testCallActionsView_StateOutgoing_Audio() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.outgoing
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testCallActionsView_StateOutgoing_Video() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.outgoing
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: Call State: - Ongoing

    func testCallActionsView_StateOngoing_Audio() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testCallActionsView_StateOngoing_Audio_Muted() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: true,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testCallActionsView_StateOngoing_Audio_SpeakerUnavailable() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanNotBeToggled),
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testCallActionsView_StateOngoing_Video() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testCallActionsView_StateOngoing_Video_PresentationMode_AllVideoStreams() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testCallActionsView_StateOngoing_Video_PresentationMode_ActiveSpeakers() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .activeSpeakers,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: Call State: - Terminating

    func testCallActionsView_StateTerminating_Audio() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.terminating
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testCallActionsView_StateTerminating_Video() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.terminating
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: - Permissions

    func testCallActionsView_Permissions_NotDetermined() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoPendingApproval,
            canToggleMediaType: false,
            isVideoCall: true,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testCallActionsView_Permissions_NotAllowed() {
        // GIVEN
        createSut(for: .regular)

        let input = CallActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoDeniedForever,
            canToggleMediaType: false,
            isVideoCall: true,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            cameraType: .front,
            callState: CallStateMock.ongoing
        )

        // WHEN
        sut.update(with: input)
        sut.updateToLayoutSize(.regular)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

}
