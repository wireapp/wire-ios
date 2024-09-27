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

import SnapshotTesting
import WireTestingPackage
import XCTest
@testable import Wire

final class PasscodeSetupViewControllerTests: XCTestCase {
    // MARK: Properties

    var sut: PasscodeSetupViewController!
    private var snapshotHelper: SnapshotHelper!

    // MARK: setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        accentColor = .blue
    }

    // MARK: tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
    }

    // MARK: Helper method

    private func fillPasscode() {
        sut.passcodeTextField.text = "P@ssc0de"
        sut.validationUpdated(sender: sut.passcodeTextField, error: nil)
    }

    // MARK: - Snapshot Tests

    func testForInitState() {
        sut = PasscodeSetupViewController(
            useCompactLayout: false,
            context: .createPasscode,
            callback: nil
        )

        snapshotHelper.verify(matching: sut)
    }

    func testForInitState_ifForcedApplock() {
        sut = PasscodeSetupViewController(
            useCompactLayout: false,
            context: .forcedForTeam,
            callback: nil
        )

        snapshotHelper.verify(matching: sut)
    }

    func testForInitStateInDarkTheme() {
        sut = PasscodeSetupViewController(
            useCompactLayout: false,
            context: .createPasscode,
            callback: nil
        )
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testForInitStateInDarkTheme_ifForcedApplock() {
        sut = PasscodeSetupViewController(
            useCompactLayout: false,
            context: .forcedForTeam,
            callback: nil
        )
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testForPasscodePassed() {
        // GIVEN
        sut = PasscodeSetupViewController(
            useCompactLayout: false,
            context: .createPasscode,
            callback: nil
        )
        fillPasscode()

        // WHEN
        for item in PasscodeError.allCases {
            sut.setValidationLabelsState(errorReason: item, passed: true)
        }

        // THEN
        snapshotHelper.verify(matching: sut)
    }
}
