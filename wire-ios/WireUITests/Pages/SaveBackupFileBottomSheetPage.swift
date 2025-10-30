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

import XCTest

class SaveBackupFileBottomSheetPage: PageModel {

    override var pageMainElement: XCUIElement {
        saveToFilesOption
    }

    var saveToFilesOption: XCUIElement {
        app.cells["Save to Files"]
    }

    func getBackupFileName() -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        let predicate = NSPredicate(format: "label BEGINSWITH %@", "WireBackup-\(dateString)")
        let element = app.otherElements.matching(predicate).firstMatch

        guard element.waitForExistence(timeout: 3) else { return nil }
        return element.exists ? element.label : nil
    }

    func tapSaveToFilesOnBottomSheet() throws -> OnMyDevicePage {
        saveToFilesOption.tap()
        return try OnMyDevicePage()
    }

}
