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

final class ConnectRequestsViewModelTests: XCTestCase {

    func testRowsAreMappedNewestFirst() throws {
        let oldestUser = MockUserType.createConnectedUser(name: "Oldest")
        let newestUser = MockUserType.createConnectedUser(name: "Newest")
        let viewModel = ConnectRequestsViewModel(
            connectionRequests: [
                conversation(connectedUser: oldestUser),
                conversation(connectedUser: newestUser)
            ]
        )

        let firstRow = try XCTUnwrap(viewModel.row(at: IndexPath(row: 0, section: 0)))
        let secondRow = try XCTUnwrap(viewModel.row(at: IndexPath(row: 1, section: 0)))

        XCTAssertEqual(firstRow.user.name, "Newest")
        XCTAssertEqual(secondRow.user.name, "Oldest")
    }

    func testRowsReturnNilWhenRequestHasNoUser() {
        let viewModel = ConnectRequestsViewModel(connectionRequests: [conversation(connectedUser: nil)])

        XCTAssertNil(viewModel.row(at: IndexPath(row: 0, section: 0)))
    }

    func testRowHeightUsesAllAvailableHeightForSingleRequest() {
        let viewModel = ConnectRequestsViewModel(
            connectionRequests: [conversation(connectedUser: MockUserType.createConnectedUser(name: "Alice"))]
        )

        XCTAssertEqual(viewModel.rowHeight(forAvailableHeight: 500), 500)
    }

    func testRowHeightLeavesHintForAdditionalRequests() {
        let viewModel = ConnectRequestsViewModel(
            connectionRequests: [
                conversation(connectedUser: MockUserType.createConnectedUser(name: "Alice")),
                conversation(connectedUser: MockUserType.createConnectedUser(name: "Bob"))
            ]
        )

        XCTAssertEqual(viewModel.rowHeight(forAvailableHeight: 500), 452)
    }

    func testRowHeightDoesNotGoBelowZero() {
        let viewModel = ConnectRequestsViewModel(
            connectionRequests: [
                conversation(connectedUser: MockUserType.createConnectedUser(name: "Alice")),
                conversation(connectedUser: MockUserType.createConnectedUser(name: "Bob"))
            ]
        )

        XCTAssertEqual(viewModel.rowHeight(forAvailableHeight: 24), 0)
    }

    func testRoutesAfterReloadShowsNextRequestWhenRequestsRemain() throws {
        let viewModel = ConnectRequestsViewModel(
            connectionRequests: [
                conversation(connectedUser: MockUserType.createConnectedUser(name: "Oldest")),
                conversation(connectedUser: MockUserType.createConnectedUser(name: "Newest"))
            ]
        )

        let route = try XCTUnwrap(viewModel.routesAfterReloadIfIdle().first)

        guard case let .showNextRequest(indexPath) = route else {
            return XCTFail("Expected showNextRequest route")
        }

        XCTAssertEqual(indexPath, IndexPath(row: 1, section: 0))
    }

    func testRoutesAfterReloadHidesWhenNoRequestsRemain() throws {
        let viewModel = ConnectRequestsViewModel()

        let route = try XCTUnwrap(viewModel.routesAfterReloadIfIdle().first)

        guard case .hideRequests = route else {
            return XCTFail("Expected hideRequests route")
        }
    }

    func testIgnoreCompletesWithCurrentRequestRoute() throws {
        let user = CompletingMockUserType()
        let viewModel = ConnectRequestsViewModel(connectionRequests: [conversation(connectedUser: user)])
        var completedRoutes = [ConnectRequestsViewModel.Route]()

        viewModel.ignore(user: user) { routes in
            completedRoutes = routes
        }

        XCTAssertFalse(viewModel.isIgnoring)

        let route = try XCTUnwrap(completedRoutes.first)
        guard case let .showNextRequest(indexPath) = route else {
            return XCTFail("Expected showNextRequest route")
        }

        XCTAssertEqual(indexPath, IndexPath(row: 0, section: 0))
    }

    func testAcceptCompletesWithHideRouteWhenRequestsAreGone() throws {
        let user = CompletingMockUserType()
        let viewModel = ConnectRequestsViewModel()
        var completedRoutes = [ConnectRequestsViewModel.Route]()

        viewModel.accept(user: user) { routes in
            completedRoutes = routes
        }

        XCTAssertFalse(viewModel.isAccepting)

        let route = try XCTUnwrap(completedRoutes.first)
        guard case .hideRequests = route else {
            return XCTFail("Expected hideRequests route")
        }
    }

    private func conversation(connectedUser: UserType?) -> SwiftMockConversation {
        let conversation = SwiftMockConversation()
        conversation.connectedUserType = connectedUser
        return conversation
    }
}

private final class CompletingMockUserType: MockUserType {

    override func accept(completion: @escaping (Error?) -> Void) {
        completion(nil)
    }

    override func ignore(completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
}
