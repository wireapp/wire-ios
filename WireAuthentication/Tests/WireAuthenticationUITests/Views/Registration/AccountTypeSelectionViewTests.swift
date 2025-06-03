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

import SwiftUI
import WireTestingPackage
import XCTest
import WireAuthenticationAPISupport

@testable import WireAuthenticationUI

final class AccountTypeSelectionViewTests: XCTestCase {

    private var analyticsTrackerMock: MockAccountRegistrationAnalyticsTrackerProtocol!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        analyticsTrackerMock = .init()
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
        analyticsTrackerMock = nil
    }

    @MainActor
    func testColorSchemeVariantsEmptyState() {
        let screenBounds = UIScreen.main.bounds

        let viewModel = AccountTypeSelectionViewModel(
            teamsURL: URL(string: "https://www.apple.com")!,
            analyticsTracker: analyticsTrackerMock
        )
        let view = AccountTypeSelectionView(factory: FakeAccountTypeSelectionFactory())
            .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testDynamicTypeVariantsEmptyState() {
        let screenBounds = UIScreen.main.bounds

        let viewModel = AccountTypeSelectionViewModel(
            teamsURL: URL(string: "https://www.apple.com")!,
            analyticsTracker: analyticsTrackerMock
        )
        let view = AccountTypeSelectionView(factory: FakeAccountTypeSelectionFactory())
            .frame(width: screenBounds.width, height: screenBounds.height)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

}
