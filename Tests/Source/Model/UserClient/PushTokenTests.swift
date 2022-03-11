//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class PushTokenTests: XCTestCase {

    struct MockOldPushToken: Encodable {
        public let deviceToken: Data
        public let appIdentifier: String
        public let transportType: String
        public var isRegistered: Bool
        public var isMarkedForDeletion: Bool
        public var isMarkedForDownload: Bool
    }

    var sut: PushToken!

    override func setUp() {
        sut = PushToken(deviceToken: Data([0x01, 0x02, 0x03]), appIdentifier: "some", transportType: "some", tokenType: .standard, isRegistered: true)

        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatTokenIsEncodedProperly() {
        XCTAssertEqual(sut.deviceTokenString, "010203")
    }

    func testThatItReturnsCopyMarkedForDownload() {
        let toDownload = sut.markToDownload()
        XCTAssertFalse(sut.isMarkedForDownload)
        XCTAssertTrue(toDownload.isMarkedForDownload)
    }

    func testThatItReturnsCopyMarkedForDelete() {
        let toDelete = sut.markToDelete()
        XCTAssertFalse(sut.isMarkedForDeletion)
        XCTAssertTrue(toDelete.isMarkedForDeletion)
    }

    func testThatItResetsFlags() {
        let toDelete = sut.markToDelete()
        let toDownload = toDelete.markToDownload()
        let reset = toDownload.resetFlags()

        XCTAssertTrue(toDelete.isMarkedForDeletion)
        XCTAssertFalse(toDelete.isMarkedForDownload)

        XCTAssertTrue(toDownload.isMarkedForDownload)
        XCTAssertTrue(toDownload.isMarkedForDownload)

        XCTAssertFalse(reset.isMarkedForDownload)
        XCTAssertFalse(reset.isMarkedForDownload)
    }

    func testThatItDecodesAPushTokenWithEmptyTokenType() throws {
        // given
        let mockPushToken = MockOldPushToken(deviceToken: Data([0x01, 0x02, 0x03]),
                                             appIdentifier: "com.wire.zclient",
                                             transportType: "APNS_VOIP",
                                             isRegistered: true,
                                             isMarkedForDeletion: false,
                                             isMarkedForDownload: false)

        guard let pushTokenData = try? JSONEncoder().encode(mockPushToken) else {
            return XCTFail("The push token data cannot be encoded.")
        }

        // when
        guard let decodedPushToken = try? JSONDecoder().decode(PushToken.self, from: pushTokenData) else {
            return XCTFail("The push token data cannot be decoded.")
        }

        // then
        let expectedPushToken = PushToken(deviceToken: Data([0x01, 0x02, 0x03]),
                                          appIdentifier: "com.wire.zclient",
                                          transportType: "APNS_VOIP",
                                          tokenType: .voip,
                                          isRegistered: true)

        XCTAssertEqual(decodedPushToken, expectedPushToken)
    }

    func testThatItDecodesPushTokenWithVoipTokenType() throws {
        // given
        let mockPushToken = PushToken(deviceToken: Data([0x01, 0x02, 0x03]),
                                      appIdentifier: "com.wire.zclient",
                                      transportType: "APNS_VOIP",
                                      tokenType: .voip,
                                      isRegistered: true)

        guard let pushTokenData = try? JSONEncoder().encode(mockPushToken) else {
            return XCTFail("The push token data cannot be encoded.")
        }

        // when
        guard let decodedPushToken = try? JSONDecoder().decode(PushToken.self, from: pushTokenData) else {
            return XCTFail("The push token data cannot be decoded.")
        }

        // then
        let expectedPushToken = PushToken(deviceToken: Data([0x01, 0x02, 0x03]),
                                          appIdentifier: "com.wire.zclient",
                                          transportType: "APNS_VOIP",
                                          tokenType: .voip,
                                          isRegistered: true)

        XCTAssertEqual(decodedPushToken, expectedPushToken)
    }

    func testThatItDecodesPushTokenWithStandardTokenType() throws {
        // given
        let mockPushToken = PushToken(deviceToken: Data([0x01, 0x02, 0x03]),
                                      appIdentifier: "com.wire.zclient",
                                      transportType: "APNS",
                                      tokenType: .standard,
                                      isRegistered: true)

        guard let pushTokenData = try? JSONEncoder().encode(mockPushToken) else {
            return XCTFail("The push token data cannot be encoded.")
        }

        // when
        guard let decodedPushToken = try? JSONDecoder().decode(PushToken.self, from: pushTokenData) else {
            return XCTFail("The push token data cannot be decoded.")
        }

        // then
        let expectedPushToken = PushToken(deviceToken: Data([0x01, 0x02, 0x03]),
                                          appIdentifier: "com.wire.zclient",
                                          transportType: "APNS",
                                          tokenType: .standard,
                                          isRegistered: true)

        XCTAssertEqual(decodedPushToken, expectedPushToken)
    }
}
