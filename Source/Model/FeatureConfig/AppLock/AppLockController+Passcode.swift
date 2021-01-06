//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import Foundation


public extension AppLockController {

    /// Delete the passcode from the keychain.

    func deletePasscode() throws {
        try Keychain.deleteItem(keychainItem)
    }

    /// Store the given passcode in the keychain.

    func storePasscode(_ passcode: String) throws {
        try Keychain.storeItem(keychainItem, value: passcode.data(using: .utf8)!)
    }

    /// Fetch the passcode from the keychain.

    func fetchPasscode() -> Data? {
        return try? Keychain.fetchItem(keychainItem)
    }

}
