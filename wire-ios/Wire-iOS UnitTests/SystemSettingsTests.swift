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
@testable import Wire

final class SystemSettingsTests: XCTestCase {
    func test_internalBuild() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "Settings.bundle/Root", withExtension: "plist"))
        let data = try Data(contentsOf: url)
        let string = try XCTUnwrap(String(decoding: data, as: UTF8.self))

        XCTAssertTrue(string.contains("DEVELOPER SETTINGS"))
        XCTAssertTrue(string.contains("LICENSES"))
    }

    func test_productionBuild() {
        // unit tests are always performed in internal builds,
        // so we cannot assert production behavior.
    }
}
