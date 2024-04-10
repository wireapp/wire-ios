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
import LocalAuthentication

/// A description of a private encryption at rest key.
///
/// Private EAR keys are used to decrypt material that was encrypted
/// with the corresponding public EAR key.

public class PrivateEARKeyDescription: BaseEARKeyDescription, KeychainItemProtocol {

    // MARK: - Life cycle

    init(
        accountID: UUID,
        label: String,
        context: LAContextProtocol? = nil
    ) {
        super.init(
            accountID: accountID,
            label: label
        )

        getQuery = [
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrLabel: tag,
            kSecReturnRef: true
        ]

        #if !targetEnvironment(simulator)
        if let context = context {
            getQuery[kSecUseAuthenticationContext] = context
            getQuery[kSecUseAuthenticationUI] = kSecUseAuthenticationUISkip
        }
        #endif
    }

    // MARK: - Keychain item

    private(set) var getQuery = [CFString: Any]()

    func setQuery<T>(value: T) -> [CFString: Any] {
        // Private keys are stored in the Secure Enclave.
        return [:]
    }

}

extension PrivateEARKeyDescription {

    static func primaryKeyDescription(
        accountID: UUID,
        context: LAContext? = nil
    ) -> PrivateEARKeyDescription {
        return PrivateEARKeyDescription(
            accountID: accountID,
            label: "private",
            context: context
        )
    }

    static func secondaryKeyDescription(accountID: UUID) -> PrivateEARKeyDescription {
        return PrivateEARKeyDescription(
            accountID: accountID,
            label: "secondary-private"
        )
    }

}
