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

import SnapshotTesting
@testable import WireAPI
import XCTest

final class UpdateEventsAPITests: XCTestCase {

    // MARK: - Request generation

    func testGetLastUpdateEvent() async throws {
        let snapshotter = APISnapshotHelper { httpClient, apiVersion in
            UpdateEventsAPIBuilder(httpClient: httpClient)
                .makeAPI(for: apiVersion)
        }

        try await snapshotter.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetLastUpdateEvent_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: 200,
            payloadResourceName: "GetLastEventSuccessResponseV0"
        )

        let sut = UpdateEventsAPIV0(httpClient: httpClient)

        // When
        let result = try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)

        // Then
        XCTAssertEqual(result, Scaffolding.updateEventEnvelope)
    }

    func testGetLastUpdateEvent_400_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 400, errorLabel: "")
        let sut = UpdateEventsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(UpdateEventsAPIError.invalidClient) {
            // When
            try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)
        }
    }

    func testGetLastUpdateEvent_404_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 404, errorLabel: "not-found")
        let sut = UpdateEventsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(UpdateEventsAPIError.notFound) {
            // When
            try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)
        }
    }

    // MARK: - V5

    func testGetLastUpdateEvent_200_V5() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: 200,
            payloadResourceName: "GetLastEventSuccessResponseV5"
        )

        let sut = UpdateEventsAPIV5(httpClient: httpClient)

        // When
        let result = try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)

        // Then
        XCTAssertEqual(result, Scaffolding.updateEventEnvelope)
    }

    func testGetLastUpdateEvent_404_V5() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: 404, errorLabel: "not-found")
        let sut = UpdateEventsAPIV5(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(UpdateEventsAPIError.notFound) {
            // When
            try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)
        }
    }

    // MARK: - Helpers

    struct Scaffolding {

        static let selfClientID = "abcd1234"
        static let eventID = UUID(uuidString: "d7f7f946-c4da-4300-998d-5aeba8affeee")!

        static let updateEventEnvelope = UpdateEventEnvelope(
            id: eventID,
            payloads: [.conversation(.create)],
            isTransient: false
        )

    }

}
