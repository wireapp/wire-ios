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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import UIKit
import ZMTransport
import ZMUtilities


@objc
public class APSSignalingKeysStore: NSObject {
    public var verificationKey: NSData!
    public var decryptionKey: NSData!
    public var apsDecoder: ZMAPSMessageDecoder!
    
    private static let verificationKeyAccountName = "APSVerificationKey"
    private static let decryptionKeyAccountName = "APSDecryptionKey"
    private static let defaultKeyLengthBytes : UInt = 256 / 8
    
    public init?(fromKeychain: Bool) {
        let newVerificationKey: NSData!
        let newDecryptionKey: NSData!
        
        if fromKeychain {
            newVerificationKey = ZMKeychain.dataForAccount(self.dynamicType.verificationKeyAccountName)
            newDecryptionKey = ZMKeychain.dataForAccount(self.dynamicType.decryptionKeyAccountName)
        }
        else {
            newVerificationKey = NSData.secureRandomDataOfLength(self.dynamicType.defaultKeyLengthBytes)
            newDecryptionKey = NSData.secureRandomDataOfLength(self.dynamicType.defaultKeyLengthBytes)
        }
        super.init()
        
        if let newVerificationKey = newVerificationKey, newDecryptionKey = newDecryptionKey {
            self.verificationKey = newVerificationKey
            self.decryptionKey = newDecryptionKey
            self.apsDecoder = ZMAPSMessageDecoder(encryptionKey: self.decryptionKey, macKey: self.verificationKey)
        }
        else {
            self.decryptionKey = nil
            self.verificationKey = nil
            self.apsDecoder = nil
            return nil
        }
    }
    
    public func saveToKeychain() {
        ZMKeychain.setData(self.verificationKey, forAccount: self.dynamicType.verificationKeyAccountName)
        ZMKeychain.setData(self.decryptionKey, forAccount: self.dynamicType.decryptionKeyAccountName)
    }
 
    
    public func decryptDataDictionary(payload: NSDictionary) -> NSDictionary? {
        return self.apsDecoder.decodeAPSPayload(payload as [NSObject : AnyObject])
    }
}
