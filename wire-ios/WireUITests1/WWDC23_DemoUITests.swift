//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
//import Wire

@available(iOS 17.0, *)
final class WWDC23_DemoUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAccessibility() throws {
        try app.performAccessibilityAudit()
    }

    func testContactsScreen() throws {
        let tabBar = app.tabBars["mainTabBar"]
        let tab = tabBar.tabs["contacts"]
        print("Kate \(tabBar)")
        tab.tap()
        try app.performAccessibilityAudit()
    }

    func testAccessibilitySomeScreen() throws {
        try app.performAccessibilityAudit(for: [.contrast]) { issue in
            var shouldIgnore = false

            if let element = issue.element,
                issue.auditType == .contrast {
                shouldIgnore = true
            }

            return shouldIgnore
        }
    }
}
