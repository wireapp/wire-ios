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

class DevicesPage: PageModel {

    override var pageMainElement: XCUIElement {
        devicesNavigationBar
    }

    var devicesNavigationBar: XCUIElement {
        app.navigationBars[Locators.DevicesPage.title.rawValue]
    }

    var deviceNameLabels: XCUIElementQuery {
        app.staticTexts.matching(identifier: Locators.DevicesPage.deviceNameLabel.rawValue)
    }

    func deviceNameLabel(named name: String) -> XCUIElement {
        deviceNameLabels.matching(NSPredicate(format: "label == %@", name)).firstMatch
    }

    func deviceCell(named name: String) -> XCUIElement {
        app.cells.matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
    }

    @discardableResult
    func verifyLoggedInDevicesListContains(
        _ deviceName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> DevicesPage {
        XCTAssertTrue(
            deviceNameLabel(named: deviceName).waitForExistence(timeout: 5),
            "\(deviceName) was not visible in devices list",
            file: file,
            line: line
        )
        return self
    }

    func openDeviceDetails(named deviceName: String) throws -> DeviceDetailsPage {
        let deviceCell = deviceCell(named: deviceName)
        deviceCell.waitAndTap()
        return try DeviceDetailsPage(deviceName: deviceName)
    }

    @discardableResult
    func verifyDeviceIsDeleted(
        named deviceName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> DevicesPage {
        XCTAssertFalse(
            deviceNameLabel(named: deviceName).waitForExistence(timeout: 2),
            "\(deviceName) was still showing after deletion",
            file: file,
            line: line
        )
        return self
    }
}
