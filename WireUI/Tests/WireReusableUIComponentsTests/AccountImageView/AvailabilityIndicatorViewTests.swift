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

import WireUITesting
import XCTest

@testable import WireReusableUIComponents

final class AvailabilityIndicatorViewTests: XCTestCase {

    private var sut: AvailabilityIndicatorView!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        sut = .init()
        print(ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"]!)
        snapshotHelper = .init()
            .withSnapshotDirectory(Bundle.module.resourceURL?.path ?? "")
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
    }

    func testNone() {

        // Given
        sut.availability = .none

        // Then
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #file,
                testName: #function,
                line: #line
            )
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #file,
                testName: #function,
                line: #line
            )
    }
}
