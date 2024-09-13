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

/// A description of a database encryption at rest key.
///
/// The database key is used to symmetrically encrypt and decrypt
/// content in the database.

public class DatabaseEARKeyDescription: BaseEARKeyDescription, KeychainItemProtocol {
    // MARK: - Properties

    private var baseQuery = [CFString: Any]()

    // MARK: - Life cycle

    override init(
        accountID: UUID,
        label: String
    ) {
        super.init(
            accountID: accountID,
            label: label
        )

        self.baseQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: id,
        ]
    }

    // MARK: - Keychain item

    var getQuery: [CFString: Any] {
        var query = baseQuery
        query[kSecReturnData] = true
        return query
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        var query = baseQuery
        query[kSecValueData] = value
        return query
    }

    // MARK: - Static Access

    static func keyDescription(accountID: UUID) -> DatabaseEARKeyDescription {
        DatabaseEARKeyDescription(
            accountID: accountID,
            label: "database"
        )
    }
}
