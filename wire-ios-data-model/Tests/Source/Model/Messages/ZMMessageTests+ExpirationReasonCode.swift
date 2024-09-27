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
@testable import WireDataModel

class ZMMessageTests_ExpirationReasonCode: BaseZMClientMessageTests {
    // MARK: Internal

    var message: ZMOTRMessage?

    override func setUp() {
        super.setUp()

        message = try? conversation.appendText(content: "Hallo") as? ZMOTRMessage
        message?.serverTimestamp = Date(timeIntervalSinceNow: -20)
    }

    override func tearDown() {
        message = nil

        super.tearDown()
    }

    func testThatExpirationReasonCodeIsNotNil_DeliveryStateIsFailedToSend() {
        // given
        guard let message else {
            XCTFail("Failed to add message")
            return
        }

        // when
        message.expire()

        // then
        XCTAssertEqual(message.deliveryState, ZMDeliveryState.failedToSend)
        XCTAssertTrue(message.isExpired)
        XCTAssertEqual(message.expirationReasonCode, 0)
    }

    func testThatExpirationReasonCodeIsNil_DeliveryStateIsSent() {
        // given
        guard let message else {
            XCTFail("Failed to add message")
            return
        }

        // when
        message.expire()
        XCTAssertEqual(message.deliveryState, ZMDeliveryState.failedToSend)
        XCTAssertTrue(message.isExpired)
        XCTAssertEqual(message.expirationReasonCode, 0)

        message.markAsSent()

        // then
        XCTAssertEqual(message.deliveryState, ZMDeliveryState.sent)
        XCTAssertFalse(message.isExpired)
        XCTAssertNil(message.expirationReasonCode)
    }

    func testExpirationReasonsParsing() {
        // given
        guard let message else {
            XCTFail("Failed to add message")
            return
        }
        // when
        message.expire()

        // then
        assert(reasonCode: nil, expectedReason: nil)
        assert(reasonCode: 0, expectedReason: .unknown)
        assert(reasonCode: 1, expectedReason: .federationRemoteError)
    }

    // MARK: Private

    // MARK: - Helper

    private func assert(reasonCode: NSNumber?, expectedReason: MessageSendFailure?) {
        guard let message else {
            XCTFail("Failed to add message")
            return
        }
        message.expirationReasonCode = reasonCode

        XCTAssertTrue(message.isExpired)
        XCTAssertEqual(message.failedToSendReason, expectedReason)
    }
}
