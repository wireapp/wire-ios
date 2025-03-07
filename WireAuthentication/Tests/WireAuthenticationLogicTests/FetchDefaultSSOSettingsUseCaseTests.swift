//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAPI
import WireAPISupport
import WireAuthenticationAPI
import WireTestingPackage
import XCTest

@testable import WireAuthenticationLogic

final class FetchDefaultSSOSettingsUseCaseTests: XCTestCase {

    private var mockAuthenticationAPI: MockAuthenticationAPI!
    private var sut: FetchDefaultSSOSettingsUseCase!

    override func setUp() {
        mockAuthenticationAPI = MockAuthenticationAPI()

        sut = FetchDefaultSSOSettingsUseCase(authenticationAPI: mockAuthenticationAPI)
    }

    override func tearDown() {
        mockAuthenticationAPI = nil
        sut = nil
    }

    func testInvoke_whenSuccess() async throws {
        // given
        let expectedCode = UUID(uuidString: "234-123-567")
        mockAuthenticationAPI.getSSOCode_MockValue = expectedCode

        // when
        let ssoCode = try await sut.invoke()

        // then
        XCTAssertEqual(ssoCode, expectedCode)
    }

    func testInvoke_whenFailure() async throws {
        // given
        mockAuthenticationAPI.getSSOCode_MockError = FetchDefaultSSOSettingsUseCaseFailure.unknown

        // when, then
        await XCTAssertThrowsErrorAsync(FetchDefaultSSOSettingsUseCaseFailure.unknown) { [self] in
            _ = try await sut.invoke()
        }
    }

}
