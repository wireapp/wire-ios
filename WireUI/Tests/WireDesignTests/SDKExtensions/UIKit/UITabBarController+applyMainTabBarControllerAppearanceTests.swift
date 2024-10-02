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
import WireTestingPackage
import XCTest

@testable import WireDesign

final class UITabBarController_applyMainTabBarControllerAppearanceTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testUIFontDarkUserInterfaceStyle() {
        let sut = MainTabBarControllerAppearancePreview()
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    @available(iOS 17, *) @MainActor
    func testUIFontContentSizeCategories() {
        let sut = MainTabBarControllerAppearancePreview()
        for contentSizeCategory in [UIContentSizeCategory.small, .accessibilityExtraExtraExtraLarge] {
            sut.traitOverrides.preferredContentSizeCategory = contentSizeCategory
            snapshotHelper
                .verify(
                    matching: sut,
                    named: "\(contentSizeCategory)"
                )
        }
    }
}
