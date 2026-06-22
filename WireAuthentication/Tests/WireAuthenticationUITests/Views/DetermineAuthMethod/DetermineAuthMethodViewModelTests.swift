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
import WireFoundation
import WireNetwork
import WireTestingPackage
import XCTest

@testable import WireAuthenticationUI

final class DetermineAuthMethodViewModelTests: XCTestCase {

    private var router: MockRouter!
    private var environment: BackendEnvironment2!

    @MainActor
    override func setUp() async throws {
        router = MockRouter()
        environment = MockDependencies().backendEnvironment
    }

    override func tearDown() {
        router = nil
        environment = nil
        super.tearDown()
    }

    // MARK: - isNextButtonEnabled

    @MainActor
    func testIsNextButtonEnabled_whenEmailLoginOnly() {
        // A valid email enables the button.
        XCTAssertTrue(makeSUT(emailOrSSOCode: "sam@example.com", overrideAllowEmailLoginOnly: true).isNextButtonEnabled)
        // An SSO code is not accepted when only email login is allowed.
        XCTAssertFalse(makeSUT(emailOrSSOCode: "team-wire", overrideAllowEmailLoginOnly: true).isNextButtonEnabled)
        // Invalid input keeps the button disabled.
        XCTAssertFalse(makeSUT(emailOrSSOCode: "not-valid", overrideAllowEmailLoginOnly: true).isNextButtonEnabled)
    }

    @MainActor
    func testIsNextButtonEnabled_whenEmailOrSSOAllowed() {
        // Both a valid email and a valid SSO code enable the button.
        XCTAssertTrue(makeSUT(emailOrSSOCode: "sam@example.com", overrideAllowEmailLoginOnly: false)
            .isNextButtonEnabled)
        XCTAssertTrue(makeSUT(emailOrSSOCode: "team-wire", overrideAllowEmailLoginOnly: false).isNextButtonEnabled)
        // Invalid input keeps the button disabled.
        XCTAssertFalse(makeSUT(emailOrSSOCode: "not-valid", overrideAllowEmailLoginOnly: false).isNextButtonEnabled)
    }

    // MARK: - submitEmailOrSSOCode (email-login-only)

    @MainActor
    func testSubmit_whenEmailLoginOnly_withValidEmail_navigatesToLoginWithTrimmedEmail() async throws {
        // given
        let sut = makeSUT(emailOrSSOCode: " sam@example.com ", overrideAllowEmailLoginOnly: true)

        // when
        await sut.submitEmailOrSSOCode()

        // then
        try XCTAssertCount(router.navigate_Invocations, count: 1)
        let destination = try XCTUnwrap(router.navigate_Invocations.first as? DetermineAuthMethodDestination)
        XCTAssertEqual(
            destination,
            .login(email: "sam@example.com", didDetectDomainConflict: false, environment: environment)
        )
    }

    @MainActor
    func testSubmit_whenEmailLoginOnly_withSSOCode_doesNotNavigate() async {
        // given: an SSO code is not a valid email and must be rejected in email-login-only mode
        let sut = makeSUT(emailOrSSOCode: "team-wire", overrideAllowEmailLoginOnly: true)

        // when
        await sut.submitEmailOrSSOCode()

        // then
        XCTAssertTrue(router.navigate_Invocations.isEmpty)
    }

    @MainActor
    func testSubmit_whenEmailLoginOnly_withInvalidInput_doesNotNavigate() async {
        // given
        let sut = makeSUT(emailOrSSOCode: "not-valid", overrideAllowEmailLoginOnly: true)

        // when
        await sut.submitEmailOrSSOCode()

        // then
        XCTAssertTrue(router.navigate_Invocations.isEmpty)
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        emailOrSSOCode: String,
        overrideAllowEmailLoginOnly: Bool
    ) -> DetermineAuthMethodViewModel {
        DetermineAuthMethodViewModel(
            factory: FakeDetermineAuthMethodFactory(),
            router: router,
            bridge: WireAuthenticationBridge(),
            environment: environment,
            emailOrSSOCode: emailOrSSOCode,
            existsAnotherAccount: false,
            overrideAllowEmailLoginOnly: overrideAllowEmailLoginOnly
        )
    }
}
