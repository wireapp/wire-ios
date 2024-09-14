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
import XCTest

@testable import Wire

final class MockTeam: TeamType {
    var conversations: Set<ZMConversation> = []

    var name: String?

    var pictureAssetId: String?

    var pictureAssetKey: String?

    var remoteIdentifier: UUID?

    var imageData: Data?

    func requestImage() {
        // no-op
    }

    func refreshMetadata() {
        // no-op
    }
}

final class AddParticipantsViewControllerSnapshotTests: XCTestCase {

    // MARK: - Properties

    var userSession: UserSessionMock!
    var mockSelfUser: MockUserType!
    var sut: AddParticipantsViewController!
    var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        SelfUser.setupMockSelfUser(inTeam: UUID())
        mockSelfUser = SelfUser.provider?.providedSelfUser as? MockUserType
        userSession = UserSessionMock(mockUser: mockSelfUser)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        userSession = nil
        mockSelfUser = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForEveryOneIsHere() {
        let newValues = ConversationCreationValues(
            name: "",
            participants: [],
            allowGuests: true,
            encryptionProtocol: .proteus,
            selfUser: mockSelfUser
        )

        sut = AddParticipantsViewController(context: .create(newValues), userSession: userSession)
        snapshotHelper.verify(matching: sut)
    }

    func testForAddParticipantsButtonIsShown() {
        let conversation = MockGroupDetailsConversation()
        sut = AddParticipantsViewController(context: .add(conversation), userSession: userSession)
        let user = MockUserType.createUser(name: "Bill")
        sut.userSelection.add(user)
        sut.userSelection(UserSelection(), didAddUser: user)

        snapshotHelper.verify(matching: sut)
    }

    func testThatTabBarIsShown_WhenBotCanBeAdded() {
        // GIVEN
        let mockConversation = MockGroupDetailsConversation()

        // WHEN
        mockConversation.conversationType = .group
        mockConversation.teamType = MockTeam()
        mockConversation.allowServices = true

        sut = AddParticipantsViewController(context: .add(mockConversation), userSession: userSession)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

}
