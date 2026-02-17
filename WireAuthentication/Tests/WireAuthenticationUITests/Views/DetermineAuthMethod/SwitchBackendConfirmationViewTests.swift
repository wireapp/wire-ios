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
import WireNetwork
import WireTestingPackage
import XCTest

@testable import WireAuthenticationAPI
@testable import WireAuthenticationUI

class SwitchBackendConfirmationViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    private let environment = BackendEnvironment2(
        title: "Staging",
        environmentType: .staging,
        config: .init(
            endpoints: .init(
                restAPIURL: URL(string: "www.staging.com")!,
                websocketURL: URL(string: "www.staging.com")!,
                blacklistURL: URL(string: "www.staging.com")!,
                teamsURL: URL(string: "www.staging.com")!,
                accountsURL: URL(string: "www.staging.com")!,
                websiteURL: URL(string: "www.staging.com")!,
                countlyURL: URL(string: "www.staging.com")!
            ),
            pinnedKeys: [],
            proxyConfig: nil
        )
    )

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testColorSchemeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = SwitchBackendConfirmation(
            environment: environment,
            onConfirm: { _ in }
        ).frame(
            width: screenBounds.width,
            height: screenBounds.height
        )

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testDynamicTypeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = SwitchBackendConfirmation(
            environment: environment,
            onConfirm: { _ in }
        ).frame(
            width: screenBounds.width,
            height: screenBounds.height
        )

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

}
