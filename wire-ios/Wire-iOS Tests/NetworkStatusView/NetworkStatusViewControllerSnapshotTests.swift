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

import WireTestingPackage
import XCTest
@testable import Wire

final class MockContainerViewController: UIViewController, NetworkStatusBarDelegate {
    var bottomMargin = CGFloat.NetworkStatusBar.bottomMargin

    func showInIPad(
        networkStatusViewController: NetworkStatusViewController,
        with orientation: UIInterfaceOrientation
    ) -> Bool {
        true
    }

    var shouldAnimateNetworkStatusView = true
}

/// Snapshot tests for differnt margin and size of NetworkStatusViewController.view for all value of NetworkState with
/// other UIView at the bottom.
final class NetworkStatusViewControllerSnapshotTests: XCTestCase {
    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: NetworkStatusViewController!
    private var mockContainerViewController: MockContainerViewController!
    private var mockContentView: UIView!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = .init()
        UIView.setAnimationsEnabled(false)

        mockContainerViewController = MockContainerViewController()
        mockContainerViewController.view.bounds.size = CGSize(width: 375.0, height: 667.0)
        mockContainerViewController.view.backgroundColor = .lightGray

        sut = NetworkStatusViewController()
        sut.view.backgroundColor = .gray
        mockContainerViewController.view.addSubview(sut.view)
        sut.delegate = mockContainerViewController

        mockContentView = UIView()
        mockContentView.backgroundColor = .white
        mockContainerViewController.view.addSubview(mockContentView)

        sut.view.translatesAutoresizingMaskIntoConstraints = false
        mockContentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            sut.view.topAnchor.constraint(equalTo: mockContainerViewController.safeTopAnchor),
            sut.view.leadingAnchor.constraint(equalTo: mockContainerViewController.view.leadingAnchor),
            sut.view.trailingAnchor.constraint(equalTo: mockContainerViewController.view.trailingAnchor),
            sut.view.bottomAnchor.constraint(equalTo: mockContentView.topAnchor),
            mockContentView.leadingAnchor.constraint(equalTo: mockContainerViewController.view.leadingAnchor),
            mockContentView.trailingAnchor.constraint(equalTo: mockContainerViewController.view.trailingAnchor),
            mockContentView.bottomAnchor.constraint(equalTo: mockContainerViewController.safeBottomAnchor),
        ])
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        mockContainerViewController = nil
        mockContentView = nil

        super.tearDown()
    }

    // MARK: - Helper method

    private func verify(
        for newState: NetworkState,
        testName: String = #function,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // GIVEN
        sut.didChangeAvailability(newState: newState)

        // WHEN
        sut.applyPendingState()

        // THEN
        snapshotHelper.verify(matching: mockContainerViewController.view, file: file, testName: testName, line: line)
    }

    // MARK: - Snapshot Tests

    func testOnlineState() {
        verify(for: .online)
    }

    func testOfflineState() {
        verify(for: .offline)
    }

    func testOnlineSynchronizing() {
        verify(for: .onlineSynchronizing)
    }
}
