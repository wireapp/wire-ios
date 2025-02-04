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

    // MARK: - Response handling

    func testGetDomainRegistration_Response_Handling_V8_Success() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetDomainRegistrationSuccessResponse")
        ])

        let sut = AuthenticationAPIV8(apiService: apiService)

        // When
        let response = try await sut.getDomainRegistration(forEmail: "email@example.com")

        // Then
        XCTAssertEqual(response, DomainRegistrationConfiguration(
            backendUrl: "https://example.com",
            domainRedirect: .none,
            dueToExistingAccount: false,
            ssoCode: "99db9768-04e3-4b5d-9268-831b6a25c4ab")
        )
    }

    func testGetDomainRegistration_Response_Handling_V8_Invalid_Domain() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.badRequest, "GetDomainRegistrationErrorResponse_InvalidDomain")
        ])

        let sut = AuthenticationAPIV8(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationAPIError.invalidDomain) {
            // When
            try await sut.getDomainRegistration(forEmail: "email@example.com")
        }
    }

}
