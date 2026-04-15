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

class CreateChannelPage: PageModel {

    override var pageMainElement: XCUIElement {
        channelNameTextfield
    }

    var channelNameTextfield: XCUIElement {
        app.descendants(matching: .any)[Locators.CreateChannelPage.channelNameField.rawValue].firstMatch
    }

    var nextButton: XCUIElement {
        app.descendants(matching: .any)[Locators.CreateChannelPage.newChannelNextButton.rawValue].firstMatch
    }

    var shareDriveSwitch: XCUIElement {
        app.descendants(matching: .any)[Locators.CreateChannelPage.sharedDriveSwitch.rawValue].switches.firstMatch
    }

    func enableShareDriveSwitch() throws -> CreateChannelPage {
        shareDriveSwitch.tap()
        return self
    }

    func enterChannelName(_ channelName: String) throws -> SelectParticipantsPage {
        try channelNameTextfield.tapIfKeyboardNotFocused().typeText(channelName)
        nextButton.tap()
        return try SelectParticipantsPage()
    }
}
