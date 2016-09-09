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
    var sampleKey : Data {
        return Data(base64Encoded: "A5NEu/TETPw0XT2G4EUNVB4ZRDmi05wetFJEucHmlXI=", options: NSData.Base64DecodingOptions())!
    }
    
    var sampleEncryptedImageData : Data {
        let dataPath = Bundle(for: type(of: self)).path(forResource: "android_image", ofType: "encrypted")
        return (try! Data(contentsOf: URL(fileURLWithPath: dataPath!)))
    }
    
    var sampleDecryptedImageData : Data {
        let dataPath = Bundle(for: type(of: self)).path(forResource: "android_image", ofType: "decrypted")
        return (try! Data(contentsOf: URL(fileURLWithPath: dataPath!)))
    }
    
    var sampleSHADigestOfImageData : Data {
        return Data(base64Encoded: "yeElK+949uC/WdbLxx61b1+JWx2uyk07YEVU/7KeeV8=", options: NSData.Base64DecodingOptions())!
    }
    
    var sampleSHAKeyOfImageData : Data {
        return Data(base64Encoded: "UnxAVuKFdWs53VwIihrfPbvUNwk5nqCbM1tb+Row8ng=", options: NSData.Base64DecodingOptions())!
    }
}

// MARK: - Encryption with plaintext IV
extension NSData_ZMSCryptoTests {
    
    func testThatItEncryptsAndDecryptsData_plaintextIV() {
        
        // given
        let data = self.sampleDecryptedImageData
        let key = self.sampleKey
        
        // when
        let encryptedData = data.zmEncryptPrefixingPlainTextIV(key: key)
        
        // then
        XCTAssertNotEqual(encryptedData, data)
        
        // and when
        let decryptedData = encryptedData.zmDecryptPrefixedPlainTextIV(key: key)
        
        // then
        AssertOptionalEqual(decryptedData, expression2: data)
    }
    
    func testThatTheEncodedDataIsDifferentEveryTime_plaintextIV() {
        
        // given
        var generatedDataSet = Set<Data>()
        let sampleData = self.sampleDecryptedImageData
        
        // when
        for _ in 0..<100 {
            let data = sampleData.zmEncryptPrefixingPlainTextIV(key: self.sampleKey)
            XCTAssertFalse(generatedDataSet.contains(data))
            generatedDataSet.insert(data)
        }
    }
    
    func testThatItDecryptsAndroidImage_plaintextIV() {
        
        // given
        let encryptedImage = self.sampleEncryptedImageData
        let expectedDecryptedImage = self.sampleDecryptedImageData
        
        // when
        let decryptedImage = encryptedImage.zmDecryptPrefixedPlainTextIV(key: self.sampleKey)
        
        // then
        XCTAssertEqual(decryptedImage, expectedDecryptedImage)
    }
    
    func testThatItGeneratesUniqueEncryptionKey() {
        var generatedDataSet = Set<Data>()
        for _ in 0..<100 {
            let data = Data.randomEncryptionKey()
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
        let encryptedData = data.zmEncryptPrefixingIV(key: key)
        
        // then
        XCTAssertNotEqual(encryptedData, data)
        
        // and when
        let decryptedData = encryptedData.zmDecryptPrefixedIV(key: key)
        
        // then
        AssertOptionalEqual(decryptedData, expression2: data)
    }
    
    func testThatTheEncodedDataIsDifferentEveryTime_encryptedIV() {
        
        // given
        var generatedDataSet = Set<Data>()
        let sampleData = self.sampleDecryptedImageData
        
        // when
        for _ in 0..<100 {
            let data = sampleData.zmEncryptPrefixingIV(key: self.sampleKey)
            XCTAssertFalse(generatedDataSet.contains(data))
            generatedDataSet.insert(data)
        }
    }
}

// MARK: - Random data generation
extension NSData_ZMSCryptoTests {
    
    func testThatItGeneratesRandomDataWithTheRightSize() {
        
        // positive data
        XCTAssertEqual(Data.secureRandomData(length: 128).count, 128)
        XCTAssertEqual(Data.secureRandomData(length: 12).count, 12)
        XCTAssertEqual(Data.secureRandomData(length: 789).count, 789)
        XCTAssertEqual(Data.secureRandomData(length: 0).count, 0)
    }
    
    func testThatItGeneratesDifferentDataValues() {
        var generatedDataSet = Set<Data>()
        for _ in 0..<100 {
            let data = Data.secureRandomData(length: 10)
            XCTAssertFalse(generatedDataSet.contains(data))
            generatedDataSet.insert(data)
        }
    }
    
    func testThatItReturnsNilIfDecryptingKeyIsNotOfAES256Length() {
        let badKey = self.sampleKey.subdata(in: Range(0...15))
        XCTAssertNil(self.sampleEncryptedImageData.zmDecryptPrefixedPlainTextIV(key: badKey))
        XCTAssertNotNil(self.sampleEncryptedImageData.zmDecryptPrefixedPlainTextIV(key: self.sampleKey))
    }
}


// MARK: - Hashing
extension NSData_ZMSCryptoTests {
    
    var samplePlainData : Data {
        let text = "A HMAC is a small set of data that helps authenticate the nature of message; it protects the integrity and the authenticity of the message."
        return text.data(using: String.Encoding.utf8, allowLossyConversion: true)!
    }
    
    var sampleHashKey : Data {
        let key = "nhrMEF8DX1ymQFJu4Xwbb"
        return key.data(using: String.Encoding.utf8, allowLossyConversion: true)!
    }

    var sampleSHA256Result : Data {
        let base64 = "Qvrf4frfLVm5GxHhx6Y/evOXMy9lMXAHEpVamCtpEp4="
        return Data(base64Encoded: base64, options: NSData.Base64DecodingOptions())!
    }
    
    var sampleHMACSHA256Result : Data {
        let base64 = "5Zsca82rFG2ymFH2SG16C5ds+AaBRm+kVrxzmr5wmyA="
        return Data(base64Encoded: base64, options: NSData.Base64DecodingOptions())!
    }
    
    var sampleMD5Result : Data {
        let base64 = "gDcfGZldpqxaxaGNzyN16A=="
        return Data(base64Encoded: base64, options: NSData.Base64DecodingOptions())!
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
        let digest = data.zmHMACSHA256Digest(key: sampleHashKey)
        
        // then
        XCTAssertEqual(digest, sampleHMACSHA256Result)
    }
    
    func testThatTheSHAOfTheTestImageMatches() {
        
        // given
        let data = sampleEncryptedImageData
        
        // when
        let digest = data.zmHMACSHA256Digest(key: sampleSHAKeyOfImageData)
        
        // then
        XCTAssertEqual(digest, sampleSHADigestOfImageData)
    }
    
    func testThatItCalculatesSHA256AsAndroid() {
        
        // given
        let dataPath = Bundle(for: type(of: self)).path(forResource: "data_to_hash", ofType: "enc")
        let inputData = try! Data(contentsOf: URL(fileURLWithPath: dataPath!))
        let expectedHash = Data(base64Encoded: "qztWViO7awf67Z1EQbGt5ENiHMibJ5j9wc/DP3M6N3Y=", options: NSData.Base64DecodingOptions())!
        
        // when
        let digest = inputData.zmSHA256Digest()
        
        // then
        XCTAssertEqual(digest, expectedHash)
    }
    
    func testThatItGeneratesUniqueHashKey() {
        var generatedDataSet = Set<Data>()
        for _ in 0..<100 {
            let data = Data.zmRandomSHA256Key()
            XCTAssertFalse(generatedDataSet.contains(data))
            generatedDataSet.insert(data)
        }
    }
}
