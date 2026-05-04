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
import WireDesign
import WireTestingPackage
import XCTest

@testable import WireReusableUIComponents

final class PasswordFieldSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
    }

    // MARK: - Snapshot Tests

    @MainActor
    func testInvalidHidden() {
        let screenBounds = UIScreen.main.bounds
        let view = PasswordField(
            password: .constant("Invalid password"),
            placeholder: L10n.Passwordtextfield.Preview.placeholder,
            title: L10n.Passwordtextfield.Preview.title,
            passwordRules: L10n.Passwordtextfield.Preview.passwordrules,
            isValidPassword: { _ in false }
        )
        .frame(width: screenBounds.width, height: screenBounds.height)
        .padding(.horizontal)
        snapshotHelper.verify(matching: view)
    }

    @MainActor
    func testColorSchemeVariants() {
        let screenBounds = UIScreen.main.bounds

        let view = PasswordField(
            password: .constant("Valid password!"),
            placeholder: L10n.Passwordtextfield.Preview.placeholder,
            title: L10n.Passwordtextfield.Preview.title,
            passwordRules: L10n.Passwordtextfield.Preview.passwordrules,
            isValidPassword: { _ in true }
        )
        .frame(width: screenBounds.width, height: screenBounds.height)
        .padding(.horizontal)

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
        let view = PasswordField(
            password: .constant("Valid password!"),
            placeholder: L10n.Passwordtextfield.Preview.placeholder,
            title: L10n.Passwordtextfield.Preview.title,
            passwordRules: L10n.Passwordtextfield.Preview.passwordrules,
            isValidPassword: { _ in true }
        )
        .frame(width: screenBounds.width, height: screenBounds.height)
        .padding(.horizontal)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }
}
