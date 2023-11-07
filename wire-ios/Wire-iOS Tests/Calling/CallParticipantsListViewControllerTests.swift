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

import Foundation
import SnapshotTesting
import XCTest
import WireUtilities
@testable import Wire

final class CallParticipantsListHelper {
    static func participants(count participantCount: Int,
                             videoState: VideoState? = nil,
                             microphoneState: MicrophoneState? = nil,
                             mockUsers: [UserType]) -> CallParticipantsList {
        let sortedParticipants = (0..<participantCount)
            .lazy
            .map { mockUsers[$0] }
            .sorted { $0.name < $1.name }
        var callParticipantState: CallParticipantState = .connecting
        if let videoState = videoState, let microphoneState = microphoneState {
            callParticipantState = .connected(videoState: videoState, microphoneState: microphoneState)
        }

        return sortedParticipants.map { CallParticipantsListCellConfiguration.callParticipant(user: HashBox(value: $0),
                                                                                              callParticipantState: callParticipantState,
                                                                                              activeSpeakerState: .inactive)
        }
    }

}

final class CallParticipantsListViewControllerTests: ZMSnapshotTestCase {

    var sut: CallParticipantsListViewController!
    var mockParticipants: CallParticipantsList!
    var selfUser: UserType!

    override func setUp() {
        super.setUp()
        mockParticipants = CallParticipantsListHelper.participants(count: 10, videoState: .stopped, microphoneState: .muted, mockUsers: SwiftMockLoader.mockUsers())
        selfUser = ZMUser.selfUser()
        guard selfUser != nil else {
            XCTFail("ZMUser.selfUser() is nil")
            return
        }
    }

    override func tearDown() {
        selfUser = nil
        mockParticipants = nil
        sut = nil
        super.tearDown()
    }

    func testCallParticipants_Overflowing_Light() {
        // Given
        guard let selfUser = ZMUser.selfUser() else { return XCTFail("ZMUser.selfUser() is nil") }

        // When
        sut = CallParticipantsListViewController(
            participants: mockParticipants,
            showParticipants: true,
            selfUser: selfUser
        )
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.setNeedsLayout()
        sut.view.layoutIfNeeded()
        sut.view.backgroundColor = .white

        // Then
        verify(matching: sut.view)
    }

    func testCallParticipants_Overflowing_Dark() {
        // When
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

        // Then
        verify(matching: sut.view)
    }

    func testCallParticipants_Truncated_Light() {
        // When
        sut = CallParticipantsListViewController(
            participants: mockParticipants,
            showParticipants: false,
            selfUser: selfUser
        )
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.backgroundColor = .white

        // Then
        verify(matching: sut.view)
    }

    func testCallParticipants_Truncated_Dark() {
        // When
        sut = CallParticipantsListViewController(
            participants: mockParticipants,
            showParticipants: false,
            selfUser: selfUser
        )
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.backgroundColor = .black
        sut.overrideUserInterfaceStyle = .dark

        // Then
        verify(matching: sut.view)
    }

    func testCallParticipants_ConnectingState_Light() {
        // When
        let participants = CallParticipantsListHelper.participants(count: 3, mockUsers: SwiftMockLoader.mockUsers())
        sut = CallParticipantsListViewController(
            participants: participants,
            showParticipants: true,
            selfUser: selfUser
        )
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.backgroundColor = .white

        // Then
        verify(matching: sut.view)
    }

    func testCallParticipants_ConnectingState_Dark() {
        // When
        let participants = CallParticipantsListHelper.participants(count: 3, mockUsers: SwiftMockLoader.mockUsers())
        sut = CallParticipantsListViewController(
            participants: participants,
            showParticipants: true,
            selfUser: selfUser
        )
        sut.view.frame = CGRect(x: 0, y: 0, width: 325, height: 336)
        sut.view.backgroundColor = .black
        sut.overrideUserInterfaceStyle = .dark

        // Then
        verify(matching: sut.view)
    }
}
