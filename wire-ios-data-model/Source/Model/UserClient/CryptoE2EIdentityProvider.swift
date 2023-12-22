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

import WireCoreCrypto

public protocol CryptoE2EIdentityProviderProtocol {
    func isE2EIdentityEnabled() -> Bool
    func fetchWireIdentity(clientIDs: [ClientId], conversationId: String) -> [WireIdentity]
    func fetchWireIdentity(userIds: [String], conversationId: String ) -> [WireIdentity]
}

// MARK: Delete this once origial corecryto methods are available
final public class MockCryptoE2EIProvider: CryptoE2EIdentityProviderProtocol {
    public init() {}

    public func isE2EIdentityEnabled() -> Bool {
        return true
    }

    public func fetchWireIdentity(userIds: [String], conversationId: String) -> [WireCoreCrypto.WireIdentity] {
        guard !userIds.isEmpty, !conversationId.isEmpty else {
            return []
        }
        // TODO: Call core crypto method to fetch `WireIdentity`
        return [WireIdentity(clientId: "sdkjfsafsld", handle: "sdsjks", displayName: "asfdsk sdfsdfs", domain: "sdfasfas")]
    }

    public func fetchWireIdentity(clientIDs: [ClientId], conversationId: String) -> [WireIdentity] {
        guard !conversationId.isEmpty, !clientIDs.isEmpty else {
            return []
        }
        // TODO: Call core crypto method to fetch `WireIdentity`
        return [WireIdentity(clientId: "sdkjfsafsld", handle: "sdsjks", displayName: "asfdsk sdfsdfs", domain: "sdfasfas")]
    }
}
