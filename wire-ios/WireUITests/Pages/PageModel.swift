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

class PageModel {

    enum Failure: Error {
        case notLoaded(PageModel)
        
        var localizedDescription: String {
            switch self {
            case .notLoaded(let pageModel):
                return "Page \(String(describing: pageModel)) not loaded"
            }
        }
    }

    let app: XCUIApplication

    init() {
        self.app = XCUIApplication()
    }

    var pageMainElement: XCUIElement {
        fatalError("override this in subclass \(String(describing: self))")
    }
    
    func assertHasLoaded() throws -> Self {
        guard pageMainElement.waitForExistence(timeout: 10) else {
            throw Failure.notLoaded(self)
        }
        return self
    }
}
