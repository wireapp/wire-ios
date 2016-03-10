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


import Foundation
import ZMProtos

public class AssetEncryption : NSObject {
    
    /// Decrypts an encrypted file in the asset directory to a decrypted file. Upon completion of the decryption, deletes the encrypted
    /// file. In case of error (the digest doesn't match, or any other error), deletes the original file and does not create a decrypted file.
    /// Returns whether the decryption was successful and the digest matched
    public static func decryptFileIfItMatchesDigest(nonce: NSUUID, format: ZMImageFormat, encryptionKey: NSData, macKey: NSData, macDigest: NSData) -> Bool {
        let directory = AssetDirectory()
        let encryptedData = directory.assetData(nonce, format: format, encrypted: true)
        if encryptedData == nil {
            return false
        }
        
        let mac = encryptedData!.zmHMACSHA256DigestWithKey(macKey)
        if mac != macDigest {
            directory.deleteAssetData(nonce, format: format, encrypted: true)
            return false
        }
        let plainData = encryptedData!.zmDecryptPrefixedPlainTextIVWithKey(encryptionKey)
        if let plainData = plainData {
            directory.storeAssetData(nonce, format: format, encrypted: false, data: plainData)
        }
        directory.deleteAssetData(nonce, format: format, encrypted: true)
        return true
    }
    
    /// Decrypts an encrypted file in the asset directory to a decrypted file. Upon completion of the decryption, deletes the encrypted
    /// file. In case of error (the digest doesn't match, or any other error), deletes the original file and does not create a decrypted file.
    /// Returns whether the decryption was successful and the digest matched
    public static func decryptFileIfItMatchesDigest(nonce: NSUUID, format: ZMImageFormat, encryptionKey: NSData, sha256Digest: NSData) -> Bool {
        let directory = AssetDirectory()
        let encryptedData = directory.assetData(nonce, format: format, encrypted: true)
        if encryptedData == nil {
            return false
        }
        
        let sha256 = encryptedData!.zmSHA256Digest()
        if sha256 != sha256Digest {
            directory.deleteAssetData(nonce, format: format, encrypted: true)
            return false
        }
        let plainData = encryptedData!.zmDecryptPrefixedPlainTextIVWithKey(encryptionKey)
        if let plainData = plainData {
            directory.storeAssetData(nonce, format: format, encrypted: false, data: plainData)
        }
        directory.deleteAssetData(nonce, format: format, encrypted: true)
        return true
    }
    
    /// Encrypts a file in an asset directory to an encrypted file, also computing the digest of the encrypted file
    public static func encryptFileAndComputeHMACDigest(nonce: NSUUID, format: ZMImageFormat) -> ZMImageAssetEncryptionKeys? {
        let directory = AssetDirectory()
        guard let plainData = directory.assetData(nonce, format: format, encrypted: false) else {
            return nil
        }
        
        let encryptionKey = NSData.randomEncryptionKey()
        let encryptedData = plainData.zmEncryptPrefixingPlainTextIVWithKey(encryptionKey)
        let macKey = NSData.zmRandomSHA256Key()
        let mac = encryptedData.zmHMACSHA256DigestWithKey(macKey)
        directory.storeAssetData(nonce, format: format, encrypted: true, data: encryptedData)
        
        return ZMImageAssetEncryptionKeys(otrKey: encryptionKey, macKey: macKey, mac: mac)
    }
    
    /// Encrypts a file in an asset directory to an encrypted file, also computing the digest of the encrypted file
    public static func encryptFileAndComputeSHA256Digest(nonce: NSUUID, format: ZMImageFormat) -> ZMImageAssetEncryptionKeys? {
        let directory = AssetDirectory()
        guard let plainData = directory.assetData(nonce, format: format, encrypted: false) else {
            return nil
        }
        
        let encryptionKey = NSData.randomEncryptionKey()
        let encryptedData = plainData.zmEncryptPrefixingPlainTextIVWithKey(encryptionKey)
        let hash = encryptedData.zmSHA256Digest()
        directory.storeAssetData(nonce, format: format, encrypted: true, data: encryptedData)
        
        return ZMImageAssetEncryptionKeys(otrKey: encryptionKey, sha256: hash)
    }
}