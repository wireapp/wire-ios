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

import WireTestingPackage
import XCTest

@testable import Wire

final class EmptyAppsSearchResultViewSnapshotTests: XCTestCase {

    // MARK: Properties

    private var snapshotHelper: SnapshotHelper!

    // MARK: setUp / tearDown

    override func setUp() {
        snapshotHelper = SnapshotHelper()
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    // MARK: Snapshot Tests

    func testAdminAppearance() {
        // GIVEN
        let sut = EmptyAppsSearchResultView(canManageTeam: true)
        sut.frame = CGRect(
            origin: .zero,
            size: CGSize(width: 320, height: 480)
        )
        sut.backgroundColor = .systemBackground

        // WHEN & THEN
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )
    }

    func testNonAdminAppearance() {
        // GIVEN
        let sut = EmptyAppsSearchResultView(canManageTeam: false)
        sut.frame = CGRect(
            origin: .zero,
            size: CGSize(width: 320, height: 480)
        )
        sut.backgroundColor = .systemBackground

        // WHEN & THEN
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: sut,
                named: "LightTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #filePath,
                testName: #function,
                line: #line
            )
    }

}
