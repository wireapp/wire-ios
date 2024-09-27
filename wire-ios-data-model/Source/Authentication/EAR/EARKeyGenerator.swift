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

public struct EARKeyGenerator {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func generatePrimaryPublicPrivateKeyPair(id: String) throws -> (publicKey: SecKey, privateKey: SecKey) {
        let keys = try KeychainManager.generatePublicPrivateKeyPair(
            identifier: id,
            accessLevel: .moreRestrictive
        )

        return (keys.publicKey, keys.privateKey)
    }

    public func generateSecondaryPublicPrivateKeyPair(id: String) throws -> (publicKey: SecKey, privateKey: SecKey) {
        let keys = try KeychainManager.generatePublicPrivateKeyPair(
            identifier: id,
            accessLevel: .lessRestrictive
        )

        return (keys.publicKey, keys.privateKey)
    }

    public func generateKey(numberOfBytes: UInt) throws -> Data {
        try KeychainManager.generateKey(numberOfBytes: numberOfBytes)
    }
}
