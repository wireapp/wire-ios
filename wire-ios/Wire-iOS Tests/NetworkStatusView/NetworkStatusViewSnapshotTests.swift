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

final class NetworkStatusViewSnapshotTests: XCTestCase {

    private var sut: NetworkStatusView!
    private var mockContainer: MockNetworkStatusViewDelegate!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()

        accentColor = .purple
        mockContainer = .init()
        mockContainer.bottomMargin = 0
        mockContainer.didChangeHeightAnimatedState_MockMethod = { _, _, _ in }

        sut = NetworkStatusView()
        sut.backgroundColor = .clear
        sut.delegate = mockContainer
        snapshotHelper = SnapshotHelper()
    }

    override func tearDown() {
        sut = nil
        mockContainer = nil

        super.tearDown()
    }

    func testOfflineExpandedState() {
        // GIVEN
        sut.state = .offlineExpanded

        // WHEN && THEN
        verifyViewInAllThemesAndWidths(sut)
    }

    func testOnlineSynchronizing() {
        // GIVEN
        sut.state = .onlineSynchronizing
        sut.layer.speed = 0 // freeze animations for deterministic tests

        // WHEN && THEN
        verifyViewInAllThemesAndWidths(sut)
    }

    // MARK: - Helper method

    private func verifyViewInAllThemesAndWidths(
        _ view: UIView,
        testName: String = #function
    ) {
        let themes: [(style: UIUserInterfaceStyle, name: String)] = [
            (.light, "LightTheme"),
            (.dark, "DarkTheme")
        ]

        for theme in themes {
            // Apply the style directly to the view because verifyInAllPhoneWidths
            // is handling the snapshotting, not the chained snapshotHelper
            view.overrideUserInterfaceStyle = theme.style
            view.layoutIfNeeded()

            verifyInAllPhoneWidths(
                matching: view,
                named: theme.name,
                testName: testName
            )
        }
    }
}
