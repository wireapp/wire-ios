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

/// A description of a public encryption at rest key.
///
/// Public EAR keys are used to encrypt material that should be decrypted
/// with the corresponding private EAR key.

public final class PublicEARKeyDescription: BaseEARKeyDescription, KeychainItemProtocol {
    private enum Constant {
        static let labelPublicPrimary = "public"
        static let labelPublicSecondary = "secondary-public"
    }

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
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
        ]
    }

    // MARK: - Keychain item

    var getQuery: [CFString: Any] {
        var query = baseQuery
        query[kSecReturnRef] = true
        return query
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        var query = baseQuery
        query[kSecValueRef] = value
        query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
        return query
    }

    // MARK: - Static Access

    static func primaryKeyDescription(accountID: UUID) -> PublicEARKeyDescription {
        PublicEARKeyDescription(
            accountID: accountID,
            label: Constant.labelPublicPrimary
        )
    }

    static func secondaryKeyDescription(accountID: UUID) -> PublicEARKeyDescription {
        PublicEARKeyDescription(
            accountID: accountID,
            label: Constant.labelPublicSecondary
        )
    }
}
