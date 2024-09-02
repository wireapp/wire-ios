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

@testable import WireDataModel
import XCTest

class ZMMessageTests_ExpirationReasonCode: BaseZMClientMessageTests {
    var message: ZMOTRMessage?

    override func setUp() {
        super.setUp()

        message = try? conversation.appendText(content: "Hallo") as? ZMOTRMessage
        message?.serverTimestamp = Date.init(timeIntervalSinceNow: -20)
    }

    override func tearDown() {
        message = nil

        super.tearDown()
    }

    func testThatExpirationReasonCodeIsNotNil_DeliveryStateIsFailedToSend() throws {
        // given
        let message = try XCTUnwrap(message)

        // when
        message.expire(withReason: .other)

        // then
        XCTAssertEqual(message.deliveryState, ZMDeliveryState.failedToSend)
        XCTAssertTrue(message.isExpired)
        XCTAssertEqual(message.expirationReasonCode, 0)
    }

    func testThatExpirationReasonCodeIsNil_DeliveryStateIsSent() throws {
        // given
        let message = try XCTUnwrap(message)

        // when
        message.expire(withReason: .other)
        XCTAssertEqual(message.deliveryState, ZMDeliveryState.failedToSend)
        XCTAssertTrue(message.isExpired)
        XCTAssertEqual(message.expirationReasonCode, 0)

        message.markAsSent()

        // then
        XCTAssertEqual(message.deliveryState, ZMDeliveryState.sent)
        XCTAssertFalse(message.isExpired)
        XCTAssertNil(message.expirationReasonCode)
    }

    func testExpirationReasonsParsing() throws {
        // given
        let message = try XCTUnwrap(message)

        // when
        message.expire(withReason: .other)

        // then
        assert(reasonCode: nil, expectedReason: nil)
        assert(reasonCode: 0, expectedReason: .other)
        assert(reasonCode: 1, expectedReason: .federationRemoteError)
    }

    // MARK: - Helper

    private func assert(reasonCode: NSNumber?, expectedReason: ExpirationReason?) {
        guard let message else {
            XCTFail("Failed to add message")
            return
        }
        message.expirationReasonCode = reasonCode

        XCTAssertTrue(message.isExpired)
        XCTAssertEqual(message.expirationReason, expectedReason)
    }

}
