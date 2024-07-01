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

import SwiftUI
import WireDesign
import WireUITesting
import XCTest

@testable import WireReusableUIComponents

final class MiniatureAccountImageFactorySnapshotTests: XCTestCase {

    private var sut: MiniatureAccountImageFactory!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        sut = .init()
        snapshotHelper = .init()
            .withPerceptualPrecision(1)
            .withSnapshotDirectory(relativeTo: #file)
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
    }

    func testRenderingWhiteW() {

        let image = sut.createImage(initials: "W", backgroundColor: .white)
        let imageView = UIImageView(image: image)
        imageView.frame.size = image.size

        snapshotHelper
            .verify(matching: imageView)
    }

    func testRenderingBlueCA() {

        let image = sut.createImage(initials: "CA", backgroundColor: BaseColorPalette.LightUI.MainColor.blue500)
        let imageView = UIImageView(image: image)
        imageView.frame.size = image.size

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: imageView)

        imageView.image = sut.createImage(initials: "CA", backgroundColor: BaseColorPalette.DarkUI.MainColor.blue500)

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: imageView)
    }
}
