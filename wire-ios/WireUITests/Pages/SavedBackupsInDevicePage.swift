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

class SavedBackupsInDevicePage: PageModel {

    override var pageMainElement: XCUIElement {
        onMyIphonePageLabel
    }

    var onMyIphonePageLabel: XCUIElement {
        app.staticTexts["On My iPhone"]
    }

    var searchField: XCUIElement {
        app.searchFields["Search"]
    }

    var backupFile: (String) -> XCUIElement {
        { name in
            let predicate = NSPredicate(format: "identifier CONTAINS %@", name)
            return self.app.cells.matching(predicate).firstMatch
        }
    }

    func selectBackupFile(withName name: String) throws -> SetPasswordPage {
        backupFile(name).tap()
        return try SetPasswordPage()
    }
}
