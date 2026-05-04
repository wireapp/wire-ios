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
import WireTestingPackage
import XCTest

@testable import WireSettingsUI

@MainActor
final class EnterPasswordViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() async throws {
        snapshotHelper = nil
    }

    func testInvalidPassword() async throws {
        let screenBounds = UIScreen.main.bounds
        let sut = EnterPasswordView(
            password: .constant("invalid"),
            passwordIsWrong: .constant(true),
            focusPasswordFieldOnAppear: false,
            continueAction: { _ in },
            cancelAction: {},
            isContextMenuAllowed: true
        )
        .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: sut, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, named: "dark")
    }

    func testNonEmptyPassword() async throws {
        let screenBounds = UIScreen.main.bounds
        let sut = EnterPasswordView(
            password: .constant("G00dPassword!"),
            passwordIsWrong: .constant(false),
            focusPasswordFieldOnAppear: false,
            continueAction: { _ in },
            cancelAction: {},
            isContextMenuAllowed: true
        )
        .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: sut, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, named: "dark")
    }

    func testColorSchemeVariants() async throws {
        let screenBounds = UIScreen.main.bounds
        let sut = EnterPasswordView(
            password: .constant(""),
            passwordIsWrong: .constant(false),
            focusPasswordFieldOnAppear: false,
            continueAction: { _ in },
            cancelAction: {},
            isContextMenuAllowed: true
        )
        .frame(width: screenBounds.width, height: screenBounds.height)

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, named: "dark")
    }

    func testDynamicTypeVariants() {
        let screenBounds = UIScreen.main.bounds
        let sut = EnterPasswordView(
            password: .constant(""),
            passwordIsWrong: .constant(false),
            focusPasswordFieldOnAppear: false,
            continueAction: { _ in },
            cancelAction: {},
            isContextMenuAllowed: true
        )
        .frame(width: screenBounds.width, height: screenBounds.height)

        for dynamicTypeSize in DynamicTypeSize.allCases {
            snapshotHelper
                .verify(
                    matching: sut.dynamicTypeSize(dynamicTypeSize),
                    named: "\(dynamicTypeSize)"
                )
        }
    }

}
