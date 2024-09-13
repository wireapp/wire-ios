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

import Foundation
import WireMockTransport
@testable import WireSyncEngine

class UserHandleTests: IntegrationTest {
    var userProfileStatusObserver: TestUserProfileUpdateObserver!

    var observerToken: Any?

    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()

        XCTAssertTrue(login())

        userProfileStatusObserver = TestUserProfileUpdateObserver()
        observerToken = userSession?.userProfile.add(observer: userProfileStatusObserver)
    }

    override func tearDown() {
        observerToken = nil
        userProfileStatusObserver = nil
        super.tearDown()
    }

    func testThatItCanCheckThatAHandleIsAvailable() {
        // GIVEN
        let handle = "Oscar"

        // WHEN
        userSession?.userProfile.requestCheckHandleAvailability(handle: handle)

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileStatusObserver.invokedCallbacks.count, 1)
        guard let first = userProfileStatusObserver.invokedCallbacks.first else { return }
        switch first {
        case let .didCheckAvailabilityOfHandle(_handle, available):
            XCTAssertEqual(handle, _handle)
            XCTAssertTrue(available)
        default:
            XCTFail()
        }
    }

    func testThatItCanCheckThatAHandleIsNotAvailable() {
        // GIVEN
        let handle = "Oscar"

        mockTransportSession.performRemoteChanges { _ in
            self.user1.handle = handle
        }

        // WHEN
        userSession?.userProfile.requestCheckHandleAvailability(handle: handle)

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileStatusObserver.invokedCallbacks.count, 1)
        guard let first = userProfileStatusObserver.invokedCallbacks.first else { return }
        switch first {
        case let .didCheckAvailabilityOfHandle(_handle, available):
            XCTAssertEqual(handle, _handle)
            XCTAssertFalse(available)
        default:
            XCTFail()
        }
    }

    func testThatItCanSetTheHandle() {
        // GIVEN
        let handle = "Evelyn"

        // WHEN
        userSession?.userProfile.requestSettingHandle(handle: handle)

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileStatusObserver.invokedCallbacks.count, 1)
        guard let first = userProfileStatusObserver.invokedCallbacks.first else { return }
        switch first {
        case .didSetHandle:
            break
        default:
            XCTFail()
            return
        }

        let selfUser = ZMUser.selfUser(inUserSession: userSession!)
        XCTAssertEqual(selfUser.handle, handle)

        mockTransportSession.performRemoteChanges { _ in
            XCTAssertEqual(self.selfUser.handle, handle)
        }
    }

    // FIXME: [WPB-5882] this test is flaky - [jacob]
    func disabled_testThatItIsNotifiedWhenFailsToSetTheHandleBecauseItExists() {
        // GIVEN
        let handle = "Evelyn"

        mockTransportSession.performRemoteChanges { _ in
            self.user1.handle = handle
        }

        // WHEN
        userSession?.userProfile.requestSettingHandle(handle: handle)

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileStatusObserver.invokedCallbacks.count, 1)
        guard let first = userProfileStatusObserver.invokedCallbacks.first else { return }
        switch first {
        case .didFailToSetHandleBecauseExisting:
            break
        default:
            XCTFail()
            return
        }
    }

    func testThatItIsNotifiedWhenFailsToSetTheHandle() {
        // GIVEN
        let handle = "Evelyn"

        mockTransportSession.responseGeneratorBlock = { req in
            if req.path == "/self/handle" {
                return ZMTransportResponse(
                    payload: nil,
                    httpStatus: 400,
                    transportSessionError: nil,
                    apiVersion: APIVersion.v0.rawValue
                )
            }
            return nil
        }

        // WHEN
        userSession?.userProfile.requestSettingHandle(handle: handle)

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(userProfileStatusObserver.invokedCallbacks.count, 1)
        guard let first = userProfileStatusObserver.invokedCallbacks.first else { return }
        switch first {
        case .didFailToSetHandle:
            break
        default:
            XCTFail()
            return
        }
    }
}
