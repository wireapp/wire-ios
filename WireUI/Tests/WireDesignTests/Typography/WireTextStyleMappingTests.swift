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

final class WireTextStyleMappingTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testFontDarkUserInterfaceStyle() {
        let screenBounds = UIScreen.main.bounds
        let sut = WireTextStyleFontMappingPreview()
            .frame(width: screenBounds.width, height: screenBounds.height)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    @MainActor
    func testFontDynamicTypeVariants() {
        let screenBounds = UIScreen.main.bounds
        let sut = WireTextStyleFontMappingPreview()
            .frame(width: screenBounds.width, height: screenBounds.height * 1.5)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: sut.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

    @MainActor
    func testUIFontDarkUserInterfaceStyle() {
        let sut = WireTextStyleUIFontMappingPreview()
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    @available(iOS 17, *) @MainActor
    func testUIFontContentSizeCategories() {
        let sut = WireTextStyleUIFontMappingPreview()
        for contentSizeCategory in UIContentSizeCategory.allCases {
            sut.traitOverrides.preferredContentSizeCategory = contentSizeCategory
            snapshotHelper
                .verify(
                    matching: sut,
                    named: "\(contentSizeCategory)"
                )
        }
    }
}
