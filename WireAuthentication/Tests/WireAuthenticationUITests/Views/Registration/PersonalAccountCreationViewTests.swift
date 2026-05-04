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
import WireAuthenticationAPI
import WireNetwork
import WireTestingPackage
import XCTest

@testable import WireAuthenticationUI

final class PersonalAccountCreationViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

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

        let view = NavigationStack {
            PersonalAccountCreationView(factory: FakePersonalAccountCreationFactory(
                email: "foo@bar.com",
                environment: Scaffolding.environment(backendURL: "https://prod-nginz-https.wire.com"),
                privacyPolicyURL: URL(string: "www.wire.com")!,
                termsOfUseURL: URL(string: "www.wire.com")!,
                passwordValidator: MockPasswordValidator()
            ))
        }.frame(width: screenBounds.width, height: screenBounds.height)

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

        let view = NavigationStack {
            PersonalAccountCreationView(factory: FakePersonalAccountCreationFactory(
                email: "foo@bar.com",
                environment: Scaffolding.environment(backendURL: "https://prod-nginz-https.wire.com"),
                privacyPolicyURL: URL(string: "www.wire.com")!,
                termsOfUseURL: URL(string: "www.wire.com")!,
                passwordValidator: MockPasswordValidator()
            ))
        }.frame(width: screenBounds.width, height: screenBounds.height)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }
}

private enum Scaffolding {

    static func environment(backendURL: String) -> BackendEnvironment2 {
        BackendEnvironment2(
            title: "mock",
            environmentType: .default,
            config: .init(
                endpoints: .init(
                    restAPIURL: URL(string: backendURL)!,
                    websocketURL: URL(string: "https://wire.com")!,
                    blacklistURL: URL(string: "https://wire.com")!,
                    teamsURL: URL(string: "https://wire.com")!,
                    accountsURL: URL(string: "https://wire.com")!,
                    websiteURL: URL(string: "https://wire.com")!,
                    countlyURL: URL(string: "https://wire.com")!
                ),
                pinnedKeys: [],
                proxyConfig: nil
            )
        )
    }

}
