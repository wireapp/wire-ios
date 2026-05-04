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

/// Payload to update a UserClient
public struct ClientUpdate: Equatable, Sendable {

    /// The capabilities of the client.
    /// - Note: capabilities cannot be removed once added to a client,
    ///  so once 1 capability added it must always be present
    public let capabilities: [UserClientCapability]?

    /// A label describing the client.

    public let label: String?

    /// The last resort Prekey

    public let lastKey: Prekey?

    /// The mls public keys for the client.

    public let mlsPublicKeys: MLSPublicKeys?

    /// New prekeys for other clients to establish OTR sessions.

    public let preKeys: [Prekey]?

    public init(
        capabilities: [UserClientCapability]? = nil,
        label: String? = nil,
        lastKey: Prekey? = nil,
        mlsPublicKeys: MLSPublicKeys? = nil,
        preKeys: [Prekey]? = nil
    ) {
        self.capabilities = capabilities
        self.label = label
        self.lastKey = lastKey
        self.mlsPublicKeys = mlsPublicKeys
        self.preKeys = preKeys
    }
}
