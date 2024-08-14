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
import WireSystemSupport

@testable import Wire

class MockContainer: NetworkStatusViewDelegate {
    var shouldAnimateNetworkStatusView: Bool = true

    var bottomMargin: CGFloat = 0

    func didChangeHeight(_ networkStatusView: NetworkStatusView, animated: Bool, state: NetworkStatusViewState) {

    }
}

final class NetworkStatusViewTests: XCTestCase {

    private var sut: NetworkStatusView!
    private var mockSceneActivationStateProvider: MockSceneActivationStateProviding!
    private var mockContainer: MockContainer!

    override func setUp() {
        super.setUp()

        mockSceneActivationStateProvider = .init()
        mockSceneActivationStateProvider.activationStateForSceneOf_MockValue = .foregroundActive

        mockContainer = MockContainer()

        sut = NetworkStatusView(sceneActivationStateProvider: mockSceneActivationStateProvider)
        sut.delegate = mockContainer
    }

    override func tearDown() {
        sut = nil
        mockSceneActivationStateProvider = nil
        mockContainer = nil

        super.tearDown()
    }

    func testThatSyncBarChangesToHiddenWhenTheAppGoesToBackground() {
        // GIVEN
        sut.state = .onlineSynchronizing
        XCTAssertEqual(sut.connectingView.heightConstraint.constant, CGFloat.SyncBar.height, "NetworkStatusView should not be zero height")

        // WHEN
        mockSceneActivationStateProvider.activationStateForSceneOf_MockValue = .background
        sut.state = .onlineSynchronizing

        // THEN
        XCTAssertEqual(sut.connectingView.heightConstraint.constant, 0, "NetworkStatusView should be zero height")
    }
}

final class NetworkStatusViewSnapShotTests: XCTestCase {

    var sut: NetworkStatusView!
    var mockContainer: MockContainer!

    override func setUp() {
        super.setUp()
        accentColor = .purple
        mockContainer = MockContainer()
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
