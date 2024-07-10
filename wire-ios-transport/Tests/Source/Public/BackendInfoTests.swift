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

@_spi(MockBackendInfo)
import WireTransport
import XCTest

final class BackendInfoTests: XCTestCase {
    func testMocking() {
        // use property `apiVersion` as test example, but it works for the full storage.

        // given
        XCTAssertNil(BackendInfo.apiVersion)
        BackendInfo.apiVersion = .v1 // ⚠️ never do this in tests before `enableMocking()`!

        // when
        BackendInfo.enableMocking()
        XCTAssertNil(BackendInfo.apiVersion)

        BackendInfo.apiVersion = .v2
        XCTAssertEqual(BackendInfo.apiVersion, .v2)

        // then
        BackendInfo.resetMocking()
        XCTAssertEqual(BackendInfo.apiVersion, .v1)

        BackendInfo.apiVersion = nil // ⚠️ manual cleanup required
    }
}
