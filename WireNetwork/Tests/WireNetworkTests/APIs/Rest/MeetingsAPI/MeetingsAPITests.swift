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

final class MeetingsAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any MeetingsAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = MeetingsAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func testCreateMeeting_Request_Generation_V15() async throws {
        let apiService = MockAPIServiceProtocol.withResponses([(.created, "MeetingResponse")])

        try await apiSnapshotHelper.verifyRequest(for: [.v15], apiService: apiService) { sut in
            _ = try await sut.createMeeting(parameters: Scaffolding.createParameters)
        }
    }

    func testUpdateMeeting_Request_Generation_V15() async throws {
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, "MeetingResponse")])

        try await apiSnapshotHelper.verifyRequest(for: [.v15], apiService: apiService) { sut in
            _ = try await sut.updateMeeting(meetingID: Scaffolding.meetingID, parameters: Scaffolding.updateParameters)
        }
    }

    func testDeleteMeeting_Request_Generation_V16() async throws {
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, nil)])

        try await apiSnapshotHelper.verifyRequest(for: [.v16], apiService: apiService) { sut in
            try await sut.deleteMeeting(meetingID: Scaffolding.meetingID)
        }
    }

    // MARK: - createMeeting V15+

    func testCreateMeeting_SuccessResponse_201_V15() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([(.created, "MeetingResponse")])
        let sut = APIVersion.v15.buildAPI(apiService: apiService)

        // When
        let result = try await sut.createMeeting(parameters: Scaffolding.createParameters)

        // Then
        XCTAssertEqual(result.id, Scaffolding.meetingID)
        XCTAssertEqual(result.title, "Engineering Sync")
    }

    func testCreateMeeting_ThrowsUnsupportedEndpoint_V0_to_V14() async throws {
        let unsupportedVersions = APIVersion.allCasesUpTo(.v14)

        for version in unsupportedVersions {
            // Given
            let apiService = MockAPIServiceProtocol()
            let sut = version.buildAPI(apiService: apiService)

            // When / Then
            await XCTAssertThrowsErrorAsync(MeetingsAPIError.unsupportedEndpointForAPIVersion) {
                _ = try await sut.createMeeting(parameters: Scaffolding.createParameters)
            }
        }
    }

    func testCreateMeeting_ThrowsInvalidOperation_403_V15() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "invalid-op"
        )
        let sut = APIVersion.v15.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.invalidOperation) {
            _ = try await sut.createMeeting(parameters: Scaffolding.createParameters)
        }
    }

    func testCreateMeeting_ThrowsUnreachableBackends_533_V15() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(statusCode: .unreachable)
        let sut = APIVersion.v15.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.unreachableBackends) {
            _ = try await sut.createMeeting(parameters: Scaffolding.createParameters)
        }
    }

    // MARK: - updateMeeting V15+

    func testUpdateMeeting_SuccessResponse_200_V15() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, "MeetingResponse")])
        let sut = APIVersion.v15.buildAPI(apiService: apiService)

        // When
        let result = try await sut.updateMeeting(meetingID: Scaffolding.meetingID, parameters: Scaffolding.updateParameters)

        // Then
        XCTAssertEqual(result.id, Scaffolding.meetingID)
        XCTAssertEqual(result.title, "Engineering Sync")
    }

    func testUpdateMeeting_ThrowsUnsupportedEndpoint_V0_to_V14() async throws {
        let unsupportedVersions = APIVersion.allCasesUpTo(.v14)

        for version in unsupportedVersions {
            // Given
            let apiService = MockAPIServiceProtocol()
            let sut = version.buildAPI(apiService: apiService)

            // When / Then
            await XCTAssertThrowsErrorAsync(MeetingsAPIError.unsupportedEndpointForAPIVersion) {
                _ = try await sut.updateMeeting(meetingID: Scaffolding.meetingID, parameters: Scaffolding.updateParameters)
            }
        }
    }

    func testUpdateMeeting_ThrowsInvalidOperation_403_V15() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "invalid-op"
        )
        let sut = APIVersion.v15.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.invalidOperation) {
            _ = try await sut.updateMeeting(meetingID: Scaffolding.meetingID, parameters: Scaffolding.updateParameters)
        }
    }

    func testUpdateMeeting_ThrowsAccessDenied_403_V15() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "access-denied"
        )
        let sut = APIVersion.v15.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.accessDenied) {
            _ = try await sut.updateMeeting(meetingID: Scaffolding.meetingID, parameters: Scaffolding.updateParameters)
        }
    }

    func testUpdateMeeting_ThrowsMeetingNotFound_404_V15() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "meeting-not-found"
        )
        let sut = APIVersion.v15.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.meetingNotFound) {
            _ = try await sut.updateMeeting(meetingID: Scaffolding.meetingID, parameters: Scaffolding.updateParameters)
        }
    }

    // MARK: - deleteMeeting V16

    func testDeleteMeeting_SuccessResponse_200_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([(.ok, nil)])
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then - no throw expected
        try await sut.deleteMeeting(meetingID: Scaffolding.meetingID)
    }

    func testDeleteMeeting_ThrowsUnsupportedEndpoint_V0_to_V15() async throws {
        let unsupportedVersions = APIVersion.allCasesUpTo(.v15)

        for version in unsupportedVersions {
            // Given
            let apiService = MockAPIServiceProtocol()
            let sut = version.buildAPI(apiService: apiService)

            // When / Then
            await XCTAssertThrowsErrorAsync(MeetingsAPIError.unsupportedEndpointForAPIVersion) {
                try await sut.deleteMeeting(meetingID: Scaffolding.meetingID)
            }
        }
    }

    func testDeleteMeeting_ThrowsAccessDenied_403_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "access-denied"
        )
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.accessDenied) {
            try await sut.deleteMeeting(meetingID: Scaffolding.meetingID)
        }
    }

    func testDeleteMeeting_ThrowsMeetingNotFound_404_V16() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "meeting-not-found"
        )
        let sut = APIVersion.v16.buildAPI(apiService: apiService)

        // When / Then
        await XCTAssertThrowsErrorAsync(MeetingsAPIError.meetingNotFound) {
            try await sut.deleteMeeting(meetingID: Scaffolding.meetingID)
        }
    }

    // MARK: -

    enum Scaffolding {
        static let meetingID = QualifiedID(
            id: UUID(uuidString: "9c2e5e1a-1234-5678-abcd-0123456789ab")!,
            domain: "example.com"
        )
        static let createParameters = CreateMeetingParameters(
            title: "Engineering Sync",
            startTime: Date(timeIntervalSince1970: 1_750_845_600), // 2025-06-25T10:00:00Z
            endTime: Date(timeIntervalSince1970: 1_750_849_200)    // 2025-06-25T11:00:00Z
        )
        static let updateParameters = UpdateMeetingParameters(
            title: "Engineering Sync (Updated)",
            startTime: Date(timeIntervalSince1970: 1_750_845_600), // 2025-06-25T10:00:00Z
            endTime: Date(timeIntervalSince1970: 1_750_849_200)    // 2025-06-25T11:00:00Z
        )
    }

}

private extension APIVersion {
    func buildAPI(apiService: any APIServiceProtocol) -> any MeetingsAPI {
        let builder = MeetingsAPIBuilder(apiService: apiService)
        return builder.makeAPI(for: self)
    }
}
