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
import WireReusableUIComponents
import WireTestingPackage
import XCTest

@testable import WireIndividualToTeamMigrationUI

final class CheckboxSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor @ViewBuilder static var checked: some View {
        let screenBounds = UIScreen.main.bounds

        Checkbox(isChecked: .constant(true), title: "Checkbox")
            .frame(width: screenBounds.width, height: screenBounds.height)
    }

    @MainActor @ViewBuilder static var unchecked: some View {
        let screenBounds = UIScreen.main.bounds

        Checkbox(isChecked: .constant(false), title: "Checkbox")
            .frame(width: screenBounds.width, height: screenBounds.height)
    }

    @MainActor
    func testUncheckedColorSchemeVariants() {
        let view = Self.unchecked

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testCheckedColorSchemeVariants() {
        let view = Self.checked

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testUncheckedDynamicTypeVariants() {
        let view = Self.unchecked

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

    @MainActor
    func testCheckedDynamicTypeVariants() {
        let view = Self.checked

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }
}
