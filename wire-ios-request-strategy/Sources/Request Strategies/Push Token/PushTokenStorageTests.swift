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

import WireSystem
import XCTest
@testable import WireRequestStrategy

final class PushTokenStorageTests: MessagingTestBase {
    private let userDefaultsSuiteName = "PushTokenStorageTests"

    // MARK: - Set up

    override func setUp() {
        super.setUp()
        PushTokenStorage.storage = UserDefaults(suiteName: userDefaultsSuiteName)!
        PushTokenStorage.pushToken = nil
    }

    override func tearDown() {
        PushTokenStorage.pushToken = nil
        PushTokenStorage.storage.removePersistentDomain(forName: userDefaultsSuiteName)
        super.tearDown()
    }

    // MARK: - Tests

    func testPushToken() {
        // Given
        let deviceToken = Data(repeating: 0x41, count: 10)
        let pushToken = PushToken(
            deviceToken: deviceToken,
            appIdentifier: "com.wire",
            transportType: "APNS_VOIP",
            tokenType: .voip
        )
        XCTAssertNil(PushTokenStorage.pushToken)

        // When
        PushTokenStorage.pushToken = pushToken

        // Then
        XCTAssertEqual(PushTokenStorage.pushToken, pushToken)
    }
}
