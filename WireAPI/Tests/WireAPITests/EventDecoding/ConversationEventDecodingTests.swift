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

final class ConversationEventDecodingTests: XCTestCase {

    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = .defaultDecoder
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    func testDecodingConversationAccessUpdateEvent() throws {
        // Given
        let mockEventData = try MockEventDataResource(name: "ConversationAccessUpdate")

        // When
        let decodedEvent = try decoder.decode(UpdateEvent.self, from: mockEventData.jsonData)

        // Then
        XCTAssertEqual(
            decodedEvent,
            .conversation(.accessUpdate(Scaffolding.accessUpdateEvent))
        )
    }

    private enum Scaffolding {

        static let accessUpdateEvent = ConversationAccessUpdateEvent(
            conversationID: ConversationID(
                uuid: UUID(uuidString: "a644fa88-2d83-406b-8a85-d4fd8dedad6b")!,
                domain: "example.com"
            ),
            senderID: UserID(
                uuid: UUID(uuidString: "f55fe9b0-a0cc-4b11-944b-125c834d9b6a")!,
                domain: "example.com"
            ),
            accessModes: [
                .private, .invite, .link, .code
            ],
            accessRoles: [
                .teamMember, .nonTeamMember, .guest, .service
            ],
            legacyAccessRole: .nonActivated
        )

    }

}
