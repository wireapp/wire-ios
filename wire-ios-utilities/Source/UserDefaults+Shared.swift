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

import CommonCrypto
import Foundation
import Security
import WireLogging

public extension UserDefaults {

    static func cookiesKey() -> Data {
        let cookieKeyKey = "ZMCookieKey"
        let sharedDefaults = UserDefaults.shared()

        if let key = sharedDefaults?.data(forKey: cookieKeyKey) {
            return key
        }

        if sharedDefaults == nil {
            WireLogger.authentication.critical("Failed to access shared user defaults", attributes: .safePublic)
        }

        // On older versions we stored key in standard user defaults.
        // We need to check for key there first and save it to shared defaults.
        // This way extension can use it to decrypt cookies stored in keychain.
        let key: Data
        if let migratedKey = UserDefaults.standard.data(forKey: cookieKeyKey) {
            UserDefaults.standard.removeObject(forKey: cookieKeyKey)
            key = migratedKey
        } else {
            key = makeRandomAES256Key()
        }

        sharedDefaults?.set(key, forKey: cookieKeyKey)
        WireLogger.authentication.info("Generated cookie key", attributes: .safePublic)

        return key
    }

    private static func makeRandomAES256Key() -> Data {
        var bytes = [UInt8](repeating: 0, count: kCCKeySizeAES256)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess)
        return Data(bytes)
    }
}
