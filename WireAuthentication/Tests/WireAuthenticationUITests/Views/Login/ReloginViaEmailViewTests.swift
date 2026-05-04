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
import WireAuthenticationAPISupport
import WireNetwork
import WireTestingPackage
import XCTest

@testable import WireAuthenticationUI

final class ReloginViaEmailViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testReloginViaEmail() {
        let screenBounds = UIScreen.main.bounds
        let environment = BackendEnvironment2.fixture(environmentType: .staging)

        let view = NavigationStack {
            ReloginViaEmailView(factory: FakeReloginViaEmailFactory(
                email: "jane@doe.com",
                environment: environment,
                existsAnotherAccount: true
            ))
        }
        .frame(
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
    func testReloginViaEmail_WithProxy() {
        let screenBounds = UIScreen.main.bounds
        let environment = BackendEnvironment2.fixture(
            environmentType: .staging,
            proxyConfig: .init(host: "host", port: 111, needsAuthentication: true)
        )

        let view = NavigationStack {
            ReloginViaEmailView(factory: FakeReloginViaEmailFactory(
                email: "jane@doe.com",
                environment: environment,
                existsAnotherAccount: true
            ))
        }
        .frame(
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

}
