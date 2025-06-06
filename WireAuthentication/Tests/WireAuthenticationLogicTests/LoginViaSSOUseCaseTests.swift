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

@testable import WireAuthenticationAPISupport
@testable import WireAuthenticationLogic

final class LoginViaSSOUseCaseTests: XCTestCase {

    private var sut: LoginViaSSOUseCase!
    private var mockAuthenticationAPI: AuthenticationAPIMock!
    private let baseURL = URL(string: "https://example.com")!
    private let ssoCallbackURLScheme = "sso-callback"
    private var mockTokenGenerator: MockSSOLoginVerificationTokenGenerator!
    private var mockWebAuthenticator: MockWebAuthenticator!
    private var mockCreateAuthResultUseCase: MockCreateAuthenticationResultUseCaseProtocol!

    @MainActor
    override func setUp() async throws {
        mockAuthenticationAPI = AuthenticationAPIMock()
        mockTokenGenerator = MockSSOLoginVerificationTokenGenerator()
        mockWebAuthenticator = MockWebAuthenticator()
        mockCreateAuthResultUseCase = MockCreateAuthenticationResultUseCaseProtocol()
        sut = LoginViaSSOUseCase(
            authenticationAPI: mockAuthenticationAPI,
            baseURL: baseURL,
            ssoCallbackURLScheme: ssoCallbackURLScheme,
            verificationTokenGenerator: mockTokenGenerator,
            webAuthenticator: mockWebAuthenticator,
            createAuthResultUseCase: mockCreateAuthResultUseCase
        )

        mockCreateAuthResultUseCase.invokeUserIDCookiesAccessTokenEmailCredentials_MockValue =
            AuthenticationResult(
                userID: UUID(),
                cookies: [],
                accessToken: nil,
                emailCredentials: nil,
                backendEnvironment: Fixture.backendEnvironment
            )
    }

    override func tearDown() {
        mockAuthenticationAPI = nil
        mockTokenGenerator = nil
        mockWebAuthenticator = nil
        sut = nil
    }

    func testInvoke_NoDefaultCodeAvailable() async throws {
        // Mock
        mockAuthenticationAPI.getSSOCodeUuidReturnValue = nil

        // Then
        await XCTAssertThrowsErrorAsync(LoginViaSSOUseCaseError.noDefaultCodeAvailable) {
            // When
            try await self.sut.invoke(code: nil)
        }
    }

    func testInvoke_UsesDefaultCode() async throws {
        // Given
        let defaultCode = UUID()
        let verificationToken = SSOLoginVerificationToken()

        // Mock
        mockAuthenticationAPI.getSSOCodeUuidReturnValue = defaultCode
        mockAuthenticationAPI.validateLoginTokenSsoCodeUUIDVoidClosure = { _ in }
        mockTokenGenerator.mockToken = verificationToken

        // When
        _ = try? await sut.invoke(code: nil)

        // Then
        XCTAssertEqual(mockAuthenticationAPI.getSSOCodeUuidCallsCount, 1)
        XCTAssertEqual(mockAuthenticationAPI.validateLoginTokenSsoCodeUUIDVoidReceivedInvocations, [defaultCode])
    }

    func testInvoke_UsesProvidedCode() async throws {
        // Given
        let code = UUID()
        let verificationToken = SSOLoginVerificationToken()

        // Mock
        mockAuthenticationAPI.validateLoginTokenSsoCodeUUIDVoidClosure = { _ in }
        mockTokenGenerator.mockToken = verificationToken

        // When
        _ = try? await sut.invoke(code: code)

        // Then
        XCTAssertEqual(mockAuthenticationAPI.getSSOCodeUuidCallsCount, 0)
        XCTAssertEqual(mockAuthenticationAPI.validateLoginTokenSsoCodeUUIDVoidReceivedInvocations, [code])
    }

    func testInvoke_SuccessCallback() async throws {
        // Given
        let code = UUID()
        let verificationToken = SSOLoginVerificationToken()

        // Mock
        mockAuthenticationAPI.validateLoginTokenSsoCodeUUIDVoidClosure = { _ in }
        mockTokenGenerator.mockToken = verificationToken
        mockWebAuthenticator.mockResult = nil

        // When
        _ = try? await sut.invoke(code: code)

        // Then
        XCTAssertEqual(mockAuthenticationAPI.validateLoginTokenSsoCodeUUIDVoidReceivedInvocations, [code])

        let success = "success_redirect=\(makeSuccessCallback(verificationToken: verificationToken))"
        let error = "error_redirect=\(makeErrorCallback(verificationToken: verificationToken))"

        let expectedAuthURL = try XCTUnwrap(URL(
            string: "https://example.com/sso/initiate-login/\(code.uuidString)?\(success)&\(error)"
        ))
        let actualAuthURL = mockWebAuthenticator.invocations.first?.absoluteString.removingPercentEncoding!
        XCTAssertEqual(actualAuthURL, expectedAuthURL.absoluteString)
    }

    private func makeSuccessCallback(verificationToken: SSOLoginVerificationToken) -> String {
        let token = verificationToken.uuid.uuidString.lowercased()
        return "sso-callback://login/success?cookie=$cookie&userid=$userid&validation_token=\(token)"
    }

    private func makeErrorCallback(verificationToken: SSOLoginVerificationToken) -> String {
        let token = verificationToken.uuid.uuidString.lowercased()
        return "sso-callback://login/failure?label=$label&validation_token=\(token)"
    }

}
