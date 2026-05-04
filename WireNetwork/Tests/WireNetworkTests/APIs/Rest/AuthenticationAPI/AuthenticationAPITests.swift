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

import XCTest

@testable import WireNetwork
@testable import WireNetworkSupport

final class AuthenticationAPITests: XCTestCase {

    private var apiSnapshotHelper: NetworkServiceSnapshotHelper<any AuthenticationAPI>!

    // MARK: - Setup

    override func setUp() {
        apiSnapshotHelper = NetworkServiceSnapshotHelper<any AuthenticationAPI> { networkService, apiVersion in
            AuthenticationAPIBuilder(networkService: networkService)
                .makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
    }

    // MARK: - Request generation

    func testGetDomainRegistration_V0_To_V7() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol()
        let builder = AuthenticationAPIBuilder(networkService: networkService)

        for apiVersion in [APIVersion.v0, .v1, .v2, .v3, .v4, .v5, .v6, .v7] {
            let sut = builder.makeAPI(for: apiVersion)

            // Then
            await XCTAssertThrowsErrorAsync(AuthenticationAPIError.unsupportedEndpointForAPIVersion) {
                try await sut.getDomainRegistration(forEmail: "email@example.com")
            }
        }
    }

    func testGetDomainRegistration_Request_Generation_V8_Onwards() async throws {
        // Given
        let apiVersions = APIVersion.v8.andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            // When
            _ = try await sut.getDomainRegistration(forEmail: "email@example.com")
        }
    }

    func testGetOnPremConfigURLRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getOnPremConfigURL(forDomain: "example.com")
        }
    }

    func testGetOnPremConfigURLEncodeRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getOnPremConfigURL(forDomain: "example com")
        }
    }

    func testLoginViaEmailRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.login(
                email: "email@example.com",
                password: "123456",
                verificationCode: "193756",
                label: nil
            )
        }
    }

    func testGetSSOCode() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getSSOCode()
        }
    }

    func testRequestVerificationCode_Request_Generation_V0_Onwards() async throws {
        // Given
        let apiVersions = APIVersion.v0.andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            // When
            _ = try await sut.requestVerificationCode(for: Scaffolding.email)
        }
    }

    func testRequestEmailVerificationCode_Request_Generation_V0_Onwards() async throws {
        // Given
        let apiVersions = APIVersion.v0.andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            // When
            _ = try await sut.requestEmailVerificationCode(for: Scaffolding.email)
        }
    }

    func testRegisterAccount_Request_Generation_V0_Onwards() async throws {
        // Given
        let apiVersions = APIVersion.v0.andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            // When
            _ = try await sut.registerAccount(
                email: Scaffolding.email,
                emailCode: Scaffolding.emailCode,
                name: Scaffolding.name,
                password: Scaffolding.password,
                label: "label"
            )
        }
    }

    // MARK: - Response handling

    func testGetDomainRegistration_Response_Handling_V8_Success() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "GetDomainRegistrationSuccessResponseV8")
        ])

        let sut = AuthenticationAPIV8(networkService: networkService)

        // When
        let response = try await sut.getDomainRegistration(forEmail: "email@example.com")

        // Then
        XCTAssertEqual(
            response,
            DomainRegistrationConfiguration(
                backendURLString: "https://example.com",
                domainRedirect: .none,
                isCloudAccountAlreadyRegistered: false,
                ssoCodeString: "99db9768-04e3-4b5d-9268-831b6a25c4ab"
            )
        )
    }

    func testGetDomainRegistration_Response_Handling_V10_Success() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "GetDomainRegistrationSuccessResponseV10")
        ])

        let sut = AuthenticationAPIV10(networkService: networkService)

        // When
        let response = try await sut.getDomainRegistration(forEmail: "email@example.com")

        // Then
        XCTAssertEqual(
            response,
            DomainRegistrationConfiguration(
                backendURLString: "https://example.com",
                domainRedirect: .none,
                isCloudAccountAlreadyRegistered: false,
                ssoCodeString: "99db9768-04e3-4b5d-9268-831b6a25c4ab"
            )
        )
    }

    func testGetDomainRegistration_ResponseWithNullValues_Handling_V8_Success() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "GetDomainRegistrationSuccessResponse_WithNullValuesV8")
        ])

        let sut = AuthenticationAPIV8(networkService: networkService)

        // When
        let response = try await sut.getDomainRegistration(forEmail: "email@example.com")

        // Then
        XCTAssertEqual(
            response,
            DomainRegistrationConfiguration(
                backendURLString: nil,
                domainRedirect: .preAuthorized,
                isCloudAccountAlreadyRegistered: false,
                ssoCodeString: nil
            )
        )
    }

    func testGetDomainRegistration_Response_Handling_V8_Invalid_Domain() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.badRequest, "GetDomainRegistrationErrorResponse_InvalidDomainV8")
        ])

        let sut = AuthenticationAPIV8(networkService: networkService)

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.invalidDomain) {
            // When
            try await sut.getDomainRegistration(forEmail: "email@example.com")
        }
    }

    func testGetDomainRegistration_Response_Handling_V8_Service_Unavailable() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.serviceUnavailable, "GetDomainRegistrationErrorResponse_ServiceUnavailableV8")
        ])

        let sut = AuthenticationAPIV8(networkService: networkService)

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.serviceUnavailable) {
            // When
            try await sut.getDomainRegistration(forEmail: "email@example.com")
        }
    }

    func testGetDomainRegistration_Response_Handling_V10_Invalid_Domain() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.badRequest, "GetDomainRegistrationErrorResponse_InvalidDomainV8") // same as in v8
        ])

        let sut = AuthenticationAPIV10(networkService: networkService)

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.invalidDomain) {
            // When
            try await sut.getDomainRegistration(forEmail: "email@example.com")
        }
    }

    func testGetDomainRegistration_Response_Handling_V10_Service_Unavailable() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.serviceUnavailable, "GetDomainRegistrationErrorResponse_ServiceUnavailableV8") // same as in v8
        ])

        let sut = AuthenticationAPIV10(networkService: networkService)

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.serviceUnavailable) {
            // When
            try await sut.getDomainRegistration(forEmail: "email@example.com")
        }
    }

    func testGetOnPremConfigURL_Response_Handling_Success() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "GetOnPremConfigURLSuccessResponseV0")
        ])

        let sut = AuthenticationAPIV8(networkService: networkService)

        // When
        let response = try await sut.getOnPremConfigURL(forDomain: "example.com")

        // Then
        XCTAssertEqual(
            response,
            DomainInfo(configurationURL: URL(string: "https://wire.example.com/config.json")!)
        )
    }

    func testGetOnPremConfigURL_Response_Handling_Custom_Backend_Not_Found() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.notFound, "GetOnPremConfigURLErrorResponse_CustomBackendNotFound_V0")
        ])

        let sut = AuthenticationAPIV8(networkService: networkService)

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.configNotFound) {
            // When
            try await sut.getOnPremConfigURL(forDomain: "example.com")
        }
    }

    func testLoginViaEmail_Response_Handling_Success() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "LoginViaEmailSuccessResponseV0")
        ])

        let sut = AuthenticationAPIV8(networkService: networkService)

        // When
        let response = try await sut.login(
            email: "email@example.com",
            password: "123456",
            verificationCode: nil,
            label: nil
        )

        // Then
        let expectedUserID = UUID(uuidString: "6396d5c6-e3fe-43cb-a635-75d3b7290c81")!
        let expectedToken = "RyhrMGDEtX6XrtOouJTovjt_4lFDlbxwHVE883XI0fB9VV4mopeQoKF"
        let expectedType = "Bearer"
        let expectedExpirationDate = Date(timeIntervalSinceNow: 900)

        XCTAssertEqual(response.1.userID, expectedUserID)
        XCTAssertEqual(response.1.token, expectedToken)
        XCTAssertEqual(response.1.type, expectedType)
        XCTAssertEqual(
            response.1.expirationDate.timeIntervalSince1970,
            expectedExpirationDate.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    func testLoginViaEmail_Response_Handling_Custom_Backend_Not_Found() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withError(
            statusCode: .forbidden,
            label: "code-authentication-required"
        )

        let sut = AuthenticationAPIV8(networkService: networkService)

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.twoFactorAuthenticationRequired) {
            // When
            try await sut.login(
                email: "email@example.com",
                password: "123456",
                verificationCode: nil,
                label: nil
            )
        }
    }

    func testValidateLoginToken_Response_Handling_InvalidSSOCode() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.notFound, "")
        ])

        let sut = AuthenticationAPIV8(networkService: networkService)
        let ssoCode = UUID()

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.SSOLoginError.invalidSSOCode) {
            // When
            try await sut.validateLoginToken(ssoCode: ssoCode)
        }
    }

    func testRequestVerificationCode_Response_Handling_V8_Success() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, nil)
        ])

        let sut = AuthenticationAPIV8(networkService: networkService)

        // When, Then no error thrown
        try await sut.requestVerificationCode(for: Scaffolding.email)
    }

    func testUpgradeToTeam_Response_Handling_V8_BadRequest() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withError(statusCode: .badRequest, label: "bad-request")

        let sut = AuthenticationAPIV8(networkService: networkService)

        do {
            // When
            try await sut.requestVerificationCode(for: Scaffolding.wrongAddress)
            XCTFail("Unexpected success")
        } catch AuthenticationAPIError.invalidEmail {
            // Then
        } catch {
            XCTFail("unexpected error: " + String(reflecting: error))
        }
    }

    func testRequestEmailVerificationCode_Response_Handling_Success() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, nil)
        ])

        let sut = AuthenticationAPIV8(networkService: networkService)

        // When, Then no error thrown
        try await sut.requestEmailVerificationCode(for: Scaffolding.email)
    }

    func testRequestEmailVerificationCode_Response_Handling_InvalidEmail() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withError(statusCode: .badRequest, label: "invalid-email")

        let sut = AuthenticationAPIV8(networkService: networkService)

        do {
            // When
            try await sut.requestEmailVerificationCode(for: Scaffolding.email)
            XCTFail("Unexpected success")
        } catch AuthenticationAPIError.RegistrationError.invalidEmail {
            // Then
        } catch {
            XCTFail("unexpected error: " + String(reflecting: error))
        }
    }

    func testRegisterAccount_Response_Handling_Success() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.created, "RegisterAccountSuccessResponseV8")
        ])

        let sut = AuthenticationAPIV8(networkService: networkService)

        // When
        let response = try await sut.registerAccount(
            email: Scaffolding.email,
            emailCode: Scaffolding.emailCode,
            name: Scaffolding.name,
            password: Scaffolding.password,
            label: "label"
        )

        // Then
        let expectedUserID = UUID(uuidString: "6396d5c6-e3fe-43cb-a635-75d3b7290c81")!

        XCTAssertEqual(response.1, expectedUserID)
    }

    func testRegisterAccount_Response_Handling_BadRequest() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withError(
            statusCode: .badRequest,
            label: "invalid-invitation-code"
        )

        let sut = AuthenticationAPIV8(networkService: networkService)

        do {
            // When
            _ = try await sut.registerAccount(
                email: Scaffolding.email,
                emailCode: Scaffolding.emailCode,
                name: Scaffolding.name,
                password: Scaffolding.password,
                label: "label"
            )
            XCTFail("Unexpected success")
        } catch AuthenticationAPIError.RegistrationError.invalidInvitationCode {
            // Then
        } catch {
            XCTFail("unexpected error: " + String(reflecting: error))
        }
    }

    // MARK: - getSSOCode(forEmail:)

    func testGetSSOCodeByEmail_V0_To_V14() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol()
        let builder = AuthenticationAPIBuilder(networkService: networkService)

        for apiVersion in APIVersion.allCasesUpTo(.v15) {
            let sut = builder.makeAPI(for: apiVersion)

            // Then
            await XCTAssertThrowsErrorAsync(AuthenticationAPIError.unsupportedEndpointForAPIVersion) {
                try await sut.getSSOCode(forEmail: Scaffolding.email)
            }
        }
    }

    func testGetSSOCodeByEmail_Request_Generation_V15() async throws {
        // Given
        let apiVersions = APIVersion.v15.andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            // When
            _ = try await sut.getSSOCode(forEmail: Scaffolding.email)
        }
    }

    func testGetSSOCodeByEmail_Response_Handling_V15_Success() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withResponses([
            (.ok, "GetSSOCodeByEmailSuccessResponseV15")
        ])

        let sut = AuthenticationAPIV15(networkService: networkService)

        // When
        let ssoCode = try await sut.getSSOCode(forEmail: Scaffolding.email)

        // Then
        XCTAssertEqual(ssoCode, UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!)
    }

    func testGetSSOCodeByEmail_Response_Handling_V15_NotFound() async throws {
        // Given
        let networkService = MockNetworkServiceProtocol.withError(statusCode: .notFound)

        let sut = AuthenticationAPIV15(networkService: networkService)

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.ssoCodeNotFound) {
            // When
            try await sut.getSSOCode(forEmail: Scaffolding.email)
        }
    }

}

private enum Scaffolding {

    static let email = "john.smith@example.com"
    static let wrongAddress = "john.smith-example.com"
    static let name = "John Smith"
    static let emailCode = "555666"
    static let password = "abcd"

}
