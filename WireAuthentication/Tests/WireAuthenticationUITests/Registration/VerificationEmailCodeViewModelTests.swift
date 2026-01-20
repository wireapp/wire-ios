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

import SwiftUI
import WireAuthenticationAPI
import WireAuthenticationAPISupport
import WireTestingPackage
import XCTest

@testable import WireAuthenticationUI
@testable import WireReusableUIComponents

final class VerificationEmailCodeViewModelTests: XCTestCase, VerificationEmailCodeViewModel.Factory {

    private var router: MockRouter!
    private var sut: VerificationEmailCodeViewModel!
    private var mockCreateAuthenticationResultUseCase: MockCreateAuthenticationResultUseCaseProtocol!
    private var mockRegisterPersonalAccountUseCase: MockRegisterPersonalAccountUseCaseProtocol!
    private var mockRequestEmailVerificationCodeUseCase: MockRequestEmailVerificationCodeUseCaseProtocol!
    private var onRegisterAccountCalled = false
    private var analyticsEventTracker: MockRegistrationAnalyticsTrackerProtocol!

    @MainActor
    override func setUp() async throws {
        mockCreateAuthenticationResultUseCase = MockCreateAuthenticationResultUseCaseProtocol()
        router = MockRouter()
        mockRegisterPersonalAccountUseCase = MockRegisterPersonalAccountUseCaseProtocol()
        mockRequestEmailVerificationCodeUseCase = MockRequestEmailVerificationCodeUseCaseProtocol()
        analyticsEventTracker = MockRegistrationAnalyticsTrackerProtocol()
        analyticsEventTracker.trackPersonalAccountCreationFailedCodeVerification_MockMethod = {}
        sut = VerificationEmailCodeViewModel(
            factory: self,
            router: router,
            email: "mika@example.com",
            password: "password",
            name: "mika",
            onFlowCompletion: { [self] _ in onRegisterAccountCalled = true },
            analyticsEventTracker: analyticsEventTracker
        )
    }

    override func tearDown() {
        mockCreateAuthenticationResultUseCase = nil
        router = nil
        sut = nil
        mockRegisterPersonalAccountUseCase = nil
        mockRequestEmailVerificationCodeUseCase = nil
        analyticsEventTracker = nil
    }

    // MARK: - Factory

    func registerPersonalAccountUseCase() async throws -> any RegisterPersonalAccountUseCaseProtocol {
        mockRegisterPersonalAccountUseCase
    }

    func requestEmailVerificationCodeUseCase() async throws -> any RequestEmailVerificationCodeUseCaseProtocol {
        mockRequestEmailVerificationCodeUseCase
    }

    func createAuthenticationResultUseCase() -> any CreateAuthenticationResultUseCaseProtocol {
        mockCreateAuthenticationResultUseCase
    }

    var viewModel: VerificationEmailCodeViewModel {
        fatalError("not needed here")
    }

    // MARK: - requestEmailVerificationCode tests

    @MainActor
    func testRegisterAccount_whenSuccessful() async throws {
        // given

        let authenticationResult = AuthenticationResult(
            userID: Fixture.someAccessToken.userID,
            cookies: [Fixture.someCookie],
            accessToken: Fixture.someAccessToken,
            emailCredentials: EmailCredentials(
                email: "mika@example.com",
                password: "password",
                verificationCode: nil
            ),
            backendEnvironment: Fixture.backendEnvironment,
            backendMetadata: Fixture.backendMetadata,
            proxyCredentials: nil
        )
        // mock
        mockRegisterPersonalAccountUseCase.invokeEmailPasswordVerificationCodeName_MockMethod = { _, _, _, _ in
            ([Fixture.someCookie], Fixture.uuid)
        }
        mockCreateAuthenticationResultUseCase
            .invokeUserIDCookiesAccessTokenEmailCredentials_MockValue = authenticationResult

        // when
        await sut.confirm()

        // then
        XCTAssertNil(sut.alert)
        XCTAssert(onRegisterAccountCalled)
    }

    @MainActor
    func testRegisterAccount_withBlacklistedEmail() async {
        // mock
        mockRegisterPersonalAccountUseCase
            .invokeEmailPasswordVerificationCodeName_MockError = RegisterPersonalAccountUseCaseError.blacklistedEmail

        // when
        await sut.confirm()

        // then
        XCTAssertEqual(sut.alert, .blacklistedEmail)
    }

}
