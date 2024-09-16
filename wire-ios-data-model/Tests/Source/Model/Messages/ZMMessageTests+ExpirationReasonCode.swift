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

    func testThatInitialExpirationReasonCodeIsNil() throws {
        XCTExpectFailure("Remove this line when fixing [WPB-10865]")

        // given
        let message = try makeMessage()

        // when
        XCTAssertNil(message.expirationReasonCode)
    }

    func testThatExpirationReasonCodeIsNotNil_DeliveryStateIsFailedToSend() throws {
        // given
        let message = try makeMessage()

        // when
        message.expire(withReason: .other)

        // then
        XCTAssertEqual(message.deliveryState, ZMDeliveryState.failedToSend)
        XCTAssertTrue(message.isExpired)
        XCTAssertEqual(message.expirationReasonCode, 0)
    }

    func testThatExpirationReasonCodeIsNil_DeliveryStateIsSent() throws {
        // given
        let message = try makeMessage()

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

    func testThatExpirationReasonsHaveTheCorrectRawValues() {
        XCTAssertEqual(ExpirationReason.other.rawValue, 0)
        XCTAssertEqual(ExpirationReason.federationRemoteError.rawValue, 1)
        XCTAssertEqual(ExpirationReason.cancelled.rawValue, 2)
        XCTAssertEqual(ExpirationReason.timeout.rawValue, 3)
    }

    func testExpirationReasonReturnsNilWhenIsExpiredIsFalse() throws {
        // given
        let message = try makeMessage()
        message.expirationReasonCode = NSNumber(value: ExpirationReason.other.rawValue)
        XCTAssertFalse(message.isExpired)

        // then
        XCTAssertNil(message.expirationReason)
    }

    func testExpirationReasonIsCorrectAfterExpiring() throws {
        // given
        let testCases: [ExpirationReason] = [
            .other,
            .federationRemoteError,
            .cancelled,
            .timeout
        ]

        for reason in testCases {
            let message = try makeMessage()

            // when
            message.expire(withReason: reason)

            // then
            XCTAssertEqual(
                message.expirationReason?.rawValue,
                reason.rawValue,
                "Test case failed - when reason is <\(reason)>"
            )
        }
    }

    func testExpirationReasonIsNotOverwrittenWhenExpiredMultipleTimes() throws {
        // given
        let message = try makeMessage()

        // when
        message.expire(withReason: .cancelled)
        message.expire(withReason: .timeout)

        // then
        XCTAssertEqual(message.expirationReason, .cancelled)
    }

    // MARK: Helpers

    private func makeMessage() throws -> ZMOTRMessage {
        let message = try XCTUnwrap(try conversation.appendText(content: "Hallo") as? ZMOTRMessage)
        message.serverTimestamp = Date.init(timeIntervalSinceNow: -20)
        return message
    }

}
