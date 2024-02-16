//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import SnapshotTesting
@testable import Wire

final class LegalHoldDetailsViewControllerSnapshotTests: BaseSnapshotTestCase {

    // MARK: - Properties

    var sut: LegalHoldDetailsViewController!
    var selfUser: MockUserType!
    var userSession: UserSessionMock!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        userSession = UserSessionMock()
        SelfUser.setupMockSelfUser(inTeam: UUID())
        selfUser = SelfUser.provider?.providedSelfUser as? MockUserType
        selfUser.handle = nil
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        SelfUser.provider = nil
        userSession = nil
        super.tearDown()
    }

    // MARK: - Helper method

    func setUpLegalHoldDetailsViewController(conversation: MockGroupDetailsConversation) -> () -> UIViewController {

        let createSut: () -> UIViewController = {
            self.sut = LegalHoldDetailsViewController(conversation: conversation, userSession: self.userSession)
            return self.sut.wrapInNavigationController()
        }

        return createSut
    }

    // MARK: - Snapshot Tests

    func testSelfUserUnderLegalHold() {
        // GIVEN
        let conversation = MockGroupDetailsConversation()
        selfUser.isUnderLegalHold = true
        conversation.sortedActiveParticipantsUserTypes = [selfUser]

        // WHEN
        let sut =  setUpLegalHoldDetailsViewController(conversation: conversation)

        // THEN
        verifyInAllColorSchemes(createSut: sut)
    }

    func testOtherUserUnderLegalHold() {
        // GIVEN
        let conversation = MockGroupDetailsConversation()
        let otherUser = SwiftMockLoader.mockUsers().first!
        otherUser.isUnderLegalHold = true
        conversation.sortedActiveParticipantsUserTypes = [otherUser]

        let createSut: () -> UIViewController = {
            self.sut = LegalHoldDetailsViewController(conversation: conversation, userSession: self.userSession)
            return self.sut.wrapInNavigationController()
        }

        // THEN
        verifyInAllColorSchemes(createSut: createSut)
    }

}
