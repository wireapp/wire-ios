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


import XCTest
import zmessaging
import ZMUtilities

class AssetEncryptionTests: BaseAssetDirectoryTest {
    
}

// MARK: - Decryption
extension AssetEncryptionTests {

    func testThatItDoesNotDecryptAFileThatDoesNotExistHMAC() {
        
        // when
        let result = AssetEncryption.decryptFileIfItMatchesDigest(NSUUID.createUUID(), format: .Medium, encryptionKey: NSData.randomEncryptionKey(), macKey: NSData.zmRandomSHA256Key(), macDigest: NSData.secureRandomDataOfLength(128))
        
        // then
        XCTAssertFalse(result)
        XCTAssertEqual(self.createdFilesInCache.count, 0)
    }
    
    func testThatItDoesNotDecryptAFileThatDoesNotExistSHA256() {
        
        // when
        let result = AssetEncryption.decryptFileIfItMatchesDigest(NSUUID.createUUID(), format: .Medium, encryptionKey: NSData.randomEncryptionKey(), sha256Digest: NSData.secureRandomDataOfLength(128))
        
        // then
        XCTAssertFalse(result)
        XCTAssertEqual(self.createdFilesInCache.count, 0)
    }
    
    func testThatItDoesNotDecryptAndDeletesAFileWithWrongHMAC() {
        
        // given
        let messageID = NSUUID.createUUID()
        AssetDirectory().storeAssetData(messageID, format: .Medium, encrypted: true, data: NSData.secureRandomDataOfLength(128))
        
        // when
        let result = AssetEncryption.decryptFileIfItMatchesDigest(messageID, format: .Medium, encryptionKey: NSData.randomEncryptionKey(), macKey: NSData.zmRandomSHA256Key(), macDigest: NSData.secureRandomDataOfLength(128))
        XCTAssertFalse(result)
        
        // then
        XCTAssertEqual(self.createdFilesInCache.count, 0)
    }
    
    func testThatItDoesNotDecryptAndDeletesAFileWithWrongSHA256() {
        
        // given
        let messageID = NSUUID.createUUID()
        AssetDirectory().storeAssetData(messageID, format: .Medium, encrypted: true, data: NSData.secureRandomDataOfLength(128))
        
        // when
        let result = AssetEncryption.decryptFileIfItMatchesDigest(messageID, format: .Medium, encryptionKey: NSData.randomEncryptionKey(), sha256Digest: NSData.secureRandomDataOfLength(128))
        XCTAssertFalse(result)
        
        // then
        XCTAssertEqual(self.createdFilesInCache.count, 0)
    }
    
    func testThatItDoesDecryptAndDeletesAFileWithTheRightHMAC() {
        
        // given
        let directory = AssetDirectory()
        let messageID = NSUUID.createUUID()
        let plainTextData = NSData.secureRandomDataOfLength(500)
        let key = NSData.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIVWithKey(key)
        let macKey = NSData.zmRandomSHA256Key()
        directory.storeAssetData(messageID, format: .Medium, encrypted: true, data: encryptedData)
        let mac = encryptedData.zmHMACSHA256DigestWithKey(macKey)
        
        // when
        let result = AssetEncryption.decryptFileIfItMatchesDigest(messageID, format: .Medium, encryptionKey: key, macKey: macKey, macDigest: mac)
        
        // then
        XCTAssertTrue(result)
        let decryptedData = directory.assetData(messageID, format: .Medium, encrypted: false)
        AssertOptionalEqual(decryptedData, expression2: plainTextData)
        XCTAssertEqual(self.createdFilesInCache.count, 1)
    }
    
    func testThatItDoesDecryptAndDeletesAFileWithTheRightSHA256() {
        
        // given
        let directory = AssetDirectory()
        let messageID = NSUUID.createUUID()
        let plainTextData = NSData.secureRandomDataOfLength(500)
        let key = NSData.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIVWithKey(key)
        directory.storeAssetData(messageID, format: .Medium, encrypted: true, data: encryptedData)
        let sha = encryptedData.zmSHA256Digest()
        
        // when
        let result = AssetEncryption.decryptFileIfItMatchesDigest(messageID, format: .Medium, encryptionKey: key, sha256Digest: sha)
        
        // then
        XCTAssertTrue(result)
        let decryptedData = directory.assetData(messageID, format: .Medium, encrypted: false)
        AssertOptionalEqual(decryptedData, expression2: plainTextData)
        XCTAssertEqual(self.createdFilesInCache.count, 1)
    }
}

