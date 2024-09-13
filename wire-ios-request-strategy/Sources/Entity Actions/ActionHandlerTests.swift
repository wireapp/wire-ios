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

import XCTest
@testable import WireRequestStrategy

private class MockAction: EntityAction, Equatable {
    let uuid = UUID()
    var resultHandler: ResultHandler?

    typealias Result = Void
    typealias Failure = Error

    static func == (lhs: MockAction, rhs: MockAction) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

private class TestActionHandler: ActionHandler<MockAction> {
    var calledRequestForAction = false
    override func request(for action: ActionHandler<MockAction>.Action, apiVersion: APIVersion) -> ZMTransportRequest? {
        calledRequestForAction = true
        return ZMTransportRequest(getFromPath: "/mock/request", apiVersion: APIVersion.v0.rawValue)
    }

    var calledHandleResponse = false
    override func handleResponse(_ response: ZMTransportResponse, action: ActionHandler<MockAction>.Action) {
        calledHandleResponse = true
    }
}

class ActionHandlerTests: MessagingTestBase {
    private var sut: TestActionHandler!

    override func setUp() {
        super.setUp()
        sut = TestActionHandler(context: uiMOC)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItCallsRequestForAction_WhenActionHasBeenSent() throws {
        // given
        let action = MockAction()
        action.send(in: uiMOC.notificationContext)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        _ = sut.nextRequest(for: .v0)

        // then
        XCTAssertTrue(sut.calledRequestForAction)
    }

    func testThatItDoesntCallRequestForAction_WhenActionHasAlreadyBeenConsumed() throws {
        // given
        let action = MockAction()
        action.send(in: uiMOC.notificationContext)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        _ = sut.nextRequest(for: .v0)
        XCTAssertTrue(sut.pendingActions.isEmpty)
        sut.calledRequestForAction = false

        // when
        _ = sut.nextRequest(for: .v0)

        // then
        XCTAssertFalse(sut.calledRequestForAction)
    }

    func testThatItHandleRequestForAction_WhenResponseArrives() throws {
        // given
        let action = MockAction()
        action.send(in: uiMOC.notificationContext)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let request = try XCTUnwrap(sut.nextRequest(for: .v0))

        // when
        request.complete(with: response(httpStatus: 200, apiVersion: .v0))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.calledHandleResponse)
    }

    func testItReturnsActionToPendingIfRateLimited_420Response() throws {
        // given
        let action = MockAction()
        action.send(in: uiMOC.notificationContext)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let request = try XCTUnwrap(sut.nextRequest(for: .v0))
        XCTAssertTrue(sut.pendingActions.isEmpty)

        // when
        request.complete(with: response(httpStatus: 420, apiVersion: .v0))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.pendingActions, [action])
        XCTAssertFalse(sut.calledHandleResponse)
    }

    func testItReturnsActionToPendingIfRateLimited_429Response() throws {
        // given
        let action = MockAction()
        action.send(in: uiMOC.notificationContext)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let request = try XCTUnwrap(sut.nextRequest(for: .v0))
        XCTAssertTrue(sut.pendingActions.isEmpty)

        // when
        request.complete(with: response(httpStatus: 429, apiVersion: .v0))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.pendingActions, [action])
        XCTAssertFalse(sut.calledHandleResponse)
    }

    private func response(httpStatus: Int, apiVersion: APIVersion) -> ZMTransportResponse {
        ZMTransportResponse(
            payload: nil,
            httpStatus: httpStatus,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )
    }
}
