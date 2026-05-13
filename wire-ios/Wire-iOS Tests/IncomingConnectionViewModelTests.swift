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

final class IncomingConnectionViewModelTests: XCTestCase {

    func testStateIsIncomingForUnconnectedUser() {
        let user = MockUserType.createUser(name: "Alice")
        let viewModel = IncomingConnectionViewModel(userSession: UserSessionMock(), user: user)

        XCTAssertEqual(viewModel.state, .incoming)
    }

    func testStateIsAlreadyConnectedForConnectedUser() {
        let user = MockUserType.createConnectedUser(name: "Alice")
        let viewModel = IncomingConnectionViewModel(userSession: UserSessionMock(), user: user)

        XCTAssertEqual(viewModel.state, .alreadyConnected)
    }

    func testRefreshDataIfNeededRefreshesIncomingUser() {
        let user = MockUserType.createUser(name: "Alice")
        let viewModel = IncomingConnectionViewModel(userSession: UserSessionMock(), user: user)

        viewModel.refreshDataIfNeeded()

        XCTAssertEqual(user.refreshDataCount, 1)
    }

    func testRefreshDataIfNeededDoesNotRefreshConnectedUser() {
        let user = MockUserType.createConnectedUser(name: "Alice")
        let viewModel = IncomingConnectionViewModel(userSession: UserSessionMock(), user: user)

        viewModel.refreshDataIfNeeded()

        XCTAssertEqual(user.refreshDataCount, 0)
    }

    func testActionsAreMappedFromViewEvents() {
        let user = MockUserType.createUser(name: "Alice")
        let viewModel = IncomingConnectionViewModel(userSession: UserSessionMock(), user: user)

        XCTAssertEqual(viewModel.action(for: .acceptTapped), .accept)
        XCTAssertEqual(viewModel.action(for: .ignoreTapped), .ignore)
    }

    func testDisplayStateKeepsViewInputs() {
        let user = MockUserType.createUser(name: "Alice")
        let userSession = UserSessionMock()
        userSession.localDomain = "example.com"
        let viewModel = IncomingConnectionViewModel(userSession: userSession, user: user)

        let displayState = viewModel.displayState

        XCTAssertEqual(displayState.user.name, user.name)
        XCTAssertEqual((displayState.userSession as? UserSessionMock)?.localDomain, "example.com")
    }
}
