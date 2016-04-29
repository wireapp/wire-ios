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


import XCTest
import ZMCDataModel

class FilePreprocessorTests : MessagingTest {

    override func setUp() {
        super.setUp()
    }
}

private let testDataURL = NSBundle(forClass: FilePreprocessorTests.self).URLForResource("Lorem Ipsum", withExtension: "txt")!
private let testData = NSData(contentsOfURL: testDataURL)!


// MARK: - File encryption
extension FilePreprocessorTests {
    
    func testThatItEncryptsAFileMessageSentByMe() {
        
        // given
        let name = "report.txt"
        let sut = FilePreprocessor(managedObjectContext: self.syncMOC)
        let msg = ZMAssetClientMessage(assetURL: testDataURL, size: UInt64(testData.length), mimeType: "txt", name: name, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        msg.transferState = .Uploading
        msg.delivered = false
        self.syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        self.syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5), "Timeout")

        // then
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "No file")
    }

    func testThatItSetsTheEncryptionKeysOnTheFileMessage() {
        
        // given
        let name = "report.txt"
        let sut = FilePreprocessor(managedObjectContext: self.syncMOC)
        let msg = ZMAssetClientMessage(assetURL: testDataURL, size: UInt64(testData.length), mimeType: "txt", name: name, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        msg.transferState = .Uploading
        msg.delivered = false
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)

        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5), "Timeout")
        
        // then
        let encryptedData = self.uiMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true)

        XCTAssertEqual(msg.genericAssetMessage.asset.uploaded.sha256, encryptedData?.zmSHA256Digest())
        if let key = msg.genericAssetMessage.asset.uploaded.otrKey where key.length > 0 {
            XCTAssertEqual(encryptedData?.zmDecryptPrefixedPlainTextIVWithKey(key), testData)
        }
        else {
            XCTFail("No key")
        }
    }

    func testThatItSetsReadyToUploadOnTheFileMessage() {
        
        // given
        let name = "report.txt"
        let sut = FilePreprocessor(managedObjectContext: self.syncMOC)
        let msg = ZMAssetClientMessage(assetURL: testDataURL, size: UInt64(testData.length), mimeType: "txt", name: name, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        msg.transferState = .Uploading
        msg.delivered = false
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5), "Timeout")
        
        // then
        XCTAssertTrue(msg.needsToUploadPreview)
        XCTAssertFalse(msg.needsToUploadMedium)
    }
    
    func testThatItDoesNotEncryptAFileMessageThatAlreadyHasAnEncryptedVersion() {
        
        // given
        let encData = "foobar".dataUsingEncoding(NSUTF8StringEncoding)!
        let name = "report.txt"
        let sut = FilePreprocessor(managedObjectContext: self.syncMOC)
        let msg = ZMAssetClientMessage(assetURL: testDataURL, size: UInt64(testData.length), mimeType: "txt", name: name, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        msg.transferState = .Uploading
        msg.delivered = false
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: true, data: encData)

        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5), "Timeout")
        
        // then
        XCTAssertEqual(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), encData, "File was overwritten")

    }
    
    func testThatItDoesNotEncryptAnImageMessage() {
        
        // given
        let sut = FilePreprocessor(managedObjectContext: self.syncMOC)
        let msg = ZMAssetClientMessage(originalImageData: testData, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5), "Timeout")
        
        // then
        XCTAssertFalse(msg.needsToUploadPreview)
        XCTAssertFalse(msg.needsToUploadMedium)
    }
    
    func testThatItDoesNotEncryptAFileMessageSentBySomeoneElse() {
        
        // given
        let name = "report.txt"
        let sut = FilePreprocessor(managedObjectContext: self.syncMOC)
        let msg = ZMAssetClientMessage(assetURL: testDataURL, size: UInt64(testData.length), mimeType: "txt", name: name, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        msg.delivered = true
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5), "Timeout")
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageReadyToBeDownloaded() {
        
        // given
        let name = "report.txt"
        let sut = FilePreprocessor(managedObjectContext: self.syncMOC)
        let msg = ZMAssetClientMessage(assetURL: testDataURL, size: UInt64(testData.length), mimeType: "txt", name: name, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        msg.transferState = .Uploaded
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5), "Timeout")
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageFailedToUpload() {
        
        // given
        let name = "report.txt"
        let sut = FilePreprocessor(managedObjectContext: self.syncMOC)
        let msg = ZMAssetClientMessage(assetURL: testDataURL, size: UInt64(testData.length), mimeType: "txt", name: name, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        msg.transferState = .FailedUpload
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5), "Timeout")
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageFailedToDownload() {
        
        // given
        let name = "report.txt"
        let sut = FilePreprocessor(managedObjectContext: self.syncMOC)
        let msg = ZMAssetClientMessage(assetURL: testDataURL, size: UInt64(testData.length), mimeType: "txt", name: name, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        msg.transferState = .FailedDownload
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5), "Timeout")
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageNotFromThisDevice() {
        
        // given
        let name = "report.txt"
        let sut = FilePreprocessor(managedObjectContext: self.syncMOC)
        let msg = ZMAssetClientMessage(assetURL: testDataURL, size: UInt64(testData.length), mimeType: "txt", name: name, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        msg.transferState = .Uploading
        msg.delivered = true
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5), "Timeout")
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }

    func testThatItReturnsAFetchRequestMatchingTheRightObjects() {
        
        // given
        let sut = FilePreprocessor(managedObjectContext: self.syncMOC)
        let msg = ZMAssetClientMessage(assetURL: testDataURL, size: UInt64(testData.length), mimeType: "txt", name: name!, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        msg.transferState = .Uploading
        msg.delivered = false
        
        let otherMsg = ZMAssetClientMessage(originalImageData: testData, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        otherMsg.transferState = .FailedUpload
        otherMsg.delivered = false
        
        let wrongMsg = ZMAssetClientMessage(assetURL: testDataURL, size: UInt64(testData.length), mimeType: "txt", name: name!, nonce: NSUUID.createUUID(), managedObjectContext: self.syncMOC)
        wrongMsg.transferState = .Uploading
        wrongMsg.delivered = true
        self.syncMOC.saveOrRollback()
        
        // when
        let req = sut.fetchRequestForTrackedObjects()!
        
        // then
        guard let objects = try! self.syncMOC.executeFetchRequest(req) as? [ZMAssetClientMessage] else { XCTFail(); return; }
        XCTAssertEqual(objects, [msg])
    }
}
