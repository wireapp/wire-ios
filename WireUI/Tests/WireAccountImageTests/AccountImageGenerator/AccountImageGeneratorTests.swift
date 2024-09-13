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

@testable import WireAccountImage

final class AccountImageGeneratorTests: XCTestCase {

    private var sut: AccountImageGenerator!
    private var snapshotHelper: SnapshotHelper!

    @MainActor
    override func setUp() async throws {
        sut = .init()
        snapshotHelper = .init()
            .withPerceptualPrecision(1)
            .withSnapshotDirectory(relativeTo: #file)
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
    }

    @MainActor
    func testRenderingWhiteW() async {
        let image = await sut.createImage(initials: "W", backgroundColor: .white)
        let imageView = UIImageView(image: image)
        imageView.frame.size = image.size

        snapshotHelper
            .verify(matching: imageView)
    }

    @MainActor
    func testRenderingBlueCA() async {
        let image = await sut.createImage(initials: "CA", backgroundColor: .init(red: 0.02, green: 0.4, blue: 0.78, alpha: 1))
        let imageView = UIImageView(image: image)
        imageView.frame.size = image.size

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: imageView)

        imageView.image = await sut.createImage(initials: "CA", backgroundColor: .init(red: 0.33, green: 0.65, blue: 1, alpha: 1))

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: imageView)
    }
}
