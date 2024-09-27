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

final class FederationEventDecodingTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        decoder = .init()
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    func testDecodingFederationConnectionRemovedEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "FederationConnectionRemoved")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .federation(.connectionRemoved(Scaffolding.connectionRemovedEvent))
        )
    }

    func testDecodingFederationDeleteEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "FederationDelete")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .federation(.delete(Scaffolding.deleteEvent))
        )
    }

    // MARK: Private

    private enum Scaffolding {
        static let connectionRemovedEvent = FederationConnectionRemovedEvent(
            domains: [
                "a.com",
                "b.com",
            ]
        )

        static let deleteEvent = FederationDeleteEvent(domain: "foo.com")
    }

    private var decoder: JSONDecoder!
}
