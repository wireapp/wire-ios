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

import XCTest

@testable import WireAPI
@testable import WireAPISupport

final class AuthenticationAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any AuthenticationAPI>!

    // MARK: - Setup

    override func setUp() {
        apiSnapshotHelper = APIServiceSnapshotHelper<any AuthenticationAPI> { apiService, apiVersion in
            AuthenticationAPIBuilder(apiService: apiService)
                .makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
    }

    // MARK: - Request generation

    func testGetDomainRegistration_V0_To_V7() async throws {
        // Given
        let apiService = MockAPIServiceProtocol()
        let builder = AuthenticationAPIBuilder(apiService: apiService)

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
                verificationCode: nil,
                label: nil
            )
        }
    }

    // MARK: - Response handling

    func testGetDomainRegistration_Response_Handling_V8_Success() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetDomainRegistrationSuccessResponseV8")
        ])

        let sut = AuthenticationAPIV8(apiService: apiService)

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
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetDomainRegistrationSuccessResponse_WithNullValuesV8")
        ])

        let sut = AuthenticationAPIV8(apiService: apiService)

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
        let apiService = MockAPIServiceProtocol.withResponses([
            (.badRequest, "GetDomainRegistrationErrorResponse_InvalidDomainV8")
        ])

        let sut = AuthenticationAPIV8(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.invalidDomain) {
            // When
            try await sut.getDomainRegistration(forEmail: "email@example.com")
        }
    }

    func testGetOnPremConfigURL_Response_Handling_Success() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetOnPremConfigURLSuccessResponseV0")
        ])

        let sut = AuthenticationAPIV8(apiService: apiService)

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
        let apiService = MockAPIServiceProtocol.withResponses([
            (.notFound, "GetOnPremConfigURLErrorResponse_CustomBackendNotFound_V0")
        ])

        let sut = AuthenticationAPIV8(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.configNotFound) {
            // When
            try await sut.getOnPremConfigURL(forDomain: "example.com")
        }
    }

    func testLoginViaEmail_Response_Handling_Success() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "LoginViaEmailSuccessResponseV0")
        ])

        let sut = AuthenticationAPIV8(apiService: apiService)

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
        let apiService = MockAPIServiceProtocol.withResponses([
            (.notFound, "LoginViaEmailErrorResponse_CodeAuthenticationRequired_V0")
        ])

        let sut = AuthenticationAPIV8(apiService: apiService)

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

}
