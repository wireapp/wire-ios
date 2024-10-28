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

/// A simple wrapper around the Keychain api.

public struct Keychain: KeychainProtocol {

    /// Add one or more items to a keychain.
    ///
    /// For more information, refer to the documentation of `SecItemAdd`.

    public func addItem(
        query: [CFString: Any]
    ) -> OSStatus {
        SecItemAdd(
            query as CFDictionary,
            nil
        )
    }

    /// Modify zero or more items which match a search query.
    ///
    /// For more information, refer to the documentation of `SecItemUpdate`.

    public func updateItem(
        query: [CFString: Any],
        attributesToUpdate: [CFString: Any]
    ) -> OSStatus {
        SecItemUpdate(
            query as CFDictionary,
            attributesToUpdate as CFDictionary
        )
    }

    /// Returns one or more items which match a search query.
    ///
    /// For more information, refer to the documentation of `SecItemCopyMatching`.

    public func fetchItem(
        query: [CFString: Any],
        result: UnsafeMutablePointer<CFTypeRef?>?
    ) -> OSStatus {
        SecItemCopyMatching(
            query as CFDictionary,
            result
        )
    }

    /// Delete zero or more items which match a search query.
    ///
    /// For more information, refer to the documentation of `SecItemDelete`.

    public func deleteItem(
        query: [CFString: Any]
    ) -> OSStatus {
        SecItemDelete(
            query as CFDictionary
        )
    }

}
