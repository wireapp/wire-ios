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

final class DetermineAuthMethodUseCaseTests: XCTestCase {

    private var mockAuthenticationAPI: MockAuthenticationAPI!
    private var sut: DetermineAuthMethodUseCase!

    override func setUp() {
        mockAuthenticationAPI = MockAuthenticationAPI()

        sut = DetermineAuthMethodUseCase(
            validateEmailOrSSOCode: ValidateEmailOrSSOCodeUseCase(),
            authenticationAPI: mockAuthenticationAPI
        )
    }

    override func tearDown() {
        mockAuthenticationAPI = nil
        sut = nil
    }

    func testInvoke_withInvalidInput() async throws {
        // given, when, then
        await XCTAssertThrowsErrorAsync(DetermineAuthMethodUseCaseFailure.invalidEmailOrSSOCode) { [self] in
            _ = try await sut.invoke(emailOrSSOCode: "some invalid input")
        }
    }

    @MainActor
    func testInvoke_withSSOCode() async throws {
        // given, when
        let authMethod = try await sut.invoke(emailOrSSOCode: "wire-acd708f0-7fab-4b5f-9c1e-2e570bcf7372")

        // then
        XCTAssertEqual(authMethod, .loginViaSSO(code: UUID(uuidString: "acd708f0-7fab-4b5f-9c1e-2e570bcf7372")!))
    }

    @MainActor
    func testInvoke_withOnPremEmailAndLegacyAPI() async throws {
        // given
        let backendURL = URL(string: "example.com")!
        mockAuthenticationAPI
            .getDomainRegistrationForEmail_MockError = AuthenticationAPIError.unsupportedEndpointForAPIVersion
        mockAuthenticationAPI.getOnPremConfigURLForDomain_MockValue = DomainInfo(configurationURL: backendURL)

        // when
        let authMethod = try await sut.invoke(emailOrSSOCode: "user@example.com")

        // then
        XCTAssertEqual(authMethod, .onPremLogin(email: "user@example.com", backendConfig: backendURL))
    }

    @MainActor
    func testInvoke_withNonOnPremEmailAndLegacyAPI() async throws {
        // given
        let testCases: [AuthenticationAPIError] = [.configNotFound, .domainNotFound]

        for testCase in testCases {
            mockAuthenticationAPI
                .getDomainRegistrationForEmail_MockError = AuthenticationAPIError.unsupportedEndpointForAPIVersion
            mockAuthenticationAPI.getOnPremConfigURLForDomain_MockError = testCase

            // when
            let authMethod = try await sut.invoke(emailOrSSOCode: "user@example.com")

            // then
            XCTAssertEqual(authMethod, .loginOrRegisterViaEmail(email: "user@example.com"))
        }
    }

    @MainActor
    func testInvoke_withEmail_whenSuccess() async throws {
        // given
        let email = "user@example.com"
        let someSSO = UUID()
        let someBackendURL = URL(string: "example.com")!

        let testCases: [(config: DomainRegistrationConfiguration, expected: AuthenticationMethod)] = [
            (config: .make(domainRedirect: .none), expected: .loginOrRegisterViaEmail(email: email)),
            (config: .make(domainRedirect: .locked), expected: .loginOrRegisterViaEmail(email: email)),
            (config: .make(domainRedirect: .preAuthorized), expected: .loginOrRegisterViaEmail(email: email)),
            (config: .make(domainRedirect: .noRegistration), expected: .loginViaEmail(email: email)),
            (
                config: .make(domainRedirect: .sso, ssoCodeString: someSSO.uuidString),
                expected: .loginViaSSO(code: someSSO)
            ),
            (
                config: .make(backendURLString: someBackendURL.absoluteString, domainRedirect: .backend),
                expected: .onPremLogin(email: email, backendConfig: someBackendURL)
            ),
        ]

        for testCase in testCases {
            mockAuthenticationAPI.getDomainRegistrationForEmail_MockValue = testCase.config

            // when
            let authMethod = try await sut.invoke(emailOrSSOCode: "user@example.com")

            // then
            XCTAssertEqual(authMethod, testCase.expected)
        }
    }

    @MainActor
    func testInvoke_withEmail_whenInvalidResponse() async {
        // given
        let testCases: [DomainRegistrationConfiguration] = [
            .make(domainRedirect: .sso), // Response missing SSO code
            .make(domainRedirect: .backend), // Response missing backend URL
        ]

        for config in testCases {
            mockAuthenticationAPI.getDomainRegistrationForEmail_MockValue = config

            // when, then
            await XCTAssertThrowsErrorAsync(DetermineAuthMethodUseCaseFailure.invalidResponse) { [self] in
                _ = try await sut.invoke(emailOrSSOCode: "user@example.com")
            }
        }
    }

    @MainActor
    func testInvoke_withOnPremEmail_whenCloudAccountExists() async throws {
        // given
        mockAuthenticationAPI.getDomainRegistrationForEmail_MockValue = .make(
                domainRedirect: .none,
                isCloudAccountAlreadyRegistered: true
        )

        // when, then
        await XCTAssertThrowsErrorAsync(
            DetermineAuthMethodUseCaseFailure.onPremNotPossible(recovery: .loginViaEmail(email: "user@example.com"))
        ) { [self] in
            _ = try await sut.invoke(emailOrSSOCode: "user@example.com")
        }
    }

    @MainActor
    func testInvoke_mapsErrors() async throws {
        // given
        let noInternetError = URLError(.notConnectedToInternet)
        let someError = NSError(domain: "SomeDomain", code: 0, userInfo: nil)

        let testCases: [(underlyingError: any Error, expected: DetermineAuthMethodUseCaseFailure)] = [
            (underlyingError: AuthenticationAPIError.invalidResponse, expected: .invalidResponse),
            (underlyingError: noInternetError, expected: .urlError(noInternetError)),
            (underlyingError: someError, expected: .unknown),
        ]

        for testCase in testCases {
            mockAuthenticationAPI.getDomainRegistrationForEmail_MockError = testCase.underlyingError

            // when, then
            await XCTAssertThrowsErrorAsync(testCase.expected) { [self] in
                _ = try await sut.invoke(emailOrSSOCode: "user@example.com")
            }
        }
    }

}


// MARK: Private Helpers

private extension DomainRegistrationConfiguration {

    static func make(
        backendURLString: String? = nil,
        domainRedirect: DomainRedirect,
        isCloudAccountAlreadyRegistered: Bool? = nil,
        ssoCodeString: String? = nil
    ) -> DomainRegistrationConfiguration {
        DomainRegistrationConfiguration(
            backendURLString: backendURLString,
            domainRedirect: domainRedirect,
            isCloudAccountAlreadyRegistered: isCloudAccountAlreadyRegistered,
            ssoCodeString: ssoCodeString
        )
    }

}
