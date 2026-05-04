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

import WireAuthenticationAPI
import WireAuthenticationAPISupport
import WireNetwork
import WireNetworkSupport
import WireTestingPackage
import XCTest

@testable import WireAuthenticationLogic

final class LoginViaEmailUseCaseTests: XCTestCase {

    private var mockAuthenticationAPI: MockAuthenticationAPI!
    private var sut: LoginViaEmailUseCase!

    override func setUp() {
        mockAuthenticationAPI = MockAuthenticationAPI()

        sut = LoginViaEmailUseCase(
            authenticationAPI: mockAuthenticationAPI
        )
    }

    override func tearDown() {
        mockAuthenticationAPI = nil
        sut = nil
    }

    func testInvoke_whenSuccess() async throws {
        // given
        let accessToken = WireNetwork.AccessToken(userID: UUID(), token: "token", type: "type", expirationDate: Date())
        mockAuthenticationAPI
            .loginEmailPasswordVerificationCodeLabel_MockValue = ([Fixture.someCookie], accessToken)

        // when
        let result = try await sut.invoke(email: "email", password: "password", verificationCode: "code")

        // then
        XCTAssertEqual(result.0, [Fixture.someCookie])
        XCTAssertEqual(
            result.1,
            AccessToken(
                userID: accessToken.userID,
                token: accessToken.token,
                type: accessToken.type,
                expirationDate: accessToken.expirationDate
            )
        )
        let invocations = mockAuthenticationAPI.loginEmailPasswordVerificationCodeLabel_Invocations
        try XCTAssertCount(invocations, count: 1)
        XCTAssertEqual(invocations[0].email, "email")
        XCTAssertEqual(invocations[0].password, "password")
        XCTAssertEqual(invocations[0].verificationCode, "code")
    }

    func testInvoke_whenLoginViaEmailUseCaseFailure() async throws {
        // given
        let testCases: [(underlyingError: any Error, expected: LoginViaEmailUseCaseFailure)] = [
            (underlyingError: AuthenticationAPIError.invalidCredentials, expected: .invalidCredentials),
            (
                underlyingError: AuthenticationAPIError.twoFactorAuthenticationRequired,
                expected: .twoFactorAuthenticationRequired
            ),
            (
                underlyingError: AuthenticationAPIError.twoFactorAuthenticationFailed,
                expected: .twoFactorAuthenticationFailed
            ),
            (underlyingError: AuthenticationAPIError.accountPendingActivation, expected: .accountPendingActivation),
            (underlyingError: AuthenticationAPIError.accountSuspended, expected: .accountSuspended)
        ]

        for testCase in testCases {
            mockAuthenticationAPI.loginEmailPasswordVerificationCodeLabel_MockError = testCase.underlyingError

            // when, then
            await XCTAssertThrowsErrorAsync(testCase.expected) { [self] in
                _ = try await sut.invoke(email: "email", password: "password", verificationCode: "code")
            }
        }
    }

    func testInvoke_otherFailure() async throws {
        // given
        mockAuthenticationAPI.loginEmailPasswordVerificationCodeLabel_MockError = URLError(.notConnectedToInternet)

        // when, then
        await XCTAssertThrowsErrorAsync(URLError(.notConnectedToInternet)) { [self] in
            _ = try await sut.invoke(email: "email", password: "password", verificationCode: "code")
        }
    }
}
