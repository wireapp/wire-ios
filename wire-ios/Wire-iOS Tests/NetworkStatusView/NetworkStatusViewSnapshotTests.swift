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

import XCTest
@testable import Wire

final class NetworkStatusViewSnapshotTests: XCTestCase {
    private var sut: NetworkStatusView!
    private var mockContainer: MockNetworkStatusViewDelegate!

    override func setUp() {
        super.setUp()

        accentColor = .purple
        mockContainer = .init()
        mockContainer.bottomMargin = 0
        mockContainer.didChangeHeightAnimatedState_MockMethod = { _, _, _ in }

        sut = NetworkStatusView()
        sut.overrideUserInterfaceStyle = .light
        sut.backgroundColor = .clear
        sut.delegate = mockContainer
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
        verifyInAllPhoneWidths(matching: sut)
    }

    func testOnlineSynchronizing() {
        // GIVEN
        sut.state = .onlineSynchronizing
        sut.layer.speed = 0 // freeze animations for deterministic tests
        // WHEN && THEN
        verifyInAllPhoneWidths(matching: sut)
    }
}
