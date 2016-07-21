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


import XCTest
import ZMTesting

class NSData_ZMSCryptoTests: XCTestCase {
    
    /// Key to use to read the test data
    var sampleKey : NSData {
        return NSData(base64EncodedString: "A5NEu/TETPw0XT2G4EUNVB4ZRDmi05wetFJEucHmlXI=", options: NSDataBase64DecodingOptions())!
    }
    
    var sampleEncryptedImageData : NSData {
        let dataPath = NSBundle(forClass: self.dynamicType).pathForResource("android_image", ofType: "encrypted")
        return NSData(contentsOfFile: dataPath!)!
    }
    
    var sampleDecryptedImageData : NSData {
        let dataPath = NSBundle(forClass: self.dynamicType).pathForResource("android_image", ofType: "decrypted")
        return NSData(contentsOfFile: dataPath!)!
    }
    
    var sampleSHADigestOfImageData : NSData {
        return NSData(base64EncodedString: "yeElK+949uC/WdbLxx61b1+JWx2uyk07YEVU/7KeeV8=", options: NSDataBase64DecodingOptions())!
    }
    
    var sampleSHAKeyOfImageData : NSData {
        return NSData(base64EncodedString: "UnxAVuKFdWs53VwIihrfPbvUNwk5nqCbM1tb+Row8ng=", options: NSDataBase64DecodingOptions())!
    }
}

// MARK: - Encryption with plaintext IV
extension NSData_ZMSCryptoTests {
    
    func testThatItEncryptsAndDecryptsData_plaintextIV() {
        
        // given
        let data = self.sampleDecryptedImageData
        let key = self.sampleKey
        
        // when
        let encryptedData = data.zmEncryptPrefixingPlainTextIVWithKey(key)
        
        // then
        XCTAssertNotEqual(encryptedData, data)
        
        // and when
        let decryptedData = encryptedData.zmDecryptPrefixedPlainTextIVWithKey(key)
        
        // then
        AssertOptionalEqual(decryptedData, expression2: data)
    }
    
    func testThatTheEncodedDataIsDifferentEveryTime_plaintextIV() {
        
        // given
        var generatedDataSet = Set<NSData>()
        let sampleData = self.sampleDecryptedImageData
        
        // when
        for _ in 0..<100 {
            let data = sampleData.zmEncryptPrefixingPlainTextIVWithKey(self.sampleKey)
            XCTAssertFalse(generatedDataSet.contains(data))
            generatedDataSet.insert(data)
        }
    }
    
    func testThatItDecryptsAndroidImage_plaintextIV() {
        
        // given
        let encryptedImage = self.sampleEncryptedImageData
        let expectedDecryptedImage = self.sampleDecryptedImageData
        
        // when
        let decryptedImage = encryptedImage.zmDecryptPrefixedPlainTextIVWithKey(self.sampleKey)
        
        // then
        XCTAssertEqual(decryptedImage, expectedDecryptedImage)
    }
    
    func testThatItGeneratesUniqueEncryptionKey() {
        var generatedDataSet = Set<NSData>()
        for _ in 0..<100 {
            let data = NSData.randomEncryptionKey()
            XCTAssertFalse(generatedDataSet.contains(data))
            generatedDataSet.insert(data)
        }
    }

}

// MARK: - Encrypted IV
extension NSData_ZMSCryptoTests {
    
    func testThatItEncryptsAndDecryptsData_encryptedIV() {
        
        // given
        let data = self.sampleDecryptedImageData
        let key = self.sampleKey
        
        // when
        let encryptedData = data.zmEncryptPrefixingIVWithKey(key)
        
        // then
        XCTAssertNotEqual(encryptedData, data)
        
        // and when
        let decryptedData = encryptedData.zmDecryptPrefixedIVWithKey(key)
        
        // then
        AssertOptionalEqual(decryptedData, expression2: data)
    }
    
    func testThatTheEncodedDataIsDifferentEveryTime_encryptedIV() {
        
        // given
        var generatedDataSet = Set<NSData>()
        let sampleData = self.sampleDecryptedImageData
        
        // when
        for _ in 0..<100 {
            let data = sampleData.zmEncryptPrefixingIVWithKey(self.sampleKey)
            XCTAssertFalse(generatedDataSet.contains(data))
            generatedDataSet.insert(data)
        }
    }
}

// MARK: - Random data generation
extension NSData_ZMSCryptoTests {
    
