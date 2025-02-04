//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

@testable import WireSettingsUI

final class CreatingBackupProgressViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testOngoingColorSchemeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = CreatingBackupProgressPreview(.ongoing(0.25))
            .frame(width: screenBounds.width)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFinishedColorSchemeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = CreatingBackupProgressPreview(.finished(URL(fileURLWithPath: "/")))
            .frame(width: screenBounds.width)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

//    @MainActor
//    func testDynamicTypeVariants() {
//        let screenBounds = UIScreen.main.bounds
//
//        let view = AuthenticationIdentityInputPreview()
//            .frame(width: screenBounds.width)
//
//        for dynamicTypeSize in DynamicTypeSize.allCases {
//            snapshotHelper
//                .verify(
//                    matching: view.dynamicTypeSize(dynamicTypeSize),
//                    named: "\(dynamicTypeSize)"
//                )
//        }
//    }
}
