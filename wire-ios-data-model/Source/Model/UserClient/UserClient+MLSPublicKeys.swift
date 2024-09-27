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

extension UserClient {
    // MARK: - Keys

    public static let mlsPublicKeysKey = "mlsPublicKeys"
    public static let needsToUploadMLSPublicKeysKey = "needsToUploadMLSPublicKeys"

    // MARK: - Properties

    /// Whether the client's mls public keys need to be uploaded to
    /// the server.

    @NSManaged public var needsToUploadMLSPublicKeys: Bool

    // Private storage of `mlsPublicKeys`.

    @NSManaged private var primitiveMlsPublicKeys: Data?

    /// The mls public keys for the self client.

    public var mlsPublicKeys: MLSPublicKeys {
        get {
            willAccessValue(forKey: Self.mlsPublicKeysKey)
            let result = decodedMLSPublicKeys(from: primitiveMlsPublicKeys)
            didAccessValue(forKey: Self.mlsPublicKeysKey)
            return result
        }

        set {
            guard newValue != mlsPublicKeys else { return }
            willChangeValue(forKey: Self.mlsPublicKeysKey)
            primitiveMlsPublicKeys = encodedMLSPublicKeys(newValue)
            didChangeValue(forKey: Self.mlsPublicKeysKey)
            needsToUploadMLSPublicKeys = true
            setLocallyModifiedKeys(Set([UserClient.needsToUploadMLSPublicKeysKey]))
        }
    }

    @objc public var hasRegisteredMLSClient: Bool {
        !mlsPublicKeys.isEmpty && needsToUploadMLSPublicKeys == false
    }

    // MARK: MLSPublicKeys

    private func decodedMLSPublicKeys(from data: Data?) -> MLSPublicKeys {
        guard let data else {
            return .init()
        }

        do {
            return try JSONDecoder().decode(MLSPublicKeys.self, from: data)
        } catch {
            // all errors are ignored
            return .init()
        }
    }

    private func encodedMLSPublicKeys(_ mlsPublicKeys: MLSPublicKeys) -> Data? {
        // all errors are ignored
        try? JSONEncoder().encode(mlsPublicKeys)
    }

    /// Clear previously registered MLS public keys.
    ///
    /// Only do this when when the self client has been deleted/reset.

    public func clearMLSPublicKeys() {
        willChangeValue(forKey: Self.mlsPublicKeysKey)
        primitiveMlsPublicKeys = nil
        didChangeValue(forKey: Self.mlsPublicKeysKey)
    }
}

// MARK: - UserClient.MLSPublicKeys

extension UserClient {
    public struct MLSPublicKeys: Codable, Equatable {
        enum CodingKeys: String, CodingKey {
            case ed25519
            case ed448
            case p256 = "ecdsa_secp256r1_sha256"
            case p384 = "ecdsa_secp384r1_sha384"
            case p521 = "ecdsa_secp521r1_sha512"
        }

        public internal(set) var ed25519: String?
        public internal(set) var ed448: String?
        public internal(set) var p256: String?
        public internal(set) var p384: String?
        public internal(set) var p521: String?

        public init(
            ed25519: String? = nil,
            ed448: String? = nil,
            p256: String? = nil,
            p384: String? = nil,
            p521: String? = nil
        ) {
            self.ed25519 = ed25519
            self.ed448 = ed448
            self.p256 = p256
            self.p384 = p384
            self.p521 = p521
        }

        public var isEmpty: Bool {
            allKeys.isEmpty
        }

        public var allKeys: [String] {
            [ed25519, ed448, p256, p384, p521].compactMap { $0 }
        }
    }
}
