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
import WireTestingPackage
import XCTest

@testable import WireAuthenticationUI

final class DetermineAuthMethodViewTests: XCTestCase {
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
        let variants: [String] = [
            "",
            "sam@example.com"
        ]

        let screenBounds = UIScreen.main.bounds
        for (index, emailOrSSOCode) in variants.enumerated() {

            let factory = FakeDetermineAuthMethodFactory(emailOrSSOCode: emailOrSSOCode)

            let view = NavigationStack {
                DetermineAuthMethodView(factory: factory)
            }
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())
            .frame(width: screenBounds.width, height: screenBounds.height)
            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "variant\(index)-light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "variant\(index)-dark")
        }
    }

    @MainActor
    func testDynamicTypeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = NavigationStack {
            DetermineAuthMethodView(factory: FakeDetermineAuthMethodFactory())
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

    @MainActor
    func testCanExitFlow() {
        let screenBounds = UIScreen.main.bounds

        let view = NavigationStack {
            DetermineAuthMethodView(factory: FakeDetermineAuthMethodFactory(existsAnotherAccount: true))
        }
        .frame(width: screenBounds.width, height: screenBounds.height)
        .tint(.primary)

        snapshotHelper.verify(matching: view)
    }
}
