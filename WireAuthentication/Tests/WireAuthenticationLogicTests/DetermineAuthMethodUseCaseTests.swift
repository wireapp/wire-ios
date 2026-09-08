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
import WireNetwork
import WireNetworkSupport
import WireTestingPackage
import XCTest

@testable import WireAuthenticationLogic

final class DetermineAuthMethodUseCaseTests: XCTestCase {

    private var mockAuthenticationAPI: MockAuthenticationAPI!
    private var session: URLSession!
    private var sut: DetermineAuthMethodUseCase!

    override func setUp() {
        mockAuthenticationAPI = MockAuthenticationAPI()
        session = .mockURLSession()

        // By default, no default SSO is configured for the backend so the use
        // case falls back to the domain-registration path. Individual tests can
        // override this to exercise the default-SSO branch.
        mockAuthenticationAPI.getSSOCodeForEmail_MockError = AuthenticationAPIError.ssoCodeNotFound

        sut = DetermineAuthMethodUseCase(
            validateEmailOrSSOCode: ValidateEmailOrSSOCodeUseCase(),
            authenticationAPI: mockAuthenticationAPI,
            urlSession: session
        )
    }

    override func tearDown() {
        mockAuthenticationAPI = nil
        session = nil
        sut = nil
    }

    func testInvoke_withInvalidInput() async throws {
        // given, when, then
        await XCTAssertThrowsErrorAsync(DetermineAuthMethodUseCaseFailure.invalidEmailOrSSOCode) { [self] in
            _ = try await sut.invoke(emailOrSSOCode: "some invalid input")
        }
    }

    func testInvoke_withSSOCode() async throws {
        // given, when
        let authMethod = try await sut.invoke(emailOrSSOCode: "wire-acd708f0-7fab-4b5f-9c1e-2e570bcf7372")

        // then
        XCTAssertEqual(authMethod, .loginViaSSO(code: UUID(uuidString: "acd708f0-7fab-4b5f-9c1e-2e570bcf7372")!))
    }

    // MARK: - Default SSO for the backend

    func testInvoke_withEmail_whenDefaultSSOCodeAvailable_returnsLoginViaSSO() async throws {
        // given
        let email = "user@example.com"
        let ssoCode = UUID()
        mockAuthenticationAPI.getSSOCodeForEmail_MockError = nil // override default, see setup
        mockAuthenticationAPI.getSSOCodeForEmail_MockValue = ssoCode

        // when
        let authMethod = try await sut.invoke(emailOrSSOCode: email)

        // then
        XCTAssertEqual(authMethod, .loginViaSSO(code: ssoCode))
        XCTAssertEqual(mockAuthenticationAPI.getSSOCodeForEmail_Invocations, [email])
        XCTAssertEqual(mockAuthenticationAPI.getDomainRegistrationForEmail_Invocations.count, 0)
    }

    func testInvoke_withEmail_whenDefaultSSOEndpointUnsupported_fallsBackToDomainRegistration() async throws {
        // given
        let email = "user@example.com"
        mockAuthenticationAPI
            .getSSOCodeForEmail_MockError = AuthenticationAPIError.unsupportedEndpointForAPIVersion
        mockAuthenticationAPI.getDomainRegistrationForEmail_MockValue = .make(domainRedirect: .none)

        // when
        let authMethod = try await sut.invoke(emailOrSSOCode: email)

        // then
        XCTAssertEqual(authMethod, .loginOrRegisterViaEmail(email: email))
        XCTAssertEqual(mockAuthenticationAPI.getSSOCodeForEmail_Invocations, [email])
        XCTAssertEqual(mockAuthenticationAPI.getDomainRegistrationForEmail_Invocations, [email])
    }

    func testInvoke_withEmail_whenDefaultSSOCodeNotFound_fallsBackToDomainRegistration() async throws {
        // given
        let email = "user@example.com"
        let teamSSOCode = UUID()
        mockAuthenticationAPI.getSSOCodeForEmail_MockError = AuthenticationAPIError.ssoCodeNotFound
        mockAuthenticationAPI.getDomainRegistrationForEmail_MockValue = .make(
            domainRedirect: .sso,
            ssoCodeString: teamSSOCode.uuidString
        )

        // when
        let authMethod = try await sut.invoke(emailOrSSOCode: email)

        // then
        XCTAssertEqual(authMethod, .loginViaSSO(code: teamSSOCode))
        XCTAssertEqual(mockAuthenticationAPI.getSSOCodeForEmail_Invocations, [email])
        XCTAssertEqual(mockAuthenticationAPI.getDomainRegistrationForEmail_Invocations, [email])
    }

    func testInvoke_withEmail_whenDefaultSSOFailsWithUnexpectedError_throws() async {
        // given
        mockAuthenticationAPI.getSSOCodeForEmail_MockError = URLError(.notConnectedToInternet)

        // when, then
        await XCTAssertThrowsErrorAsync(URLError(.notConnectedToInternet)) { [self] in
            _ = try await sut.invoke(emailOrSSOCode: "user@example.com")
        }
        XCTAssertEqual(mockAuthenticationAPI.getDomainRegistrationForEmail_Invocations.count, 0)
    }

