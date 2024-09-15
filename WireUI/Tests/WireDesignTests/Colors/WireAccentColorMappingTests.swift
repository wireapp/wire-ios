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

@testable import WireDesign

final class WireAccentColorMappingTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(relativeTo: #file)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @available(iOS 16, *) @MainActor
    func testAccentColors() {
        let screenBounds = UIScreen.main.bounds
        let sut = WireAccentColorMappingPreview()
            .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: sut, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, named: "dark")
    }
}
