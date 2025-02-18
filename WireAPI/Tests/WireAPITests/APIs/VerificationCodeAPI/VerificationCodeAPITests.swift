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

final class VerificationCodeAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any VerificationCodeAPI>!

    // MARK: - Setup

    override func setUp() {
        apiSnapshotHelper = APIServiceSnapshotHelper<any VerificationCodeAPI> { apiService, apiVersion in
            VerificationCodeAPIBuilder(apiService: apiService)
                .makeAPI(for: apiVersion)

        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
    }

    // MARK: - Request generation

    func testRequestVerificationCode_V0_To_V7() async throws {
        // Given
        let apiService = MockAPIServiceProtocol()
        let builder = VerificationCodeAPIBuilder(apiService: apiService)
        let apiVersions = APIVersion.allCasesUpTo(.v8)

        for apiVersion in apiVersions {
            let sut = builder.makeAPI(for: apiVersion)

            // Then
            await XCTAssertThrowsErrorAsync(VerificationCodeAPIError.unsupportedEndpointForAPIVersion) {
                try await sut.requestVerificationCode(for: Scaffolding.email)
            }
        }
    }

    func testRequestVerificationCode_Request_Generation_V8_Onwards() async throws {
        // Given
        let apiVersions = APIVersion.v8.andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            // When
            _ = try await sut.requestVerificationCode(for: Scaffolding.email)
        }
    }

    // MARK: - Response handling

    func testRequestVerificationCode_Response_Handling_V8_Success() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "RequestVerificationCodeResponse_Success")
        ])

        let sut = VerificationCodeAPIV8(apiService: apiService)

        // When, Then no error thrown
        try await sut.requestVerificationCode(for: Scaffolding.email)
    }

    func testUpgradeToTeam_Response_Handling_V8_UnsupportedVersion() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.notFound, "RequestVerificationCodeResponse_UnsupportedVersion")
        ])

        let sut = VerificationCodeAPIV8(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(VerificationCodeAPIError.invalidEmail) {
            // When
            try await sut.requestVerificationCode(for: Scaffolding.email)
        }
    }

}

private enum Scaffolding {

    static let email = "john.smith@example.com"

}
