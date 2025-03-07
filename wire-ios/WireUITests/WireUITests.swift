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
import WireUtilities

final class WireUITests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
   // @MainActor // comment @MainActor to use recorder
    func test_Login_useWireAuthentication() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-BackendEnvironmentTypeOverrideKey staging",
            "--preferred-api-version=8"
        ]

        app.developerFlag(DeveloperFlag.useWireAuthentication, enabled: true)
        app.launch()
                        
        let elementsQuery = app.scrollViews.otherElements
        let textField = elementsQuery.textFields["Email or SSO code"]
        let nextButton = elementsQuery.buttons["Next"]
        
        XCTAssertFalse(nextButton.isEnabled, "nextButton should be disabled if no email")
        
        textField.tap()
        textField.typeText("demo@wire.com")
        
        let errorAlert = app.alerts["Error"]
        XCTAssertFalse(errorAlert.exists)

//        let okButton = errorAlert.scrollViews.otherElements.buttons["OK"]
//        okButton.tap()
        
    }
}

extension XCUIApplication {
    func developerFlag(_ developerFlag: DeveloperFlag, enabled: Bool) {
        launchArguments.append("--developer-flag=\(developerFlag.rawValue):\(enabled ? "true" : "false")")
    }
}
