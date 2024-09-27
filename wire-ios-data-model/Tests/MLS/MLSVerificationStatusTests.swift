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

final class MLSVerificationStatusTests: XCTestCase {
    typealias SUT = MLSVerificationStatus

    /// Ensures that the raw values, which are persited to the database, don't change, once the app has been published.
    func testRawValuesHaveNotChanged() {
        XCTAssertEqual(SUT.notVerified.rawValue, 1)
        XCTAssertEqual(SUT.verified.rawValue, 2)
        XCTAssertEqual(SUT.degraded.rawValue, 3)
    }
}
