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

@testable import WireRequestStrategy
import XCTest

final class PayloadUpdateConversationProtocolChangeTests: XCTestCase {

    func testEventType() throws {
        // given
        // when
        let eventType = Payload.UpdateConversationProtocolChange.eventType

        // then
        XCTAssertEqual(eventType, .conversationProtocolUpdate)
    }

    func testDecodableFails() throws {
        // given
        let decoder = JSONDecoder()

        // when
        // then
        XCTAssertThrowsError(try decoder.decode(
            Payload.UpdateConversationProtocolChange.self,
            from: Data()
        ))
    }

    func testDecodableSucceeds() throws {
        // given
        let jsonDecoder = JSONDecoder()

        // when
        let payload = try jsonDecoder.decode(
            Payload.UpdateConversationProtocolChange.self,
            from: jsonData
        )

        // then
        XCTAssertEqual(payload.messageProtocol, "mockProtocol")
    }
}

private let jsonData = Data("""
{
    "protocol": "mockProtocol"
}
""".utf8)
