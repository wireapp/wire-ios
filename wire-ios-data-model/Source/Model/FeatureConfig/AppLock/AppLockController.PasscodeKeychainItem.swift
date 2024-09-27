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

import Foundation

extension AppLockController {
    struct PasscodeKeychainItem: KeychainItem {
        // MARK: Lifecycle

        init(userId: UUID) {
            self.init(itemIdentifier: "\(Constant.legacyIdentifier)-\(userId.uuidString)")
        }

        private init(itemIdentifier: String) {
            self.itemIdentifier = itemIdentifier
        }

        // MARK: Internal

        // MARK: - Methods

        var queryForGettingValue: [CFString: Any] {
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: itemIdentifier,
                kSecReturnData: true,
            ]
        }

        // MARK: Legacy

        static func makeLegacyItem() -> PasscodeKeychainItem {
            PasscodeKeychainItem(itemIdentifier: Constant.legacyIdentifier)
        }

        func queryForSetting(value: Data) -> [CFString: Any] {
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: itemIdentifier,
                kSecValueData: value,
            ]
        }

        // MARK: Private

        private enum Constant {
            static let legacyIdentifier = "com.wire.passcode"
        }

        // MARK: - Properties

        private let itemIdentifier: String
    }
}
