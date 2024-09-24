//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

final class UserPropertiesAPITests: XCTestCase {

    private var apiSnapshotHelper: APISnapshotHelper<any UserPropertiesAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APISnapshotHelper { httpClient, apiVersion in
            let builder = UserPropertiesBuilder(httpClient: httpClient)
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

    func testGetUserReceiptModeProperty_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetUserReceiptModePropertySuccessResponseV0"
        )

        let sut = UserPropertiesAPIV0(httpClient: httpClient)

        // When
        let result = try await sut.areReadReceiptsEnabled

        // Then
        XCTAssertEqual(
            result,
            true
        )
    }

    func testGetUserTypingIndicatorModeProperty_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetUserTypingIndicatorModePropertySuccessResponseV0"
        )

        let sut = UserPropertiesAPIV0(httpClient: httpClient)

        // When
        let result = try await sut.areTypingIndicatorsEnabled

        // Then
        XCTAssertEqual(
            result,
            false
        )
    }

    func testGetUserLabelsProperty_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetUserLabelsPropertySuccessResponseV0"
        )

        let sut = UserPropertiesAPIV0(httpClient: httpClient)

        // When
        let labels = try await sut.getLabels()

        // Then
        XCTAssertEqual(labels.count, 2)
        XCTAssertEqual(labels[0].name, "Foo")
        XCTAssertEqual(labels[1].name, nil)
    }

    func testGetLabels_FailureResponse_PropertyNotFound_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "")
        let sut = UserPropertiesAPIV4(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(UserPropertiesAPIError.propertyNotFound) {
            // When
            _ = try await sut.getLabels()
        }
    }

    func testGetUserTypingIndicatorModeProperty_FailureResponse_PropertyNotFound_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "")
        let sut = UserPropertiesAPIV4(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(UserPropertiesAPIError.propertyNotFound) {
            // When
            _ = try await sut.areTypingIndicatorsEnabled
        }
    }

    func testGetUserReceiptModeProperty_FailureResponse_PropertyNotFound_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "")
        let sut = UserPropertiesAPIV4(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(UserPropertiesAPIError.propertyNotFound) {
            // When
            _ = try await sut.areReadReceiptsEnabled
        }
    }

    // MARK: - V4

    func testGetUserProperties_FailureResponse_InvalidKey_V4() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .badRequest, errorLabel: "")
        let sut = UserPropertiesAPIV4(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(UserPropertiesAPIError.invalidKey) {
            // When
            try await sut.getLabels()
        }
    }
}
