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

import Foundation

import SwiftUI
import WireTestingPackage
import XCTest

@testable import WireAuthenticationUI

class NoHistoryViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    // MARK: - First time login

    @MainActor
    func testColorSchemeVariantsEmptyState_FirstTimeLogin() {
        let screenBounds = UIScreen.main.bounds

        let view = NoHistoryView(factory: FakeNoHistoryFactory(didReauthenticate: false))
            .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testDynamicTypeVariantsEmptyState_FirstTimeLogin() {
        let screenBounds = UIScreen.main.bounds

        let view = NoHistoryView(factory: FakeNoHistoryFactory(didReauthenticate: false))
            .frame(width: screenBounds.width, height: screenBounds.height)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

    // MARK: - Reauth

    @MainActor
    func testColorSchemeVariantsEmptyState_DidReauthenticate() {
        let screenBounds = UIScreen.main.bounds

        let view = NoHistoryView(factory: FakeNoHistoryFactory(didReauthenticate: true))
            .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

}
