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

import UIKit
import XCTest

@testable public import WireFoundation

@MainActor
final class DeviceAbstractionMockTests: XCTestCase {

    func testMockReturnsConfiguredValues() {
        // Given
        let sut = DeviceAbstractionMock()
        sut.underlyingUserInterfaceIdiom = .pad
        sut.underlyingOrientation = .landscapeLeft
        sut.underlyingModel = "iPad13,1"

        // Then
        XCTAssertEqual(sut.userInterfaceIdiom, .pad)
        XCTAssertEqual(sut.orientation, .landscapeLeft)
        XCTAssertEqual(sut.model, "iPad13,1")
    }

    func testMockCanBeUsedThroughProtocol() {
        // Given
        let mock = DeviceAbstractionMock()
        mock.underlyingModel = "iPhone15,2"
        let sut: any DeviceAbstraction = mock

        // Then
        XCTAssertEqual(sut.model, "iPhone15,2")
    }
}
