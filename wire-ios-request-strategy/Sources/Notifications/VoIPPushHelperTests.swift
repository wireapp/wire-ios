//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Foundation
import WireSystem
import XCTest

@testable import WireRequestStrategy

final class VoIPPushHelperTests: XCTestCase {

    private let userDefaultsSuiteName = "VoIPPushHelperTests"

    // MARK: - Set up

    override func setUp() {
        super.setUp()
        VoIPPushHelper.storage = UserDefaults(suiteName: userDefaultsSuiteName)!
    }

    override func tearDown() {
        VoIPPushHelper.storage.removePersistentDomain(forName: userDefaultsSuiteName)
        super.tearDown()
    }

    // MARK: - Tests

    func testIsCallKitAvailable() {
        // Given
        XCTAssertFalse(VoIPPushHelper.isCallKitAvailable)

        // When
        VoIPPushHelper.isCallKitAvailable = true

        // Then
        XCTAssertTrue(VoIPPushHelper.isCallKitAvailable)
    }

    func testIsAVSReady() {
        // Given
        VoIPPushHelper.isAVSReady = false
        XCTAssertFalse(VoIPPushHelper.isAVSReady)

        // When
        VoIPPushHelper.isAVSReady = true

        // Then
        XCTAssertTrue(VoIPPushHelper.isAVSReady)
    }

}