    // MARK: - Legacy / fallback domain-registration path

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

    func testInvoke_withEmail_whenSuccess() async throws {
        // given
        let email = "user@example.com"
        let someSSO = UUID()
        let someBackendURL = URL(string: "example.com")!

        let testCases: [(config: DomainRegistrationConfiguration, expected: AuthenticationMethod)] = [
            (config: .make(domainRedirect: .none), expected: .loginOrRegisterViaEmail(email: email)),
            (
                config: .make(domainRedirect: .noRegistration, isCloudAccountAlreadyRegistered: true),
                expected: .loginViaEmail(email: email, didDetectDomainConflict: true)
            ),
            (config: .make(domainRedirect: .locked), expected: .loginOrRegisterViaEmail(email: email)),
            (config: .make(domainRedirect: .preAuthorized), expected: .loginOrRegisterViaEmail(email: email)),
            (
                config: .make(domainRedirect: .noRegistration),
                expected: .loginViaEmail(
                    email: email,
                    didDetectDomainConflict: false
                )
            ),
            (
                config: .make(domainRedirect: .sso, ssoCodeString: someSSO.uuidString),
                expected: .loginViaSSO(code: someSSO)
            )
        ]

        for testCase in testCases {
            mockAuthenticationAPI.getDomainRegistrationForEmail_MockValue = testCase.config

            // when
            let authMethod = try await sut.invoke(emailOrSSOCode: "user@example.com")

            // then
            XCTAssertEqual(authMethod, testCase.expected)
        }
    }

    func testInvoke_withEmail_whenInvalidResponse() async {
        // given
        let testCases: [DomainRegistrationConfiguration] = [
            .make(domainRedirect: .sso), // Response missing SSO code
            .make(domainRedirect: .backend) // Response missing backend URL
        ]

        for config in testCases {
            mockAuthenticationAPI.getDomainRegistrationForEmail_MockValue = config

            // when, then
            await XCTAssertThrowsErrorAsync(AuthenticationAPIError.invalidResponse) { [self] in
                _ = try await sut.invoke(emailOrSSOCode: "user@example.com")
            }
        }
    }

    func testInvoke_withEmail_whenServiceUnavailable() async throws {
        // given
        let email = "user@example.com"
        mockAuthenticationAPI.getDomainRegistrationForEmail_MockError = AuthenticationAPIError.serviceUnavailable

        // when
        let authMethod = try await sut.invoke(emailOrSSOCode: email)

        // then
        XCTAssertEqual(authMethod, .loginOrRegisterViaEmail(email: email))
    }

    func testInvoke_forwardsUnderlyingErrors() async throws {
        // given
        mockAuthenticationAPI.getDomainRegistrationForEmail_MockError = URLError(.notConnectedToInternet)

        // when, then
        await XCTAssertThrowsErrorAsync(URLError(.notConnectedToInternet)) { [self] in
            _ = try await sut.invoke(emailOrSSOCode: "user@example.com")
        }
    }

    func testInvoke_withEmail_onPremLogin_whenSuccess() async throws {
        // given
        let backendURL = URL(string: "https://backend.example.com/config")!
        let configJsonURL = URL(string: "https://example.com/deeplink.json")!
        let json = """
        {
            "config_json_url": "\(configJsonURL.absoluteString)",
            "webapp_welcome_url": "https://webapp.example.com/"
        }
        """
        let data = json.data(using: .utf8)!

        mockAuthenticationAPI.getDomainRegistrationForEmail_MockValue = DomainRegistrationConfiguration.make(
            backendURLString: backendURL.absoluteString,
            domainRedirect: .backend
        )
        URLProtocolMock.mockHandler = { request in
            XCTAssertEqual(request.url, backendURL)
            return (data, HTTPURLResponse(url: backendURL, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }

        // when
        let authMethod = try await sut.invoke(emailOrSSOCode: "user@example.com")

        // then
        XCTAssertEqual(authMethod, .onPremLogin(email: "user@example.com", backendConfig: configJsonURL))
    }

    func testInvoke_onPremLogin_WhenBackendConfigJsonURLIsMissing() async throws {
        // given
        let backendURL = URL(string: "https://backend.example.com/config")!
        let jsonData = Data("{}".utf8)

        mockAuthenticationAPI.getDomainRegistrationForEmail_MockValue = DomainRegistrationConfiguration.make(
            backendURLString: backendURL.absoluteString,
            domainRedirect: .backend
        )
        URLProtocolMock.mockHandler = { request in
            XCTAssertEqual(request.url, backendURL)
            return (jsonData, HTTPURLResponse(url: backendURL, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }

        // when, then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.invalidResponse) { [self] in
            _ = try await sut.invoke(emailOrSSOCode: "user@example.com")
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
