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
import XCTest

final class FederationEventDecodingTests: XCTestCase {

    func testDecodingFederationConnectionRemovedEvent() async throws {
        // Given event data.
        let resource = try MockEventDataResource(name: "FederationConnectionRemoved")

        // When decode update event.
        let updateEvent = try JSONDecoder.defaultDecoder.decode(
            UpdateEvent.self,
            from: resource.jsonData
        )

        // Then it decoded the correct event.
        guard case .federation(.connectionRemoved(let payload)) = updateEvent else {
            return XCTFail("unexpected event: \(updateEvent)")
        }

        XCTAssertEqual(payload, Scaffolding.connectionRemovedEventPayload)
    }

    func testDecodingFederationDeleteEvent() async throws {
        // Given event data.
        let resource = try MockEventDataResource(name: "FederationDelete")

        // When decode update event.
        let updateEvent = try JSONDecoder.defaultDecoder.decode(
            UpdateEvent.self,
            from: resource.jsonData
        )

        // Then it decoded the correct event.
        guard case .federation(.delete(let payload)) = updateEvent else {
            return XCTFail("unexpected event: \(updateEvent)")
        }

        XCTAssertEqual(payload, Scaffolding.deleteEventPayload)
    }

    private enum Scaffolding {

        static let connectionRemovedEventPayload = FederationConnectionRemovedEvent(
            domains: [
                "a.com",
                "b.com"
            ]
        )

        static let deleteEventPayload = FederationDeleteEvent(domain: "foo.com")
    }

}
