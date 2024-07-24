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

import WireTestingPackage
import XCTest

@testable import WireReusableUIComponents

final class AvailabilityIndicatorViewSnapshotTests: XCTestCase {

    private var sut: AvailabilityIndicatorView!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        sut = .init(frame: .init(x: 0, y: 0, width: 20, height: 20))
        snapshotHelper = .init()
            .withSnapshotDirectory(relativeTo: #file)
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
    }

    func testAllAvailabilities() {
        for availability in Availability.allCases + [Availability?.none] {
            // Given
            sut.availability = availability
            let testName = if let availability { "\(availability)" } else { "none" }

            // Then
            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: sut, named: "light", testName: testName)
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: sut, named: "dark", testName: testName)
        }
    }
}
