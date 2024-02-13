//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireUtilities
@testable import Wire

final class UserCellTests: BaseSnapshotTestCase {

    // MARK: - Properties

    var sut: UserCell!
    var teamID = UUID()
    var conversation: MockGroupDetailsConversation!
    var mockUser: MockUserType!

    // MARK: - setUp

    override func setUp() {
        super.setUp()

        SelfUser.setupMockSelfUser(inTeam: teamID)

        mockUser = MockUserType.createUser(name: "James Hetfield", inTeam: teamID)
        mockUser.handle = "james_hetfield_1"

        conversation = MockGroupDetailsConversation()
    }

    // MARK: - tearDown

    override func tearDown() {
        conversation = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper method

    private func verify(
        mockUser: UserType,
        conversation: GroupDetailsConversationType,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        guard let user = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        sut = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        sut.configure(
            user: mockUser,
            isSelfUserPartOfATeam: user.hasTeam,
            conversation: conversation
        )
        sut.accessoryIconView.isHidden = false

        verifyInAllColorSchemes(matching: sut, file: file, testName: testName, line: line)
    }

    // MARK: - Snapshot Tests

    func testExternalUser() {
        // GIVEN && WHEN
        mockUser.teamRole = .partner

        // THEN
        verify(mockUser: mockUser, conversation: conversation)
    }

    func testServiceUser() {
        // GIVEN && WHEN
        mockUser.mockedIsServiceUser = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation)
    }

    func testNonTeamUser() {
        // GIVEN && WHEN
        mockUser.teamIdentifier = nil
        mockUser.isConnected = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation)
    }

    func testTrustedNonTeamUser() {
        // GIVEN && WHEN
        mockUser.isVerified = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation)
    }

    func testFederatedUser() {
        // GIVEN && WHEN
        mockUser.isFederated = true
        mockUser.domain = "foo.com"

        // THEN
        verify(mockUser: mockUser, conversation: conversation)
    }

    func testGuestUser() {
        // GIVEN && WHEN
        mockUser.isGuestInConversation = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation)
    }

    func testGuestUser_Wireless() {
        // GIVEN && WHEN
        mockUser.isGuestInConversation = true
        mockUser.expiresAfter = 5_200
        mockUser.handle = nil

        // THEN
        verify(mockUser: mockUser, conversation: conversation)
    }

    func testTrustedGuestUser() {
        // GIVEN && WHEN
        mockUser.isVerified = true
        mockUser.isGuestInConversation = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation)
    }

    func testNonTeamUserWithoutHandle() {
        // GIVEN && WHEN
        mockUser = MockUserType.createUser(name: "Tarja Turunen")
        mockUser.accentColorValue = .vividRed
        mockUser.isConnected = true
        mockUser.handle = nil

        // THEN
        verify(mockUser: mockUser, conversation: conversation)
    }

    func testUserInsideOngoingVideoCall() {
        guard let user = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        let callParticipantState: CallParticipantState = .connected(videoState: .started, microphoneState: .unmuted)
        let config = CallParticipantsListCellConfiguration.callParticipant(user: HashBox(value: mockUser), callParticipantState: callParticipantState, activeSpeakerState: .inactive)
        sut = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        sut.configure(with: config, selfUser: user)
        sut.overrideUserInterfaceStyle = .dark

        // THEN
        verifyInAllColorSchemes(matching: sut)
    }

    func testUserScreenSharingInsideOngoingVideoCall() {
        guard let user = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        let callParticipantState: CallParticipantState = .connected(videoState: .screenSharing, microphoneState: .unmuted)
        let config = CallParticipantsListCellConfiguration.callParticipant(user: HashBox(value: mockUser), callParticipantState: callParticipantState, activeSpeakerState: .inactive)
        sut = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        sut.configure(with: config, selfUser: user)
        sut.overrideUserInterfaceStyle = .dark
        verifyInAllColorSchemes(matching: sut)
    }

    // MARK: unit test

    func testThatAccessIDIsGenerated() {
        // GIVEN
        let user = SwiftMockLoader.mockUsers().map(ParticipantsRowType.init)[0]
        let cell = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        cell.sectionName = "Members"
        cell.cellIdentifier = "participants.section.participants.cell"

        // WHEN
        cell.configure(with: user, conversation: conversation, showSeparator: true)

        // THEN
        XCTAssertEqual(cell.accessibilityIdentifier, "Members - participants.section.participants.cell")
    }

}
