// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import ZMTransport
import ZMUtilities


public struct SignalingKeys {
    let verificationKey : NSData
    let decryptionKey : NSData
    
    init(verificationKey: NSData? = nil, decryptionKey: NSData? = nil) {
        self.verificationKey = verificationKey ?? NSData.secureRandomDataOfLength(APSSignalingKeysStore.defaultKeyLengthBytes)
        self.decryptionKey = decryptionKey ?? NSData.secureRandomDataOfLength(APSSignalingKeysStore.defaultKeyLengthBytes)
    }
}


@objc
public class APSSignalingKeysStore: NSObject {
    public var apsDecoder: ZMAPSMessageDecoder!
    internal var verificationKey : NSData!
    internal var decryptionKey : NSData!

    internal static let verificationKeyAccountName = "APSVerificationKey"
    internal static let decryptionKeyAccountName = "APSDecryptionKey"
    internal static let defaultKeyLengthBytes : UInt = 256 / 8
    
    public init?(userClient: UserClient) {
        super.init()
        if let verificationKey = userClient.apsVerificationKey, decryptionKey = userClient.apsDecryptionKey {
            self.verificationKey = verificationKey
            self.decryptionKey = decryptionKey
            self.apsDecoder = ZMAPSMessageDecoder(encryptionKey: decryptionKey, macKey: verificationKey)
        }
        else {
            return nil
        }
    }
    
    /// use this method to create new keys, e.g. for client registration or update
    static func createKeys() -> SignalingKeys {
        return SignalingKeys()
    }
    
    /// we previously stored keys in the key chain. use this method to retreive the previously stored values to move them into the selfClient
    static func keysStoredInKeyChain() -> SignalingKeys? {
        guard let verificationKey = ZMKeychain.dataForAccount(self.verificationKeyAccountName),
              let decryptionKey = ZMKeychain.dataForAccount(self.decryptionKeyAccountName)
        else { return nil }
        
        return SignalingKeys(verificationKey: verificationKey, decryptionKey: decryptionKey)
    }
    
    static func clearSignalingKeysInKeyChain(){
        ZMKeychain.deleteAllKeychainItemsWithAccountName(self.verificationKeyAccountName)
        ZMKeychain.deleteAllKeychainItemsWithAccountName(self.decryptionKeyAccountName)
    }
    
    public func decryptDataDictionary(payload: NSDictionary) -> NSDictionary? {
        return self.apsDecoder.decodeAPSPayload(payload as [NSObject : AnyObject])
    }
}

