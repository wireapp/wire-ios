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

import Foundation
import WireAuthenticationAPI
import WireNetwork
import XCTest

@testable import WireAuthenticationUI

final class DetermineAuthMethodViewModelTests: XCTestCase, DetermineAuthMethodViewModel.Factory {

    private var router: MockRouter!
    private var sut: DetermineAuthMethodViewModel!

    /// The auth method returned by the determine-auth-method use case.
    private var stubbedAuthMethod: AuthenticationMethod = .onPremLogin(
        email: "mika@example.com",
        backendConfig: URL(string: "https://config.example.com")!
    )

    /// The backend the on-prem login resolves to (returned by the fetch-backend-config use case).
    private var stubbedTargetEnvironment: BackendEnvironment2!

    @MainActor
    override func setUp() async throws {
        router = MockRouter()
        stubbedTargetEnvironment = Self.backendEnvironment(host: "target.example.com")
    }

    override func tearDown() {
        router = nil
        sut = nil
    }

    // MARK: - Tests

    @MainActor
    func test_multibackendDisabled_differentBackend_isBlocked() async {
        // given an account already exists on a different backend
        makeSUT(
            allowsMultipleBackends: false,
            existingBackendHosts: ["existing.example.com"]
        )
        stubbedTargetEnvironment = Self.backendEnvironment(host: "target.example.com")

        // when
        await sut.submitEmailOrSSOCode()

        // then the switch is blocked
        XCTAssertEqual(sut.alert, .switchBackendBlocked)
        XCTAssertNil(sut.modalDestination)
    }

    @MainActor
    func test_multibackendDisabled_sameBackend_isAllowed() async {
        // given an account already exists on the same backend
        makeSUT(
            allowsMultipleBackends: false,
            existingBackendHosts: ["target.example.com"]
        )
        stubbedTargetEnvironment = Self.backendEnvironment(host: "target.example.com")

        // when
        await sut.submitEmailOrSSOCode()

        // then the confirmation is presented
        XCTAssertNil(sut.alert)
        assertSwitchBackendConfirmationPresented()
    }

    @MainActor
    func test_multibackendDisabled_noExistingAccounts_isAllowed() async {
        // given no other account exists yet
        makeSUT(
            allowsMultipleBackends: false,
            existingBackendHosts: []
        )
        stubbedTargetEnvironment = Self.backendEnvironment(host: "target.example.com")

        // when
        await sut.submitEmailOrSSOCode()

        // then switching the single backend is allowed
        XCTAssertNil(sut.alert)
        assertSwitchBackendConfirmationPresented()
    }

    @MainActor
    func test_multibackendEnabled_differentBackend_isAllowed() async {
        // given multibackend support is enabled and an account exists on a different backend
        makeSUT(
            allowsMultipleBackends: true,
            existingBackendHosts: ["existing.example.com"]
        )
        stubbedTargetEnvironment = Self.backendEnvironment(host: "target.example.com")

        // when
        await sut.submitEmailOrSSOCode()

        // then the confirmation is presented
        XCTAssertNil(sut.alert)
        assertSwitchBackendConfirmationPresented()
    }

    @MainActor
    func test_multibackendDisabled_cloudLoginOnDifferentBackend_isBlocked() async {
        // given an account exists on a different backend and the user logs in via email on the
        // default (flow) backend
        stubbedAuthMethod = .loginViaEmail(email: "mika@example.com", didDetectDomainConflict: false)
        makeSUT(
            allowsMultipleBackends: false,
            existingBackendHosts: ["existing.example.com"]
        )

        // when
        await sut.submitEmailOrSSOCode()

        // then the login is blocked
        XCTAssertEqual(sut.alert, .switchBackendBlocked)
        XCTAssertTrue(router.navigate_Invocations.isEmpty)
    }

