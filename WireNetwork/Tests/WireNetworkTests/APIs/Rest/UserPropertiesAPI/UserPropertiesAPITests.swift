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

final class UserPropertiesAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any UserPropertiesAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = UserPropertiesAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func testGetLabelsRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getLabels()
        }
    }

    func testGetWireIndicatorModeRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.areTypingIndicatorsEnabled
        }
    }

    func testGetWireReceiptModeRequest() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.areReadReceiptsEnabled
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetUserReceiptModeProperty_SuccessResponse_200_V0_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetUserReceiptModePropertySuccessResponseV0")
        ])

        // Then
        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            // When
            let result = try await sut.areReadReceiptsEnabled

            // Then
            XCTAssertEqual(
                result,
                true
            )
        }
    }

    func testGetUserTypingIndicatorModeProperty_SuccessResponse_200_V0_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetUserTypingIndicatorModePropertySuccessResponseV0")
        ])

        // Then
        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            // When
            let result = try await sut.areTypingIndicatorsEnabled

            // Then
            XCTAssertEqual(
                result,
                false
            )
        }
    }

    func testGetUserLabelsProperty_SuccessResponse_200_V0_Then_Verify_Request() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetUserLabelsPropertySuccessResponseV0")
        ])

        // Then
        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            // When
            let labels = try await sut.getLabels()

            // Then
            XCTAssertEqual(labels.count, 2)
            XCTAssertEqual(labels[0].name, "Foo")
            XCTAssertEqual(labels[1].name, nil)
        }
    }

    func testGetLabels_FailureResponse_PropertyNotFound_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound
        )

        let sut = UserPropertiesAPIV4(apiService: apiService)

        // When
        let result = try await sut.getLabels()

        // Then
        XCTAssertEqual(result, [])
    }

    func testGetUserTypingIndicatorModeProperty_FailureResponse_PropertyNotFound_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound
        )

        let sut = UserPropertiesAPIV4(apiService: apiService)

        // When
        let result = try await sut.areTypingIndicatorsEnabled

        // Then
        XCTAssertFalse(result)
    }

    func testGetUserReceiptModeProperty_FailureResponse_PropertyNotFound_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound
        )

        let sut = UserPropertiesAPIV4(apiService: apiService)

        // When
        let result = try await sut.areReadReceiptsEnabled

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - V4

    func testGetUserProperties_FailureResponse_InvalidKey_V4() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest
        )

        let sut = UserPropertiesAPIV4(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(UserPropertiesAPIError.invalidKey) {
            // When
            try await sut.getLabels()
        }
    }
}
