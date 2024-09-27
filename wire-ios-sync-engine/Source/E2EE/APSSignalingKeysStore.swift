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

import UIKit
import WireTransport
import WireUtilities

// MARK: - SignalingKeys

public struct SignalingKeys {
    // MARK: Lifecycle

    init(verificationKey: Data? = nil, decryptionKey: Data? = nil) {
        self.verificationKey = verificationKey ?? NSData
            .secureRandomData(ofLength: APSSignalingKeysStore.defaultKeyLengthBytes)
        self.decryptionKey = decryptionKey ?? NSData
            .secureRandomData(ofLength: APSSignalingKeysStore.defaultKeyLengthBytes)
    }

    // MARK: Internal

    let verificationKey: Data
    let decryptionKey: Data
}

// MARK: - APSSignalingKeysStore

@objcMembers
public final class APSSignalingKeysStore: NSObject {
    // MARK: Lifecycle

    public init?(userClient: UserClient) {
        super.init()
        if let verificationKey = userClient.apsVerificationKey, let decryptionKey = userClient.apsDecryptionKey {
            self.verificationKey = verificationKey
            self.decryptionKey = decryptionKey
            self.apsDecoder = ZMAPSMessageDecoder(encryptionKey: decryptionKey, macKey: verificationKey)
        } else {
            return nil
        }
    }

    // MARK: Public

    public var apsDecoder: ZMAPSMessageDecoder!

    public func decryptDataDictionary(_ payload: [AnyHashable: Any]!) -> [AnyHashable: Any]! {
        apsDecoder.decodeAPSPayload(payload)
    }

    // MARK: Internal

    static let verificationKeyAccountName = "APSVerificationKey"
    static let decryptionKeyAccountName = "APSDecryptionKey"
    static let defaultKeyLengthBytes: UInt = 256 / 8

    var verificationKey: Data!
    var decryptionKey: Data!

    /// use this method to create new keys, e.g. for client registration or update
    static func createKeys() -> SignalingKeys {
        SignalingKeys()
    }

    /// we previously stored keys in the key chain. use this method to retreive the previously stored values to move
    /// them into the selfClient
    static func keysStoredInKeyChain() -> SignalingKeys? {
        guard let verificationKey = ZMKeychain.data(forAccount: verificationKeyAccountName),
              let decryptionKey = ZMKeychain.data(forAccount: decryptionKeyAccountName)
        else { return nil }

        return SignalingKeys(verificationKey: verificationKey, decryptionKey: decryptionKey)
    }

    static func clearSignalingKeysInKeyChain() {
        ZMKeychain.deleteAllKeychainItems(withAccountName: verificationKeyAccountName)
        ZMKeychain.deleteAllKeychainItems(withAccountName: decryptionKeyAccountName)
    }
}
