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
import WireSyncEngineSupport
@testable import WireSyncEngine

final class ChangeUsernameUseCaseTests: XCTestCase {

    func testThatIt_requestsSettingHandle() async throws {
        // given
        let username = "username"
        let userProfile = MockUserProfile()
        let didRegisterObserver = expectation(description: "did register observer")
        userProfile.requestSettingHandleHandle_MockMethod = { _ in }
        userProfile.addObserver_MockMethod = { _ in
            didRegisterObserver.fulfill()
        }
        let sut = ChangeUsernameUseCase(userProfile: userProfile)

        // when
        async let usernameChange: Void = try sut.invoke(username: username)
        await fulfillment(of: [didRegisterObserver])
        sut.didSetHandle()
        try await usernameChange

        // then
        XCTAssertEqual(userProfile.requestSettingHandleHandle_Invocations.first, username)
    }

    func testThatIt_ThrowsTakenError_whenObserverInvokes_didFailToSetHandleBecauseExisting() async throws {
        // given
        let username = "username"
        let userProfile = MockUserProfile()
        let didRegisterObserver = expectation(description: "did register observer")
        userProfile.requestSettingHandleHandle_MockMethod = { _ in }
        userProfile.addObserver_MockMethod = { _ in
            didRegisterObserver.fulfill()
        }
        let sut = ChangeUsernameUseCase(userProfile: userProfile)
        let usernameChange = Task {
            try await sut.invoke(username: username)
        }
        await fulfillment(of: [didRegisterObserver])

        // when
        sut.didFailToSetHandleBecauseExisting()

        // then
        await assertItThrows(error: ChangeUsernameError.taken) {
            try await usernameChange.value
        }

        XCTAssertEqual(userProfile.requestSettingHandleHandle_Invocations.first, username)
    }

    func testThatIt_ThrowsUnknownError_whenObserverInvokes_didFailToSetHandle() async throws {
        // given
        let username = "username"
        let userProfile = MockUserProfile()
        let didRegisterObserver = expectation(description: "did register observer")
        userProfile.requestSettingHandleHandle_MockMethod = { _ in }
        userProfile.addObserver_MockMethod = { _ in
            didRegisterObserver.fulfill()
        }
        let sut = ChangeUsernameUseCase(userProfile: userProfile)
        let usernameChange = Task {
            try await sut.invoke(username: username)
        }
        await fulfillment(of: [didRegisterObserver])

        // when
        sut.didFailToSetHandle()

        // then
        await assertItThrows(error: ChangeUsernameError.unknown) {
            try await usernameChange.value
        }

        XCTAssertEqual(userProfile.requestSettingHandleHandle_Invocations.first, username)
    }

}
