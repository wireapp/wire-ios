//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// A container of MLS public keys.

public struct MLSPublicKeys: Equatable, Codable, Sendable {

    /// The ed25519 signature key.

    public let ed25519: String?

    /// The ed448 signature key.

    public let ed448: String?

    /// The p256 signature key.

    public let p256: String?

    /// The p384 signature key.

    public let p384: String?

    /// The p512 signature key.

    public let p512: String?

    enum CodingKeys: String, CodingKey {

        case ed25519
        case ed448
        case p256 = "ecdsa_secp256r1_sha256"
        case p384 = "ecdsa_secp384r1_sha384"
        case p512 = "ecdsa_secp521r1_sha512"

    }

    public init(
        ed25519: String? = nil,
        ed448: String? = nil,
        p256: String? = nil,
        p384: String? = nil,
        p512: String? = nil
    ) {
        self.ed25519 = ed25519
        self.ed448 = ed448
        self.p256 = p256
        self.p384 = p384
        self.p512 = p512
    }

}
