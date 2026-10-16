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

final class CreateFilePage: PageModel {

    enum Template: String {
        case document
        case spreadsheet
        case presentation

        var fileExtension: String {
            switch self {
            case .document: "docx"
            case .spreadsheet: "xlsx"
            case .presentation: "pptx"
            }
        }
    }

    override var pageMainElement: XCUIElement {
        fileNameInputField
    }

    var fileNameInputField: XCUIElement {
        app.textFields.firstMatch
    }

    var createButton: XCUIElement {
        app.buttons
            .matching(identifier: Locators.WireDrive.CreateFilePage.createButton.rawValue)
            .firstMatch
    }

    var closeEditorButton: XCUIElement {
        app.navigationBars.buttons
            .matching(identifier: Locators.WireDrive.EditFilePage.closeEditFilePage.rawValue)
            .firstMatch
    }

    /// Creating a file opens it in the editor, which is closed to get back to the file list.
    func enterFileNameAndCreate(name: String) throws -> SharedDriveFilesPage {
        fileNameInputField.tap()
        fileNameInputField.typeText(name)
        createButton.tap()
        closeEditorButton.waitAndTap(timeout: 10)
        return try SharedDriveFilesPage()
    }
}
