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
import WireFoundation
import WireMultiBackendUI
import WireNetwork
import WireTestingPackage
import XCTest
@testable import WireAuthenticationUI

final class AccountSwitcherViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    let accounts = [
        AccountUIModel(
            avatarSource: .image(.strokedCheckmark),
            name: "Name",
            handle: "handle",
            teamName: "Team",
            backendName: nil,
            action: {}
        ),
        AccountUIModel(
            avatarSource: .text("DS"),
            name: "Name 2",
            handle: "handle 2",
            teamName: "Team two",
            backendName: "Backend two",
            action: {}
        )
    ]

    @MainActor
    func testAccountSwitcher() {
        let screenBounds = UIScreen.main.bounds

        let view = NavigationStack {
            AccountSwitcherModalView(
                factory: FakeAccountSwitcherFactory(
                    accounts: accounts,
                    defaultEnvironment: .fixture()
                )
            )
        }
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