    @MainActor
    func test_multibackendDisabled_loginOnSameBackend_isAllowed() async {
        // given an account exists on the same backend as the flow environment
        stubbedAuthMethod = .loginViaEmail(email: "mika@example.com", didDetectDomainConflict: false)
        makeSUT(
            allowsMultipleBackends: false,
            existingBackendHosts: ["flow.example.com"]
        )

        // when
        await sut.submitEmailOrSSOCode()

        // then the login proceeds
        XCTAssertNil(sut.alert)
        XCTAssertFalse(router.navigate_Invocations.isEmpty)
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT(
        allowsMultipleBackends: Bool,
        existingBackendHosts: Set<String>,
        emailOrSSOCode: String = "",
        overrideAllowEmailLoginOnly: Bool = false
    ) {
        sut = DetermineAuthMethodViewModel(
            factory: self,
            router: router,
            bridge: WireAuthenticationBridge(),
            environment: Self.backendEnvironment(host: "flow.example.com"),
            existsAnotherAccount: !existingBackendHosts.isEmpty,
            allowsMultipleBackends: allowsMultipleBackends,
            existingBackendHosts: existingBackendHosts,
            overrideAllowEmailLoginOnly: overrideAllowEmailLoginOnly
        )
    }

    @MainActor
    private func assertSwitchBackendConfirmationPresented(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .switchBackendConfirmation = sut.modalDestination else {
            XCTFail(
                "expected switchBackendConfirmation, got \(String(describing: sut.modalDestination))",
                file: file,
                line: line
            )
            return
        }
    }

    private static func backendEnvironment(host: String) -> BackendEnvironment2 {
        let url = URL(string: "https://\(host)")!
        return BackendEnvironment2(
            title: host,
            environmentType: .custom(url: url),
            config: .init(
                endpoints: .init(
                    restAPIURL: url,
                    websocketURL: url,
                    blacklistURL: url,
                    teamsURL: url,
                    accountsURL: url,
                    websiteURL: url,
                    countlyURL: nil
                ),
                pinnedKeys: [],
                proxyConfig: nil
            )
        )
    }

    // MARK: - DetermineAuthMethodViewModel.Factory

    var viewModel: DetermineAuthMethodViewModel { fatalError("not needed here") }

    func loginView(
        email: String?,
        didDetectDomainConflict: Bool,
        environment: BackendEnvironment2
    ) -> LoginViaEmailView {
        fatalError("not needed here")
    }

    func loginOrRegisterView(
        email: String?,
        didDetectDomainConflict: Bool,
        environment: BackendEnvironment2
    ) -> LoginViaEmailView {
        fatalError("not needed here")
    }

    func noHistoryView(result: AuthenticationResult) -> NoHistoryView {
        fatalError("not needed here")
    }

    func determineAuthMethodUseCase() async throws -> any DetermineAuthMethodUseCaseProtocol {
        StubDetermineAuthMethodUseCase(method: stubbedAuthMethod)
    }

    func fetchBackendConfigUseCase() -> any FetchBackendConfigUseCaseProtocol {
        MockFetchBackendConfigUseCase(environment: stubbedTargetEnvironment)
    }

    func loginViaSSOUseCase(environment: BackendEnvironment2?) async throws -> any LoginViaSSOUseCaseProtocol {
        fatalError("not needed here")
    }

    func validateEmailOrSSOCodeUseCase() -> any ValidateEmailOrSSOCodeUseCaseProtocol {
        StubValidateEmailOrSSOCodeUseCase()
    }

}

private struct StubDetermineAuthMethodUseCase: DetermineAuthMethodUseCaseProtocol {

    let method: AuthenticationMethod

    func invoke(emailOrSSOCode: String) async throws -> AuthenticationMethod {
        method
    }

}

private struct StubValidateEmailOrSSOCodeUseCase: ValidateEmailOrSSOCodeUseCaseProtocol {

    func invoke(input: String) throws -> ValidatedEmailOrSSOCode {
        .email(email: input, domain: "example.com")
    }

}
