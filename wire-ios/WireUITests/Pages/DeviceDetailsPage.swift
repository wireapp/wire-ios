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

import WireLocators
import XCTest

class DeviceDetailsPage: PageModel {

    private let deviceName: String

    override var pageMainElement: XCUIElement {
        app.staticTexts[deviceName].firstMatch
    }

    init(deviceName: String) throws {
        self.deviceName = deviceName
        try super.init()
    }

    var verifiedSwitch: XCUIElement {
        app.switches[Locators.DeviceDetailsPage.verifiedSwitch.rawValue].firstMatch
    }

    var removeDeviceButton: XCUIElement {
        app.buttons[Locators.DeviceDetailsPage.removeDeviceButton.rawValue].firstMatch
    }

    var passwordField: XCUIElement {
        app.secureTextFields.firstMatch
    }

    var okButton: XCUIElement {
        app.buttons[Locators.DeviceDetailsPage.ok.rawValue].firstMatch
    }

    @discardableResult
    func verifyDevice(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> DeviceDetailsPage {
        if verifiedSwitch.value as? String != "1" {
            verifiedSwitch.tap()
        }

        let predicate = NSPredicate(format: "value == %@", "1")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: verifiedSwitch)
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: 5),
            .completed,
            "Device was not verified",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func verifyDeviceIsStillVerified(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> DeviceDetailsPage {
        XCTAssertEqual(
            verifiedSwitch.value as? String,
            "1",
            "Device not showing as verified",
            file: file,
            line: line
        )
        return self
    }

    func deleteDevice(password: String) throws -> DevicesPage {
        removeDeviceButton.waitAndTap()
        try passwordField.tapIfKeyboardNotFocused().typeText(password)
        okButton.waitAndTap()
        return try DevicesPage()
    }
}
