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

import WireLocators
import XCTest

class CreatingBackupPage: PageModel {

    override var pageMainElement: XCUIElement {
        creatingBackupPageLabel
    }

    var creatingBackupPageLabel: XCUIElement {
        app.descendants(matching: .any)[Locators.CreatingBackupPage.creatingBackupPageLabel.rawValue]
    }

    var backupSuccessfullyCreatedLabel: XCUIElement {
        app.descendants(matching: .any)[Locators.CreatingBackupPage.backupCreatedLabel.rawValue]
    }

    var backupProgressLabel: XCUIElement {
        app.descendants(matching: .any)[Locators.CreatingBackupPage.progressView.rawValue]
    }

    var saveFileButton: XCUIElement {
        app.buttons[Locators.CreatingBackupPage.exportBackupButton.rawValue]
    }

    func getBackupProgressValue() -> String? {
        backupProgressLabel.value as? String
    }

    func tapSaveFile() throws -> SaveBackupFileBottomSheetPage {
        if backupSuccessfullyCreatedLabel.exists {
            saveFileButton.tap()
        }
        return try SaveBackupFileBottomSheetPage()
    }

}