// MARK: - Encryption
extension AssetEncryptionTests {
    
    func testThatReturnsNilWhenEncryptingAMissingFileWithHMAC() {
        
        // given
        let messageID = NSUUID.createUUID()
        
        // when
        let result = AssetEncryption.encryptFileAndComputeHMACDigest(messageID, format: .Preview)
        
        // then
        AssertOptionalNil(result)
        XCTAssertEqual(self.createdFilesInCache.count, 0)
    }
    
    func testThatItCreatesTheEncryptedFileAndDoesNotDeletedThePlainTextWithHMAC() {
        
        // given
        let directory = AssetDirectory()
        let messageID = NSUUID.createUUID()
        let plainData = NSData.secureRandomDataOfLength(500)
        directory.storeAssetData(messageID, format: .Preview, encrypted: false, data: plainData)
        
        // when
        _ = AssetEncryption.encryptFileAndComputeHMACDigest(messageID, format: .Preview)
        
        // then
        _  = directory.assetData(messageID, format: .Preview, encrypted: true)
        XCTAssertNotNil(directory.assetData(messageID, format: .Preview, encrypted: false))
        XCTAssertEqual(self.createdFilesInCache.count, 2)
    }
    
    func testThatItReturnsCorrectEncryptionResultWithHMAC() {
        // given
        let directory = AssetDirectory()
        let messageID = NSUUID.createUUID()
        let plainData = NSData.secureRandomDataOfLength(500)
        directory.storeAssetData(messageID, format: .Preview, encrypted: false, data: plainData)
        
        // when
        let result = AssetEncryption.encryptFileAndComputeHMACDigest(messageID, format: .Preview)
        
        // then
        let encryptedData = directory.assetData(messageID, format: .Preview, encrypted: true)
        AssertOptionalNotNil(result, "Result") { result in
            AssertOptionalNotNil(encryptedData, "Encrypted data") { encryptedData in
                let decodedData = encryptedData.zmDecryptPrefixedPlainTextIVWithKey(result.otrKey)
                XCTAssertEqual(decodedData, plainData)
                let mac = encryptedData.zmHMACSHA256DigestWithKey(result.macKey)
                XCTAssertEqual(mac, result.mac)
            }
        }
    }
    
    func testThatReturnsNilWhenEncryptingAMissingFileWithSHA256() {
        
        // given
        let messageID = NSUUID.createUUID()
        
        // when
        let result = AssetEncryption.encryptFileAndComputeSHA256Digest(messageID, format: .Preview)
        
        // then
        AssertOptionalNil(result)
        XCTAssertEqual(self.createdFilesInCache.count, 0)
    }
    
    func testThatItCreatesTheEncryptedFileAndDoesNotDeletedThePlainTextWithSHA256() {
        
        // given
        let directory = AssetDirectory()
        let messageID = NSUUID.createUUID()
        let plainData = NSData.secureRandomDataOfLength(500)
        directory.storeAssetData(messageID, format: .Preview, encrypted: false, data: plainData)
        
        // when
        _ = AssetEncryption.encryptFileAndComputeSHA256Digest(messageID, format: .Preview)
        
        // then
        _  = directory.assetData(messageID, format: .Preview, encrypted: true)
        XCTAssertNotNil(directory.assetData(messageID, format: .Preview, encrypted: false))
        XCTAssertEqual(self.createdFilesInCache.count, 2)
    }
    
    func testThatItReturnsCorrectEncryptionResultWithSHA256() {
        // given
        let directory = AssetDirectory()
        let messageID = NSUUID.createUUID()
        let plainData = NSData.secureRandomDataOfLength(500)
        directory.storeAssetData(messageID, format: .Preview, encrypted: false, data: plainData)
        
        // when
        let result = AssetEncryption.encryptFileAndComputeSHA256Digest(messageID, format: .Preview)
        
        // then
        let encryptedData = directory.assetData(messageID, format: .Preview, encrypted: true)
        AssertOptionalNotNil(result, "Result") { result in
            AssertOptionalNotNil(encryptedData, "Encrypted data") { encryptedData in
                let decodedData = encryptedData.zmDecryptPrefixedPlainTextIVWithKey(result.otrKey)
                XCTAssertEqual(decodedData, plainData)
                let sha = encryptedData.zmSHA256Digest()
                XCTAssertEqual(sha, result.sha256)
            }
        }
    }
}
