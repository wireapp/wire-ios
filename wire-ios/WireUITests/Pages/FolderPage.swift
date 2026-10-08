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

final class FolderPage: PageModel {

    override var pageMainElement: XCUIElement {
        createFolderPageHeader
    }

    var folderNameInputField: XCUIElement {
        app.textFields.firstMatch
    }

    var createFolderPageHeader: XCUIElement {
        app.staticTexts[Locators.WireDrive.CreateFilePage.createFolderPageHeader.rawValue]
    }

    var createFolderButton: XCUIElement {
        app.buttons
            .matching(identifier: Locators.WireDrive.CreateFilePage.createButton.rawValue)
            .firstMatch
    }

    func enterFolderNameAndValidate(name: String) throws -> SharedDriveFilesPage {
        folderNameInputField.tap()
        folderNameInputField.typeText(name)
        createFolderButton.tap()
        return try SharedDriveFilesPage()
    }

}
