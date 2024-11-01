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
import WireTestingPackage
import WireUtilities
import XCTest

final class UserCellTests: XCTestCase {

    // MARK: - Properties

    private var sut: UserCell!
    private var teamID = UUID()
    private var conversation: MockGroupDetailsConversation!
    private var mockUser: MockUserType!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        SelfUser.setupMockSelfUser(inTeam: teamID)

        mockUser = MockUserType.createUser(name: "James Hetfield", inTeam: teamID)
        mockUser.handle = "james_hetfield_1"

        conversation = MockGroupDetailsConversation()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        conversation = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper method

    private func verify(
        mockUser: UserType,
        conversation: GroupDetailsConversationType,
        isE2EICertified: Bool,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        guard let selfUser = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        sut = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        sut.configure(
            userStatus: .init(user: mockUser, isE2EICertified: isE2EICertified),
            user: mockUser,
            userIsSelfUser: mockUser.isSelfUser,
            isSelfUserPartOfATeam: selfUser.hasTeam,
            conversation: conversation
        )
        sut.accessoryIconView.isHidden = false

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: file,
                testName: testName,
                line: line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: file,
                testName: testName,
                line: line
            )
    }

    // MARK: - Snapshot Tests

    func testExternalUser() {
        // GIVEN && WHEN
        mockUser.teamRole = .partner

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: false)
    }

    func testServiceUser() {
        // GIVEN && WHEN
        mockUser.mockedIsServiceUser = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: false)
    }

    func testNonTeamUser() {
        // GIVEN && WHEN
        mockUser.teamIdentifier = nil
        mockUser.isConnected = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: false)
    }

    func testTrustedNonTeamUser() {
        // GIVEN && WHEN
        mockUser.isVerified = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: false)
    }

    func testCertifiedNonTeamUser() {
        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: true)
    }

    func testTrustedAndCertifiedNonTeamUser() {
        // GIVEN && WHEN
        mockUser.isVerified = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: true)
    }

    func testFederatedUser() {
        // GIVEN && WHEN
        mockUser.isFederated = true
        mockUser.domain = "foo.com"

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: false)
    }

    func testGuestUser() {
        // GIVEN && WHEN
        mockUser.isGuestInConversation = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: false)
    }

    func testGuestUser_Wireless() {
        // GIVEN && WHEN
        mockUser.isGuestInConversation = true
        mockUser.expiresAfter = 5_200
        mockUser.handle = nil

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: false)
    }

    func testTrustedGuestUser() {
        // GIVEN && WHEN
        mockUser.isVerified = true
        mockUser.isGuestInConversation = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: false)
    }

    func testCertifiedGuestUser() {
        // GIVEN && WHEN
        mockUser.isGuestInConversation = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: true)
    }

    func testTrustedAndCertifiedGuestUser() {
        // GIVEN && WHEN
        mockUser.isVerified = true
        mockUser.isGuestInConversation = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: true)
    }

    func testSelfUser() throws {
        // GIVEN && WHEN
        mockUser = MockUserType.createUser(name: "Tarja Turunen")
        mockUser.zmAccentColor = .red
        mockUser.isConnected = true
        mockUser.handle = "tarja_turunen"
        mockUser.availability = .busy
        mockUser.isSelfUser = true

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: true)
    }

    func testNonTeamUserWithoutHandle() {
        // GIVEN && WHEN
        mockUser = MockUserType.createUser(name: "Tarja Turunen")
        mockUser.zmAccentColor = .red
        mockUser.isConnected = true
        mockUser.handle = nil

        // THEN
        verify(mockUser: mockUser, conversation: conversation, isE2EICertified: false)
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

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #file,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #file,
                testName: #function,
                line: #line
            )
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

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #file,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #file,
                testName: #function,
                line: #line
            )
    }

    // MARK: unit test

    func testThatAccessIDIsGenerated() {
        // GIVEN
        let user = SwiftMockLoader.mockUsers()[0]
        let cell = UserCell(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        cell.sectionName = "Members"
        cell.cellIdentifier = "participants.section.participants.cell"

        // WHEN
        cell.configure(
            user: user,
            isE2EICertified: false,
            conversation: conversation,
            showSeparator: true
        )

        // THEN
        XCTAssertEqual(cell.accessibilityIdentifier, "Members - participants.section.participants.cell")
    }
}
