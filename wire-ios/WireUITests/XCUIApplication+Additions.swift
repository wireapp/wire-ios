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

extension XCUIApplication {

    func setDeveloperFlags(_ flags: [DeveloperFlag: Bool]) {
        let flagsString = flags.map {
            "\($0.key.rawValue):\($0.value ? "true" : "false")"
        }.joined(separator: " ")

        launchArguments.append("--developer-flag=\(flagsString)")
    }

    func loginUser(email: String, password: String) throws -> FirstTimePage {
        try WelcomePage()
            .enterEmailOrSSO(email)
            .enterPassword(password)
            .acceptFirstTimeAlert()
    }

    @discardableResult
    func onPad(_ block: (() -> Void)? = nil) -> Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
        block?()
        return true
    }
}
