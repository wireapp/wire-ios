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

import WireSidebarUI
import WireTestingPackage
import XCTest

@testable import Wire

final class SidebarViewControllerBuilderSnapshotTests: XCTestCase {

    private var sut: SidebarViewController!
    private var snapshotHelper: SnapshotHelper!

    @MainActor
    override func setUp() async throws {
        sut = SidebarViewControllerBuilder().build()
        sut.accountInfo.displayName = "Firstname Surname"
        sut.accountInfo.username = "@username"
        sut.accountInfo.availability = .busy
        sut.accountInfo.isE2EICertified = true
        sut.accountInfo.isVerified = true
        sut.accountInfo.accountImageSource = .text("CA")
        sut.wireAccentColor = .purple
        snapshotHelper = .init()
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
    }

    @available(iOS 17, *) @MainActor
    func testUIFontDarkUserInterfaceStyle() {
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    @available(iOS 17, *) @MainActor
    func testUIFontContentSizeCategories() {
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
