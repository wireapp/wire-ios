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

import WireCommonComponents
import WireTestingPackage
import XCTest

@testable import Wire

final class MessageActionTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!

    // MARK: setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    // MARK: tearDown

    override func tearDown() {
        snapshotHelper = nil

        super.tearDown()
    }

    func testForSystemIcons() {
        MessageAction.allCases.forEach { action in
            if let image = action.systemIcon() {
                let imageView = UIImageView(image: image)
                snapshotHelper.verify(matching: imageView, named: "\(action)")
            }
        }
    }

    func testForStyleKitIcons() {
        MessageAction.allCases.forEach { action in
            if let icon = action.icon {
                let image = icon.makeImage(size: .tiny, color: .black)
                snapshotHelper.verify(matching: image, named: "\(action)")
            }
        }
    }
}
