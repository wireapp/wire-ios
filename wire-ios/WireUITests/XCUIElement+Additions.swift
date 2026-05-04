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

import WireUtilities
import XCTest

extension XCUIElement {
    enum KeyboardFocusError: Error {
        case failedToFocusWithinTimeout(message: String)
    }

    @discardableResult
    func tapIfKeyboardNotFocused(timeout: TimeInterval = 3.0) throws -> XCUIElement {
        tap()
        let keyboard = XCUIApplication().keyboards.element

        _ = keyboard.waitForExistence(timeout: 0.5)
        let hasFocus = (value(forKey: "hasKeyboardFocus") as? Bool) ?? false

        if !(keyboard.exists || hasFocus) {
            tap()
            _ = keyboard.waitForExistence(timeout: 0.5)
        }
        return self
    }

    @discardableResult
    func waitToDisappear(andThenWaitFor nextElement: XCUIElement? = nil, timeout: TimeInterval = 5) -> Bool {

        let disappearExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: self
        )
        let disappearResult = XCTWaiter().wait(for: [disappearExpectation], timeout: timeout)
        guard disappearResult == .completed else { return false }

        guard let next = nextElement else { return true }

        let appearExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"),
            object: next
        )
        let result = XCTWaiter().wait(for: [appearExpectation], timeout: timeout)
        return result == .completed
    }

    @discardableResult
    func waitAndTap(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true && isHittable == true")
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [exp], timeout: timeout)
        guard result == .completed else { return false }
        tap()
        return true
    }
}
