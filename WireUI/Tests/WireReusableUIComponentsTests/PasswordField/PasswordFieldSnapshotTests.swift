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
        let viewModel = PasswordFieldViewModel(
            isPasswordVisible: false,
            password: "Invalid password",
            passwordValidator: MockPasswordValidator(validationCallback: { _ in false })
        )
        let view = view(for: viewModel)
        snapshotHelper.verify(matching: view)
    }

    @MainActor
    func testInvalidVisible() {
        let viewModel = PasswordFieldViewModel(
            isPasswordVisible: true,
            password: "Invalid password",
            passwordValidator: MockPasswordValidator(validationCallback: { _ in false })
        )
        let view = view(for: viewModel)
        snapshotHelper.verify(matching: view)
    }

    @MainActor
    func testValidHidden() {
        let viewModel = PasswordFieldViewModel(
            isPasswordVisible: false,
            password: "Valid password!",
            passwordValidator: MockPasswordValidator(validationCallback: { _ in true })
        )
        let view = view(for: viewModel)
        snapshotHelper.verify(matching: view)
    }

    @MainActor
    func testValidVisible() {
        let viewModel = PasswordFieldViewModel(
            isPasswordVisible: true,
            password: "Valid password!",
            passwordValidator: MockPasswordValidator(validationCallback: { _ in true })
        )
        let view = view(for: viewModel)
        snapshotHelper.verify(matching: view)
    }

    @MainActor
    func testColorSchemeVariants() {
        let viewModel = PasswordFieldViewModel(
            isPasswordVisible: false,
            password: "Valid password!",
            passwordValidator: MockPasswordValidator(validationCallback: { _ in true })
        )
        let view = view(for: viewModel)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testDynamicTypeVariants() {
        let viewModel = PasswordFieldViewModel(
            isPasswordVisible: false,
            password: "Valid password!",
            passwordValidator: MockPasswordValidator(validationCallback: { _ in true })
        )
        let view = view(for: viewModel)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: view.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }
}

@MainActor @ViewBuilder
fileprivate func view(for viewModel: PasswordFieldViewModel) -> some View {
    let screenBounds = UIScreen.main.bounds
    PasswordField(
       viewModel: viewModel,
       placeholder: L10n.Passwordtextfield.Preview.placeholder,
       title: L10n.Passwordtextfield.Preview.title
   )
   .frame(width: screenBounds.width, height: screenBounds.height)
}
