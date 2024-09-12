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

import SwiftUI
import WireTestingPackage
import XCTest

@testable import WireUserProfile

final class AccountImageViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withPerceptualPrecision(1)
            .withSnapshotDirectory(relativeTo: #file)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testAllAccountTypesAndAvailabilities() {
        for isTeamAccount in [false, true] {
            for availability in Availability.allCases + [Availability?.none] {
                if #available(iOS 16.0, *) {
                    // Given
                    let rootView = AccountImageView_Previews.previewWithNavigationBar(isTeamAccount, availability)
                    let hostingControllerView = UIHostingController(rootView: rootView).view!
                    hostingControllerView.frame = UIScreen.main.bounds
                    let accountType = isTeamAccount ? "team" : "personal"
                    let testName = if let availability { "\(accountType).\(availability)" } else { "\(accountType).none" }

                    // Then
                    snapshotHelper
                        .withUserInterfaceStyle(.light)
                        .verify(matching: hostingControllerView, named: "light", testName: testName)
                    snapshotHelper
                        .withUserInterfaceStyle(.dark)
                        .verify(matching: hostingControllerView, named: "dark", testName: testName)

                } else {
                    XCTFail("iOS 16+ is needed")
                }
            }
        }
    }
}
