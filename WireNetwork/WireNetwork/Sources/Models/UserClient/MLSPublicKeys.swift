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

import Foundation

/// A container of MLS public keys.

public struct MLSPublicKeys: Equatable, Sendable {

    /// The ed25519 signature key.

    public let ed25519: String?

    /// The p256 signature key.

    public let p256: String?

    /// The p384 signature key.

    public let p384: String?

    /// The p521 signature key.

    public let p521: String?

    /// Whether at least one non-empty key exists.

    public var isValid: Bool {
        let allKeys = [ed25519, p256, p384, p521].compactMap(\.self)
        return allKeys.contains { !$0.isEmpty }
    }

    public init(
        ed25519: String? = nil,
        p256: String? = nil,
        p384: String? = nil,
        p521: String? = nil
    ) {
        self.ed25519 = ed25519
        self.p256 = p256
        self.p384 = p384
        self.p521 = p521
    }
}

struct MLSPublicKeysV0: Equatable, Sendable, Codable {

    let ed25519: String?
    let p256: String?
    let p384: String?
    let p521: String?

    enum CodingKeys: String, CodingKey {

        case ed25519
        case p256 = "ecdsa_secp256r1_sha256"
        case p384 = "ecdsa_secp384r1_sha384"
        case p521 = "ecdsa_secp521r1_sha512"

    }

    init(
        ed25519: String? = nil,
        p256: String? = nil,
        p384: String? = nil,
        p521: String? = nil
    ) {
        self.ed25519 = ed25519
        self.p256 = p256
        self.p384 = p384
        self.p521 = p521
    }
}

extension MLSPublicKeysV0: ToAPIModelConvertible {

    func toAPIModel() -> MLSPublicKeys {
        MLSPublicKeys(
            ed25519: ed25519,
            p256: p256,
            p384: p384,
            p521: p521
        )
    }
}

extension MLSPublicKeys: ToNetworkConvertible {

    func toNetworkModel() -> MLSPublicKeysV0 {
        MLSPublicKeysV0(
            ed25519: ed25519,
            p256: p256,
            p384: p384,
            p521: p521
        )
    }
}
