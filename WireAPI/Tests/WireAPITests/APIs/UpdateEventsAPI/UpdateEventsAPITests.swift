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

@testable import WireAPI
@testable import WireAPISupport
import XCTest

final class UpdateEventsAPITests: XCTestCase {

    private func createSnapshotter() -> APIServiceSnapshotHelper<any UpdateEventsAPI> {
        APIServiceSnapshotHelper { apiService, apiVersion in
            UpdateEventsAPIBuilder(apiService: apiService)
                .makeAPI(for: apiVersion)
        }
    }

    // MARK: - Request generation

    func testGetLastUpdateEvent() async throws {
        try await createSnapshotter().verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)
        }
    }

    func testGetUpdateEvents() async throws {
        // Then
        try await createSnapshotter().verifyRequestForAllAPIVersions {
            // Given
            .withResponses([
                (.ok, "GetUpdateEventsSuccessResponse200_Page1"),
                (.ok, "GetUpdateEventsSuccessResponse200_Page2")
            ])
        } when: { sut in
            for try await _ in sut.getUpdateEvents(
                selfClientID: Scaffolding.selfClientID,
                sinceEventID: Scaffolding.lastUpdateEventID
            ) {
                // Nothing to assert here since we're only snapshotting request.
            }
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetLastUpdateEvent_200_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetLastEventSuccessResponseV0")
        ])

        let sut = UpdateEventsAPIV0(apiService: apiService)

        // When
        let result = try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)

        // Then
        XCTAssertEqual(result, Scaffolding.updateEventEnvelope)
    }

    func testGetLastUpdateEvent_400_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(statusCode: .badRequest)
        let sut = UpdateEventsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsError(UpdateEventsAPIError.invalidClient) {
            // When
            try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)
        }
    }

    func testGetLastUpdateEvent_404_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "not-found"
        )

        let sut = UpdateEventsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsError(UpdateEventsAPIError.notFound) {
            // When
            try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)
        }
    }

    func testGetUpdateEvents_200_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetUpdateEventsSuccessResponse200_Page1"),
            (.ok, "GetUpdateEventsSuccessResponse200_Page2")
        ])

        let sut = UpdateEventsAPIV0(apiService: apiService)

        // When
        var pages = [[UpdateEventEnvelope]]()
        for try await page in sut.getUpdateEvents(
            selfClientID: Scaffolding.selfClientID,
            sinceEventID: Scaffolding.lastUpdateEventID
        ) {
            pages.append(page)
        }

        // Then
        XCTAssertEqual(pages.count, 2)

        let page1 = try XCTUnwrap(pages.first)
        XCTAssertEqual(page1, Scaffolding.updateEventPage1)

        let page2 = try XCTUnwrap(pages.last)
        XCTAssertEqual(page2, Scaffolding.updateEventPage2)
    }

    func testGetUpdateEvents_400_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(statusCode: .badRequest)
        let sut = UpdateEventsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsError(UpdateEventsAPIError.invalidParameters) {
            // When
            for try await _ in sut.getUpdateEvents(
                selfClientID: Scaffolding.selfClientID,
                sinceEventID: Scaffolding.lastUpdateEventID
            ) {
                // no op
            }
        }
    }

    func testGetUpdateEvents_404_V0() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(statusCode: .notFound)
        let sut = UpdateEventsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsError(UpdateEventsAPIError.notFound) {
            // When
            for try await _ in sut.getUpdateEvents(
                selfClientID: Scaffolding.selfClientID,
                sinceEventID: Scaffolding.lastUpdateEventID
            ) {
                // no op
            }
        }
    }

    // MARK: - V5

    func testGetLastUpdateEvent_200_V5() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetLastEventSuccessResponseV5")
        ])

        let sut = UpdateEventsAPIV5(apiService: apiService)

        // When
        let result = try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)

        // Then
        XCTAssertEqual(result, Scaffolding.updateEventEnvelope)
    }

    func testGetLastUpdateEvent_404_V5() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "not-found"
        )

        let sut = UpdateEventsAPIV5(apiService: apiService)

        // Then
        await XCTAssertThrowsError(UpdateEventsAPIError.notFound) {
            // When
            try await sut.getLastUpdateEvent(selfClientID: Scaffolding.selfClientID)
        }
    }

    func testGetUpdateEvents_200_V5() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetUpdateEventsSuccessResponse200_Page1"),
            (.ok, "GetUpdateEventsSuccessResponse200_Page2")
        ])

        let sut = UpdateEventsAPIV5(apiService: apiService)

        // When
        var pages = [[UpdateEventEnvelope]]()
        for try await page in sut.getUpdateEvents(
            selfClientID: Scaffolding.selfClientID,
            sinceEventID: Scaffolding.lastUpdateEventID
        ) {
            pages.append(page)
        }

        // Then
        XCTAssertEqual(pages.count, 2)

        let page1 = try XCTUnwrap(pages.first)
        XCTAssertEqual(page1, Scaffolding.updateEventPage1)

        let page2 = try XCTUnwrap(pages.last)
        XCTAssertEqual(page2, Scaffolding.updateEventPage2)
    }

    func testGetUpdateEvents_404_V5() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(statusCode: .notFound)
        let sut = UpdateEventsAPIV5(apiService: apiService)

        // Then
        await XCTAssertThrowsError(UpdateEventsAPIError.notFound) {
            // When
            for try await _ in sut.getUpdateEvents(
                selfClientID: Scaffolding.selfClientID,
                sinceEventID: Scaffolding.lastUpdateEventID
            ) {
                // no op
            }
        }
    }

    // MARK: - Helpers

    enum Scaffolding {

        static let selfClientID = "abcd1234"
        static let eventID = UUID(uuidString: "d7f7f946-c4da-4300-998d-5aeba8affeee")!
        static let lastUpdateEventID = UUID(uuidString: "d7f7f946-c4da-4300-998d-5aeba8affeee")!

        static let updateEventEnvelope = UpdateEventEnvelope(
            id: eventID,
            events: [.user(.pushRemove)],
            isTransient: false
        )

        static let updateEventPage1 = [
            UpdateEventEnvelope(
                id: UUID(uuidString: "2eeeb5e4-df85-4aef-9eb2-289981f086ab")!,
                events: [.unknown(eventType: "some event")],
                isTransient: false
            ),
            UpdateEventEnvelope(
                id: UUID(uuidString: "688ad9fc-6906-4dd6-9ccc-db8d849c41ad")!,
                events: [.unknown(eventType: "some transient event")],
                isTransient: true
            )
        ]

        static let updateEventPage2 = [
            UpdateEventEnvelope(
                id: UUID(uuidString: "0b08693f-4f67-46e1-9e5e-f7c15f3e8157")!,
                events: [.unknown(eventType: "some transient event")],
                isTransient: true
            ),
            UpdateEventEnvelope(
                id: UUID(uuidString: "7ed84e3d-108c-4d50-904e-78a4e6908956")!,
                events: [.unknown(eventType: "some event")],
                isTransient: false
            )
        ]

    }

}