    func testThatItGeneratesRandomDataWithTheRightSize() {
        
        // positive data
        XCTAssertEqual(NSData.secureRandomDataOfLength(128).length, 128)
        XCTAssertEqual(NSData.secureRandomDataOfLength(12).length, 12)
        XCTAssertEqual(NSData.secureRandomDataOfLength(789).length, 789)
        XCTAssertEqual(NSData.secureRandomDataOfLength(0).length, 0)
    }
    
    func testThatItGeneratesDifferentDataValues() {
        var generatedDataSet = Set<NSData>()
        for _ in 0..<100 {
            let data = NSData.secureRandomDataOfLength(10)
            XCTAssertFalse(generatedDataSet.contains(data))
            generatedDataSet.insert(data)
        }
    }
    
    func testThatItReturnsNilIfDecryptingKeyIsNotOfAES256Length() {
        
        let badKey = self.sampleKey.subdataWithRange(NSRange(location: 0, length: 16))
        XCTAssertNil(self.sampleEncryptedImageData.zmDecryptPrefixedPlainTextIVWithKey(badKey))
        XCTAssertNotNil(self.sampleEncryptedImageData.zmDecryptPrefixedPlainTextIVWithKey(self.sampleKey))
    }
}


// MARK: - Hashing
extension NSData_ZMSCryptoTests {
    
    var samplePlainData : NSData {
        let text = "A HMAC is a small set of data that helps authenticate the nature of message; it protects the integrity and the authenticity of the message."
        return text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
    }
    
    var sampleHashKey : NSData {
        let key = "nhrMEF8DX1ymQFJu4Xwbb"
        return key.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
    }

    var sampleSHA256Result : NSData {
        let base64 = "Qvrf4frfLVm5GxHhx6Y/evOXMy9lMXAHEpVamCtpEp4="
        return NSData(base64EncodedString: base64, options: NSDataBase64DecodingOptions())!
    }
    
    var sampleHMACSHA256Result : NSData {
        let base64 = "5Zsca82rFG2ymFH2SG16C5ds+AaBRm+kVrxzmr5wmyA="
        return NSData(base64EncodedString: base64, options: NSDataBase64DecodingOptions())!
    }
    
    var sampleMD5Result : NSData {
        let base64 = "gDcfGZldpqxaxaGNzyN16A=="
        return NSData(base64EncodedString: base64, options: NSDataBase64DecodingOptions())!
    }
    
    func testThatItCalculatesTheMD5Digest() {
        
        // given
        let data = samplePlainData
        
        // when
        let digest = data.zmMD5Digest()
        
        // then
        XCTAssertEqual(digest, sampleMD5Result)
    }
    
    func testThatItCalculatesTheSHA256Digest() {
        
        // given
        let data = samplePlainData
        
        // when
        let digest = data.zmSHA256Digest()
        
        // then
        XCTAssertEqual(digest, sampleSHA256Result)
    }
    
    func testThatItCalculatesTheHMACSHA256Digest() {
        
        // given
        let data = samplePlainData
        
        // when
        let digest = data.zmHMACSHA256DigestWithKey(sampleHashKey)
        
        // then
        XCTAssertEqual(digest, sampleHMACSHA256Result)
    }
    
    func testThatTheSHAOfTheTestImageMatches() {
        
        // given
        let data = sampleEncryptedImageData
        
        // when
        let digest = data.zmHMACSHA256DigestWithKey(sampleSHAKeyOfImageData)
        
        // then
        XCTAssertEqual(digest, sampleSHADigestOfImageData)
    }
    
    func testThatItCalculatesSHA256AsAndroid() {
        
        // given
        let dataPath = NSBundle(forClass: self.dynamicType).pathForResource("data_to_hash", ofType: "enc")
        let inputData = NSData(contentsOfFile: dataPath!)!
        let expectedHash = NSData(base64EncodedString: "qztWViO7awf67Z1EQbGt5ENiHMibJ5j9wc/DP3M6N3Y=", options: NSDataBase64DecodingOptions())!
        
        // when
        let digest = inputData.zmSHA256Digest()
        
        // then
        XCTAssertEqual(digest, expectedHash)
    }
    
    func testThatItGeneratesUniqueHashKey() {
        var generatedDataSet = Set<NSData>()
        for _ in 0..<100 {
            let data = NSData.zmRandomSHA256Key()
            XCTAssertFalse(generatedDataSet.contains(data))
            generatedDataSet.insert(data)
        }
    }
}
