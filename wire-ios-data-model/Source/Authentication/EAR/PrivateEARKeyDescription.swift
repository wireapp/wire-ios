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
import LocalAuthentication

/// A description of a private encryption at rest key.
///
/// Private EAR keys are used to decrypt material that was encrypted
/// with the corresponding public EAR key.

public final class PrivateEARKeyDescription: BaseEARKeyDescription, KeychainItemProtocol {
    // MARK: Lifecycle

    init(
        accountID: UUID,
        label: String,
        context: AuthenticationContextProtocol?
    ) {
        self.context = context

        super.init(
            accountID: accountID,
            label: label
        )
    }

    // MARK: Internal

    // MARK: - Keychain item

    var getQuery: [CFString: Any] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrLabel: tag,
            kSecReturnRef: true,
        ]

        #if !targetEnvironment(simulator)
            if let laContext = context?.laContext {
                query[kSecUseAuthenticationContext] = laContext
                query[kSecUseAuthenticationUI] = kSecUseAuthenticationUISkip
            }
        #endif

        return query
    }

    // MARK: - Static Access

    static func primaryKeyDescription(
        accountID: UUID,
        context: AuthenticationContextProtocol?
    ) -> PrivateEARKeyDescription {
        PrivateEARKeyDescription(
            accountID: accountID,
            label: Constant.labelPrivatePrimary,
            context: context
        )
    }

    static func secondaryKeyDescription(accountID: UUID) -> PrivateEARKeyDescription {
        PrivateEARKeyDescription(
            accountID: accountID,
            label: Constant.labelPrivateSecondary,
            context: nil
        )
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        // Private keys are stored in the Secure Enclave.
        [:]
    }

    // MARK: Private

    private enum Constant {
        static let labelPrivatePrimary = "private"
        static let labelPrivateSecondary = "secondary-private"
    }

    private let context: AuthenticationContextProtocol?
}
