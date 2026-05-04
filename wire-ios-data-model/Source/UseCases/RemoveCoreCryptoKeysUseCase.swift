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

// sourcery: AutoMockable
public protocol RemoveCoreCryptoKeysUseCaseProtocol {

    /// Removes all the core crypto keys from the keychain for the user with the given user ID
    func invoke(userID: UUID) throws

}

public struct RemoveCoreCryptoKeysUseCase {

    public func invoke(userID: UUID) throws {
        // Get all items of class key
        let items = try KeychainManager.fetchAllItems(secClass: kSecClassKey)

        try items.filter { item in

            // Filter by tag matching all CC keys of the user
            guard
                let tagData = item[kSecAttrApplicationTag] as? Data,
                let tagString = String(data: tagData, encoding: .utf8)
            else {
                return false
            }
            let partialTag = "\(CoreCryptoKeychainItem.scopedBaseId).\(userID.uuidString)"
            return tagString.contains(partialTag)

        }.forEach { item in

            // Remove the matching keys
            let query = [
                kSecClass: kSecClassKey,
                kSecAttrApplicationTag: item[kSecAttrApplicationTag]
            ]

            try KeychainManager.delete(query: query as CFDictionary)
        }
    }

}
