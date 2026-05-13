//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

final class SearchUserViewModelTests: XCTestCase {

    func testActionShowsDirectoryUserProfileWhenDirectoryUserExists() {
        let viewer = MockUserType.createSelfUser(name: "Viewer")
        let directoryUser = MockUserType.createUser(name: "Alice")
        let teamMember = MockUserType.createUser(name: "Bob")
        var viewModel = SearchUserViewModel()

        let action = viewModel.action(
            for: SearchUserViewModel.LookupResult(
                directoryUsers: [directoryUser],
                teamMemberUsers: [teamMember]
            ),
            viewer: viewer
        )

        guard case let .showProfile(route) = action else {
            return XCTFail("Expected showProfile action")
        }

        XCTAssertTrue((route.user as? MockUserType) === directoryUser)
        XCTAssertTrue((route.viewer as? MockUserType) === viewer)
    }

    func testActionFallsBackToTeamMemberWhenDirectoryUserIsDeleted() {
        let viewer = MockUserType.createSelfUser(name: "Viewer")
        let deletedDirectoryUser = MockUserType.createUser(name: "Alice")
        deletedDirectoryUser.isAccountDeleted = true
        let teamMember = MockUserType.createUser(name: "Bob")
        var viewModel = SearchUserViewModel()

        let action = viewModel.action(
            for: SearchUserViewModel.LookupResult(
                directoryUsers: [deletedDirectoryUser],
                teamMemberUsers: [teamMember]
            ),
            viewer: viewer
        )

        guard case let .showProfile(route) = action else {
            return XCTFail("Expected showProfile action")
        }

        XCTAssertTrue((route.user as? MockUserType) === teamMember)
    }

    func testActionShowsInvalidUserWhenNoDisplayableUserExists() {
        let viewer = MockUserType.createSelfUser(name: "Viewer")
        let deletedDirectoryUser = MockUserType.createUser(name: "Alice")
        deletedDirectoryUser.isAccountDeleted = true
        var viewModel = SearchUserViewModel()

        let action = viewModel.action(
            for: SearchUserViewModel.LookupResult(
                directoryUsers: [deletedDirectoryUser],
                teamMemberUsers: []
            ),
            viewer: viewer
        )

        guard case let .showInvalidUser(alertContent) = action else {
            return XCTFail("Expected showInvalidUser action")
        }

        XCTAssertEqual(alertContent.title, L10n.Localizable.UrlAction.InvalidUser.title)
        XCTAssertEqual(alertContent.message, L10n.Localizable.UrlAction.InvalidUser.message)
        XCTAssertEqual(alertContent.buttonTitle, L10n.Localizable.General.ok)
    }

    func testActionAssertsMissingSelfUserWhenViewerIsMissing() {
        let directoryUser = MockUserType.createUser(name: "Alice")
        var viewModel = SearchUserViewModel()

        let action = viewModel.action(
            for: SearchUserViewModel.LookupResult(
                directoryUsers: [directoryUser],
                teamMemberUsers: []
            ),
            viewer: nil
        )

        guard case let .assertMissingSelfUser(message) = action else {
            return XCTFail("Expected assertMissingSelfUser action")
        }

        XCTAssertEqual(message, "ZMUser.selfUser() is nil")
    }

    func testActionIgnoresResultAfterProfileHasBeenShown() {
        let viewer = MockUserType.createSelfUser(name: "Viewer")
        let firstUser = MockUserType.createUser(name: "Alice")
        let secondUser = MockUserType.createUser(name: "Bob")
        var viewModel = SearchUserViewModel()

        _ = viewModel.action(
            for: SearchUserViewModel.LookupResult(
                directoryUsers: [firstUser],
                teamMemberUsers: []
            ),
            viewer: viewer
        )

        let action = viewModel.action(
            for: SearchUserViewModel.LookupResult(
                directoryUsers: [secondUser],
                teamMemberUsers: []
            ),
            viewer: viewer
        )

        guard case .ignore = action else {
            return XCTFail("Expected ignore action")
        }
    }
}
