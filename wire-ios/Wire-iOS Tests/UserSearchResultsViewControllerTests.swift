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

final class UserSearchResultsViewControllerTests: XCTestCase {
    // MARK: - Properties

    private var sut: UserSearchResultsViewController!
    private var serviceUser: MockServiceUserType!
    private var selfUser: MockUserType!
    private var otherUser: MockUserType!
    private var snapshotHelper: SnapshotHelper!

    // MARK: setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        // self user should be a team member and other participants should be guests, in order to show guest icon in the
        // user cells
        SelfUser.setupMockSelfUser(inTeam: UUID())
        selfUser = SelfUser.provider?.providedSelfUser as? MockUserType
        otherUser = MockUserType.createDefaultOtherUser()

        serviceUser = MockServiceUserType.createServiceUser(name: "ServiceUser")

        XCTAssert(selfUser.isTeamMember, "selfUser should be a team member to generate snapshots with guest icon")
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        selfUser = nil
        otherUser = nil
        serviceUser = nil
        super.tearDown()
    }

    // MARK: - Helper methods

    func createSUT() {
        sut = UserSearchResultsViewController(nibName: nil, bundle: nil)
        sut.view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    func mockSearchResultUsers(file: StaticString = #file, line: UInt = #line) -> [UserType] {
        var allUsers: [UserType] = []

        for name in MockUserType.usernames {
            let user = MockUserType.createUser(name: name)
            user.zmAccentColor = .amber
            XCTAssertFalse(
                user.isTeamMember,
                "user should not be a team member to generate snapshots with guest icon",
                file: file,
                line: line
            )
            allUsers.append(user)
        }

        allUsers.append(selfUser)

        return allUsers.searchForMentions(withQuery: "")
    }

    // MARK: - Snapshot Tests

    func testThatShowsResultsInConversationWithQuery() {
        let createSut: () -> UIViewController = {
            self.createSUT()
            self.sut.users = [self.selfUser, self.otherUser].searchForMentions(withQuery: "u")
            return self.sut
        }

        let sut = createSut()

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

    func testThatItOverflowsWithTooManyUsers() {
        createSUT()
        sut.users = mockSearchResultUsers()

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

    func testThatHighlightedTopMostItemUpdatesAfterSelectedTopMostUser() {
        createSUT()

        sut.users = mockSearchResultUsers()

        let numberOfUsers = MockUserType.usernames.count

        for _ in 0 ..< numberOfUsers {
            sut.selectPreviousUser()
        }

        snapshotHelper.verify(matching: sut)
    }

    func testThatHighlightedItemStaysAtMiddleAfterSelectedAnUserAtTheMiddle() {
        createSUT()

        sut.users = mockSearchResultUsers()

        let numberOfUsers = MockUserType.usernames.count

        // go to top most
        for _ in 0 ..< numberOfUsers + 5 {
            sut.selectPreviousUser()
        }

        // go to bottom most
        for _ in 0 ..< numberOfUsers + 5 {
            sut.selectNextUser()
        }

        // go to middle
        for _ in 0 ..< numberOfUsers / 2 {
            sut.selectPreviousUser()
        }

        snapshotHelper.verify(matching: sut)
    }

    func testThatLowestItemIsNotHighlightedIfKeyboardIsNotCollapsed() {
        createSUT()
        sut.users = mockSearchResultUsers()

        // Post a mock show keyboard notification
        NotificationCenter.default.post(name: UIResponder.keyboardWillShowNotification, object: nil, userInfo: [
            UIResponder.keyboardFrameBeginUserInfoKey: CGRect(x: 0, y: 0, width: 0, height: 0),
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 0, height: 100),
            UIResponder.keyboardAnimationDurationUserInfoKey: TimeInterval(0.0),
        ])

        snapshotHelper.verify(matching: sut)
    }

    func testThatItDoesNotCrashWithNoResults() {
        createSUT()
        // given
        let users: [UserType] = [selfUser, otherUser, serviceUser]
        sut.users = users.searchForMentions(withQuery: "u")

        // when
        sut.users = users.searchForMentions(withQuery: "362D00AE-B606-4680-BD47-F17749229E64")
    }
}
