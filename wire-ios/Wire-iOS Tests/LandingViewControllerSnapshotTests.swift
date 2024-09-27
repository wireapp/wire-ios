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
import WireTransport
import XCTest
@testable import Wire

// MARK: - LandingViewControllerSnapshotTests

final class LandingViewControllerSnapshotTests: XCTestCase {
    // MARK: - Properties

    private var sut: LandingViewController!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = .init()
        sut = LandingViewController()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForInitState() {
        sut = LandingViewController()
        snapshotHelper.verifyInAllDeviceSizes(matching: sutInUiNavigationController())
    }

    func testForBackendWithCustomURL() {
        let customBackend = MockEnvironment()
        customBackend.backendURL = URL(string: "https://api.example.org")!
        customBackend.proxy = nil
        customBackend
            .environmentType =
            EnvironmentTypeProvider(environmentType: .custom(url: URL(string: "https://api.example.org")!))
        sut = LandingViewController(backendEnvironmentProvider: {
            customBackend
        })

        snapshotHelper.verifyInAllDeviceSizes(matching: sutInUiNavigationController())
    }

    // MARK: - Helper Method

    func sutInUiNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(
            navigationBarClass: AuthenticationNavigationBar.self,
            toolbarClass: nil
        )
        navigationController.setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: .compact), forChild: sut)
        navigationController.viewControllers = [sut]

        return navigationController
    }
}

// MARK: - FakeProxySettings

final class FakeProxySettings: NSObject, ProxySettingsProvider {
    var host: String
    var port: Int
    var needsAuthentication: Bool

    init(host: String = "api.example.org", port: Int = 1345, needsAuthentication: Bool = false) {
        self.host = host
        self.port = port
        self.needsAuthentication = needsAuthentication
    }

    func socks5Settings(proxyUsername: String?, proxyPassword: String?) -> [AnyHashable: Any]? {
        nil
    }
}
