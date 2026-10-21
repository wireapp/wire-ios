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

import WireUtilities
import XCTest

final class DeveloperFlagTests: XCTestCase {

    func testOfflinePendingMessagesDefaultsOffAndSupportsExplicitValues() throws {
        let suiteName = UUID().uuidString
        let storage = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let previousStorage = DeveloperFlag.storage
        DeveloperFlag.storage = storage
        defer {
            DeveloperFlag.storage = previousStorage
            storage.removePersistentDomain(forName: suiteName)
        }

        XCTAssertFalse(DeveloperFlag.offlinePendingMessages.isOn)
        DeveloperFlag.offlinePendingMessages.enable(true)
        XCTAssertTrue(DeveloperFlag.offlinePendingMessages.isOn)
        DeveloperFlag.offlinePendingMessages.enable(false)
        XCTAssertFalse(DeveloperFlag.offlinePendingMessages.isOn)

        DeveloperFlag.offlinePendingMessages.enable(true)
        DeveloperFlag.clearAllFlags()
        XCTAssertFalse(DeveloperFlag.offlinePendingMessages.isOn)
    }
}
