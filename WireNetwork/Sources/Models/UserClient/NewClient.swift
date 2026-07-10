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

/// Payload to register a new client.

public struct NewClient: Equatable, Sendable {

    /// Prekeys for other clients to establish proteus sessions.

    public let prekeys: [Prekey]

    /// The last resort prekey.

    public let lastkey: Prekey

    /// The type of user client.

    public let type: UserClientType

    /// The capabilities of the client.

    public let capabilities: [UserClientCapability]?

    /// The device class of the client.

    public let deviceClass: DeviceClass?

    /// The cookie label, i.e. the label used when logging in.

    public let cookie: String?

    /// A label describing the client.

    public let label: String?

    /// A description of the client device model.

    public let model: String?

    /// The password of the authenticated user for verification.
    /// Note: Required for registration of the 2nd, 3rd, ... client.

    public let password: String?

    /// Verification code for authentication.

    public let verificationCode: String?

    /// The mls public keys for the client.

    public let mlsPublicKeys: MLSPublicKeys?

    /// Create a new `NewClient`.
    ///
    /// - Parameters:
    ///   - prekeys: Prekeys for other clients to establish proteus sessions.
    ///   - lastkey: The last resort prekey.
    ///   - type: The type of user client.
    ///   - capabilities: The capabilities of the client.
    ///   - deviceClass: The device class of the client.
    ///   - cookie: The cookie label, i.e. the label used when logging in.
    ///   - label: A label describing the client.
    ///   - model: A description of the client device model.
    ///   - password: The password of the authenticated user for verification.
    ///   - verificationCode: Verification code for authentication.
    ///   - mlsPublicKeys: The mls public keys for the client.

    public init(
        prekeys: [Prekey],
        lastkey: Prekey,
        type: UserClientType,
        capabilities: [UserClientCapability]? = nil,
        deviceClass: DeviceClass? = nil,
        cookie: String? = nil,
        label: String? = nil,
        model: String? = nil,
        password: String? = nil,
        verificationCode: String? = nil,
        mlsPublicKeys: MLSPublicKeys? = nil
    ) {
        self.prekeys = prekeys
        self.lastkey = lastkey
        self.type = type
        self.capabilities = capabilities
        self.deviceClass = deviceClass
        self.cookie = cookie
        self.label = label
        self.model = model
        self.password = password
        self.verificationCode = verificationCode
        self.mlsPublicKeys = mlsPublicKeys
    }

}
