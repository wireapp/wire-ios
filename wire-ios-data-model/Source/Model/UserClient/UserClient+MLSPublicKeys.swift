//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
            let result = primitiveMlsPublicKeys?.decode(as: MLSPublicKeys.self) ?? .init()
            didAccessValue(forKey: Self.mlsPublicKeysKey)
            return result
        }

        set {
            guard newValue != mlsPublicKeys else { return }
            willChangeValue(forKey: Self.mlsPublicKeysKey)
            primitiveMlsPublicKeys = newValue.encodeToJSON()
            didChangeValue(forKey: Self.mlsPublicKeysKey)
            needsToUploadMLSPublicKeys = true
            setLocallyModifiedKeys(Set([UserClient.needsToUploadMLSPublicKeysKey]))
        }
    }

}

extension UserClient {

    public struct MLSPublicKeys: Codable, Equatable {

        public internal(set) var ed25519: String?

        public init(ed25519: String? = nil) {
            self.ed25519 = ed25519
        }

    }

}
