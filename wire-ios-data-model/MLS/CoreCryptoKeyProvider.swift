//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

public class CoreCryptoKeyProvider {
    public func coreCryptoKey() throws -> Data  {
        let item = CoreCryptoKeychainItem()
        if let key: Data = try? KeychainManager.fetchItem(item) {
            return key
        } else {
            let key = try KeychainManager.generateKey(numberOfBytes: 32)
            try KeychainManager.storeItem(item, value: key)
            return key
        }
    }
}

struct CoreCryptoKeychainItem: KeychainItemProtocol {

    static let tag = "com.wire.mls.key".data(using: .utf8)!

    var getQuery: [CFString : Any] {
        return [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: Self.tag,
            kSecReturnData: true
        ]
    }

    func setQuery<T>(value: T) -> [CFString : Any] {
        return [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: Self.tag,
            kSecValueData: value
        ]
    }
}
