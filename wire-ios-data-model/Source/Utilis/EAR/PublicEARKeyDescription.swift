//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

/// A description of a public encryption at rest key.
///
/// Public EAR keys are used to encrypt material that should be decrypted
/// with the corresponding private EAR key.

public class PublicEARKeyDescription: BaseEARKeyDescription, KeychainItemProtocol {

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

        baseQuery = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
    }

    // MARK: - Keychain item

    var getQuery: [CFString: Any] {
        var query = baseQuery
        query[kSecReturnRef] = true
        return query
    }

    func setQuery<T>(value: T) -> [CFString: Any] {
        var query = baseQuery
        query[kSecValueRef] = value
        return query
    }

}
