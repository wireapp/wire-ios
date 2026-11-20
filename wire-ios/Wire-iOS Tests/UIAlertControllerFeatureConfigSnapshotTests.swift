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

import XCTest
@testable import Wire

final class UIAlertControllerFeatureConfigSnapshotTests: XCTestCase {

    private typealias Strings = L10n.Localizable.FeatureConfig

    private func createSut(message: String) -> UIAlertController {
        let result = UIAlertController.alertForFeatureChange(message: message, onOK: {})
        result.view.backgroundColor = .white
        return result
    }

    // MARK: - Tests

    func testSelfDeletingMessagesIsDisabled() throws {
        try verify(matching: createSut(message: Strings.Alert.SelfDeletingMessages.Message.disabled))
    }

    func testSelfDeletingMessagsIsEnabled() throws {
        try verify(matching: createSut(message: Strings.Alert.SelfDeletingMessages.Message.enabled))
    }

    func testSelfDeletingMessagesIsForcedOn() throws {
        let timeout = MessageDestructionTimeoutValue(rawValue: 300)
        let timeoutString = try XCTUnwrap(timeout.displayString)
        try verify(matching: createSut(message: Strings.Alert.SelfDeletingMessages.Message.forcedOn(timeoutString)))
    }

    func testFileSharingEnabled() throws {
        try verify(matching: createSut(message: Strings.Update.FileSharing.Alert.Message.enabled))
    }

    func testFileSharingDisabled() throws {
        try verify(matching: createSut(message: Strings.Update.FileSharing.Alert.Message.disabled))
    }

}
