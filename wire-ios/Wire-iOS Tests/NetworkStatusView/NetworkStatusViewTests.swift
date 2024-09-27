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

// MARK: - NetworkStatusViewTests

final class NetworkStatusViewTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockContainer = .init()
        mockContainer.bottomMargin = 0
        mockContainer.didChangeHeightAnimatedState_MockMethod = { _, _, _ in }

        sut = .init()
        sut.delegate = mockContainer
        let rootView = try XCTUnwrap(
            (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?
                .rootViewController?.view
        )
        sut.translatesAutoresizingMaskIntoConstraints = false
        rootView.addSubview(sut)
        NSLayoutConstraint.activate([
            sut.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
            sut.centerYAnchor.constraint(equalTo: rootView.centerYAnchor),
        ])
    }

    override func tearDown() {
        sut.removeFromSuperview()
        sut = nil
        mockContainer = nil

        super.tearDown()
    }

    func testThatSyncBarChangesToHiddenWhenTheAppGoesToBackground() throws {
        // GIVEN
        sut.state = .onlineSynchronizing
        XCTAssertEqual(
            sut.connectingView.heightConstraint.constant,
            CGFloat.SyncBar.height,
            "NetworkStatusView should not be zero height"
        )

        // ... the activation state of the scene returns `.background`
        let getterSelector = #selector(getter: UIScene.activationState)
        let getBackgroundSelector = #selector(getter: UIScene.backgroundActivationState)
        let originalGetter = try XCTUnwrap(class_getInstanceMethod(UIScene.self, getterSelector))
        let temporaryGetter = try XCTUnwrap(class_getInstanceMethod(UIScene.self, getBackgroundSelector))
        method_exchangeImplementations(originalGetter, temporaryGetter)
        defer { method_exchangeImplementations(originalGetter, temporaryGetter) }

        // WHEN
        sut.state = .onlineSynchronizing

        // THEN
        XCTAssertEqual(sut.connectingView.heightConstraint.constant, 0, "NetworkStatusView should be zero height")
    }

    // MARK: Private

    private var sut: NetworkStatusView!
    private var mockContainer: MockNetworkStatusViewDelegate!
}

// MARK: - Method Swizzling

extension UIScene {
    @objc fileprivate var backgroundActivationState: UIScene.ActivationState {
        .background
    }
}
