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

import WireUtilities
import XCTest

extension XCUIElement {

    @discardableResult
    func tapIfKeyboardNotFocused(timeout: TimeInterval = 3.0) -> XCUIElement {
        let startTime = Date()
        while true {
            let hasKeyboardFocus = (value(forKey: "hasKeyboardFocus") as? Bool) ?? false
            if hasKeyboardFocus {
                break
            }
            tap()

            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Failed to focus keyboard on element within \(timeout) seconds")
                break
            }
        }
        return self
    }
}
