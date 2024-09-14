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
import WireTestingPackage

@testable import WireFoundation

final class Font_WireTextStyleTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(relativeTo: #file)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testWireTextStyleMappingPreview() throws {
        guard #available(iOS 16, *) else { return XCTFail() }

        let screenBounds = UIScreen.main.bounds
            let sut = WireTextStyleMappingPreview()
            .frame(width: screenBounds.width, height: screenBounds.height)
            snapshotHelper.verify(matching: sut)
    }
}
