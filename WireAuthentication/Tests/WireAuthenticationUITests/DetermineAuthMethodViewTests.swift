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

class DetermineAuthMethodViewTests: XCTestCase {
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
        let variants: [(emailOrSSOCode: String, errorMessage: String?)] = [
            ("", nil),
            ("sam@example.com", "Short error message"),
            ("sam@example.com", "Long error message that might wrap multiple lines depending on device and font size")
        ]

        let screenBounds = UIScreen.main.bounds
        for (index, variant) in variants.enumerated() {
            let view = MockDependencies().makeDetermineAuthMethodView(
                emailOrSSOCode: variant.emailOrSSOCode,
                isLoading: false,
                errorMessage: variant.errorMessage
            )
            .frame(width: screenBounds.width, height: screenBounds.height)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())

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

        let view = MockDependencies().makeDetermineAuthMethodView(
            emailOrSSOCode: "",
            isLoading: false,
            errorMessage: nil
        )
        .frame(width: screenBounds.width, height: screenBounds.height)
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }
}

