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

import SwiftUI
import WireTestingPackage
import XCTest

@testable import Wire

final class ShareDebugBannerViewSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: UIHostingController<AnyView>!

    // MARK: - setUp

    @MainActor
    override func setUp() async throws {
        snapshotHelper = SnapshotHelper()
        let view = ShareDebugBannerView(onTap: {})
            .padding()
        sut = UIHostingController(rootView: AnyView(view))
        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 120)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testLightMode() {
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: sut)
    }

    func testDarkMode() {
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }
}
