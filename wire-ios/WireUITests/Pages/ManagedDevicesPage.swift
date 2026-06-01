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

class ManagedDevicesPage: PageModel {

    override var pageMainElement: XCUIElement {
        manageDevicesButton
    }

    var manageDevicesButton: XCUIElement {
        app.buttons[Locators.ManageDevicesPage.manageDevices.rawValue].firstMatch
    }

    var removeDevice: XCUIElement {
        app.images[Locators.ManageDevicesPage.removeDevice.rawValue].firstMatch
    }

    var deleteDevice: XCUIElement {
        app.buttons[Locators.ManageDevicesPage.deleteDevice.rawValue].firstMatch
    }

    func removeDeviceAndContinueIfShown() throws -> ConversationsPage {
        guard manageDevicesButton.exists else {
            return try ConversationsPage()
        }
        manageDevicesButton.tap()
        removeDevice.tap()
        deleteDevice.tap()

        return try ConversationsPage()
    }

}
