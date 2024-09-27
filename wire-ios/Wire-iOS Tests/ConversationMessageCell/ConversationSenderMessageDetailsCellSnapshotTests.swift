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

import WireDesign
import WireTestingPackage
import XCTest
@testable import Wire

final class ConversationSenderMessageDetailsCellSnapshotTests: XCTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        mockUser = MockUserType.createUser(name: "Bruno", inTeam: teamID)
        mockUser.isConnected = true
        sut = ConversationSenderMessageDetailsCell()

        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.widthAnchor.constraint(equalToConstant: 320).isActive = true

        sut.backgroundColor = SemanticColors.View.backgroundConversationView
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        mockUser = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func test_SenderIsExternal_InConversation() {
        // GIVEN
        mockUser.teamRole = .partner
        let configuration = ConversationSenderMessageDetailsCell.Configuration(
            user: mockUser,
            indicator: .none,
            teamRoleIndicator: .externalPartner,
            timestamp: "1/1/70, 1:00 AM"
        )

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func test_SenderIsFederated_InConversation() {
        // GIVEN
        mockUser.isFederated = true
        let configuration = ConversationSenderMessageDetailsCell.Configuration(
            user: mockUser,
            indicator: .none,
            teamRoleIndicator: .federated,
            timestamp: "1/1/70, 1:00 AM"
        )

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func test_SenderIsGuest_InConversation() {
        // GIVEN
        mockUser.isGuestInConversation = true
        let configuration = ConversationSenderMessageDetailsCell.Configuration(
            user: mockUser,
            indicator: .none,
            teamRoleIndicator: .guest,
            timestamp: "1/1/70, 1:00 AM"
        )

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func test_SenderIsBot_InConversation() {
        // GIVEN
        mockUser.mockedIsServiceUser = true
        let configuration = ConversationSenderMessageDetailsCell.Configuration(
            user: mockUser,
            indicator: .none,
            teamRoleIndicator: .service,
            timestamp: "1/1/70, 1:00 AM"
        )

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func test_SenderIsTeamMember_InConversation() {
        // GIVEN
        mockUser.teamRole = .member
        let configuration = ConversationSenderMessageDetailsCell.Configuration(
            user: mockUser,
            indicator: .none,
            teamRoleIndicator: .none,
            timestamp: "1/1/70, 1:00 AM"
        )

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func test_MessageHasBeenDeleted() {
        mockUser.teamRole = .member
        let configuration = ConversationSenderMessageDetailsCell.Configuration(
            user: mockUser,
            indicator: .deleted,
            teamRoleIndicator: .none,
            timestamp: "1/1/70, 1:00 AM"
        )

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func test_MessageHasBeenEdited() {
        mockUser.teamRole = .member
        let configuration = ConversationSenderMessageDetailsCell.Configuration(
            user: mockUser,
            indicator: .edited,
            teamRoleIndicator: .none,
            timestamp: "1/1/70, 1:00 AM"
        )

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func test_SenderIsGuestWithALongName_AndMessageHasBeenEdited() {
        // GIVEN
        mockUser = MockUserType.createUser(
            name: "Bruno with a really really really really really really really really really really long name",
            inTeam: teamID
        )
        mockUser.isGuestInConversation = true
        let configuration = ConversationSenderMessageDetailsCell.Configuration(
            user: mockUser,
            indicator: .edited,
            teamRoleIndicator: .guest,
            timestamp: "1/1/70, 1:00 AM"
        )

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func test_SenderIsGuestWithALongName_AndMessageHasBeenDeleted() {
        // GIVEN
        mockUser = MockUserType.createUser(
            name: "Bruno with a really really really really really really really really really really long name",
            inTeam: teamID
        )
        mockUser.isGuestInConversation = true
        let configuration = ConversationSenderMessageDetailsCell.Configuration(
            user: mockUser,
            indicator: .deleted,
            teamRoleIndicator: .guest,
            timestamp: "1/1/70, 1:00 AM"
        )

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func test_SenderIsWithoutMetadata_GroupConversation() {
        // GIVEN
        mockUser.name = nil
        mockUser.teamRole = .member
        let configuration = ConversationSenderMessageDetailsCell.Configuration(
            user: mockUser,
            indicator: .none,
            teamRoleIndicator: .none,
            timestamp: "1/1/70, 1:00 AM"
        )

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: Private

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: ConversationSenderMessageDetailsCell!
    private var teamID = UUID()
    private var mockUser: MockUserType!
}
