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

import WireTestingPackage
import WireUtilities
import XCTest
@testable import Wire

// MARK: - CallParticipantsListHelper

enum CallParticipantsListHelper {
    static func participants(
        count participantCount: Int,
        videoState: VideoState? = nil,
        microphoneState: MicrophoneState? = nil,
        mockUsers: [UserType]
    ) -> CallParticipantsList {
        let sortedParticipants = (0 ..< participantCount)
            .lazy
            .map { mockUsers[$0] }
            .sortedAscendingPrependingNil(by: \.name)
        var callParticipantState: CallParticipantState = .connecting
        if let videoState, let microphoneState {
            callParticipantState = .connected(videoState: videoState, microphoneState: microphoneState)
        }

        return sortedParticipants.map { CallParticipantsListCellConfiguration.callParticipant(
            user: HashBox(value: $0),
            callParticipantState: callParticipantState,
            activeSpeakerState: .inactive
        )
        }
    }
}

// MARK: - CallParticipantsListViewControllerTests

final class CallParticipantsListViewControllerTests: XCTestCase {
    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: CallParticipantsListViewController!
    private var mockParticipants: CallParticipantsList!
    private var selfUser: UserType!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = .init()
        mockParticipants = CallParticipantsListHelper.participants(
            count: 10,
            videoState: .stopped,
            microphoneState: .muted,
            mockUsers: SwiftMockLoader.mockUsers()
        )
        selfUser = ZMUser.selfUser()
        guard selfUser != nil else {
            XCTFail("ZMUser.selfUser() is nil")
            return
        }
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        selfUser = nil
        mockParticipants = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testCallParticipants_Overflowing_Light() {
        // GIVEN && WHEN
        sut = CallParticipantsListViewController(
            participants: mockParticipants,
            showParticipants: true,
            selfUser: selfUser
        )
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.setNeedsLayout()
        sut.view.layoutIfNeeded()
        sut.view.backgroundColor = .white

        // THEN
        snapshotHelper.verify(matching: sut.view)
    }

    func testCallParticipants_Overflowing_Dark() {
        // GIVEN && WHEN
        sut = CallParticipantsListViewController(
            participants: mockParticipants,
            showParticipants: true,
            selfUser: selfUser
        )
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.setNeedsLayout()
        sut.view.layoutIfNeeded()
        sut.view.backgroundColor = .black
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        snapshotHelper.verify(matching: sut.view)
    }

    func testCallParticipants_Truncated_Light() {
        // GIVEN && WHEN
        sut = CallParticipantsListViewController(
            participants: mockParticipants,
            showParticipants: false,
            selfUser: selfUser
        )
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.backgroundColor = .white

        // THEN
        snapshotHelper.verify(matching: sut.view)
    }

    func testCallParticipants_Truncated_Dark() {
        // GIVEN && WHEN
        sut = CallParticipantsListViewController(
            participants: mockParticipants,
            showParticipants: false,
            selfUser: selfUser
        )
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.backgroundColor = .black
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        snapshotHelper.verify(matching: sut.view)
    }

    func testCallParticipants_ConnectingState_Light() {
        // GIVEN && WHEN
        let participants = CallParticipantsListHelper.participants(count: 3, mockUsers: SwiftMockLoader.mockUsers())
        sut = CallParticipantsListViewController(
            participants: participants,
            showParticipants: true,
            selfUser: selfUser
        )
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.backgroundColor = .white

        // THEN
        snapshotHelper.verify(matching: sut.view)
    }

    func testCallParticipants_ConnectingState_Dark() {
        // GIVEN && WHEN
        let participants = CallParticipantsListHelper.participants(count: 3, mockUsers: SwiftMockLoader.mockUsers())
        sut = CallParticipantsListViewController(
            participants: participants,
            showParticipants: true,
            selfUser: selfUser
        )
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.backgroundColor = .black
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        snapshotHelper.verify(matching: sut.view)
    }
}
