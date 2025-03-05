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
import WireAPI
import WireTestingPackage
import XCTest

@testable import WireAuthenticationAPI
@testable import WireAuthenticationUI

class LoginViaEmailOnPremViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testColorSchemeVariantsWithoutProxySettings() {
        let screenBounds = UIScreen.main.bounds

        let view = MockDependencies().loginViaEmailOnPremView(
            email: "foo@bar.com",
            backendConfig: MockDependencies()._backendConfig
        )
        .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testDynamicTypeVariantsWithoutProxySettings() {
        let screenBounds = UIScreen.main.bounds

        let view = MockDependencies().loginViaEmailOnPremView(
            email: "foo@bar.com",
            backendConfig: MockDependencies()._backendConfig
        )
        .frame(width: screenBounds.width, height: screenBounds.height)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

    @MainActor
    func testColorSchemeVariantsWithProxySettings() {
        let screenBounds = UIScreen.main.bounds

        let backendConfig = BackendConfig(
            title: "<backen name>",
            endpoints: Endpoints(
                backendURL: URL(string: "https://example.com")!,
                backendWSURL: URL(string: "https://example.com")!,
                blackListURL: URL(string: "https://example.com")!,
                teamsURL: URL(string: "https://example.com")!,
                accountsURL: URL(string: "https://example.com")!,
                websiteURL: URL(string: "https://example.com")!
            ),
            proxySettings: ProxySettings(host: "host", port: 111, needsAuthentication: true),
            pinnedKeys: nil
        )

        let view = MockDependencies().loginViaEmailOnPremView(
            email: "foo@bar.com",
            backendConfig: backendConfig
        )
        .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testDynamicTypeVariantsWithProxySettings() {
        let screenBounds = UIScreen.main.bounds

        let backendConfig = BackendConfig(
            title: "<backen name>",
            endpoints: Endpoints(
                backendURL: URL(string: "https://example.com")!,
                backendWSURL: URL(string: "https://example.com")!,
                blackListURL: URL(string: "https://example.com")!,
                teamsURL: URL(string: "https://example.com")!,
                accountsURL: URL(string: "https://example.com")!,
                websiteURL: URL(string: "https://example.com")!
            ),
            proxySettings: nil,
            pinnedKeys: nil
        )
        let view = MockDependencies().loginViaEmailOnPremView(
            email: "foo@bar.com",
            backendConfig: backendConfig
        )
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
