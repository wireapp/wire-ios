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
import ZMCDataModel
@testable import WireMessageStrategy


class FilePreprocessorTests : MessagingTestBase {

    var sut: FilePreprocessor!

    override func setUp() {
        super.setUp()
        sut = FilePreprocessor(managedObjectContext: self.syncMOC, filter: NSPredicate(value: true))
    }

}


private let testDataURL = Bundle(for: FilePreprocessorTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!
private let testData = try! Data(contentsOf: testDataURL)


// MARK: - File encryption
extension FilePreprocessorTests {

    func testThatItEncryptsAFileMessageWithTheSpecifiedVersion() {

        // GIVEN
        let name = "report.txt"
        sut = FilePreprocessor(managedObjectContext: syncMOC, filter: NSPredicate(format: "version > 2"))
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: syncMOC, expiresAfter:0.0)

        msg.setValue(3, forKey: "version")
        XCTAssertEqual(msg.version, 3)

        msg.transferState = .uploading
        msg.delivered = false
        syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)

        // WHEN
        sut.objectsDidChange([msg])
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")

        // THEN
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "No file present")
    }

    func testThatItDoesNotEncryptAFileMessageWithAVersinonOtherThanTheSpecifiedVersion() {

        // GIVEN
        let name = "report.txt"
        sut = FilePreprocessor(managedObjectContext: syncMOC, filter: NSPredicate(value: false))
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: syncMOC, expiresAfter:0.0)

        msg.setValue(3, forKey: "version")
        XCTAssertEqual(msg.version, 3)
        syncMOC.saveOrRollback()

        msg.transferState = .uploading
        msg.delivered = false
        syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)

        // WHEN
        sut.objectsDidChange([msg])
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")

        // THEN
        XCTAssertNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "File present where it should not be")
    }
    
    func testThatItEncryptsAFileMessageSentByMe() {
        
        // GIVEN
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .uploading
        msg.delivered = false
        self.syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        self.syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)
        
        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")

        // THEN
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "No file")
    }

    func testThatItSetsTheEncryptionKeysOnTheFileMessage() {
        
        // GIVEN
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .uploading
        msg.delivered = false
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)

        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        let encryptedData = self.uiMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true)

        XCTAssertEqual(msg.genericAssetMessage.asset.uploaded.sha256, encryptedData?.zmSHA256Digest())
        if let key = msg.genericAssetMessage.asset.uploaded.otrKey , key.count > 0 {
            XCTAssertEqual(encryptedData?.zmDecryptPrefixedPlainTextIV(key: key), testData)
        }
        else {
            XCTFail("No key")
        }
    }

    func testThatItSetsReadyToUploadOnTheFileMessage() {
        
        // GIVEN
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        XCTAssertFalse(msg.isReadyToUploadFile)
        
        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        XCTAssertTrue(msg.isReadyToUploadFile)
        XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingPlaceholder)
    }
    
    func testThatItDoesNotEncryptAFileMessageThatAlreadyHasAnEncryptedVersion() {
        
        // GIVEN
        let encData = "foobar".data(using: String.Encoding.utf8)!
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .uploading
        msg.delivered = false
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: true, data: encData)

        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        XCTAssertEqual(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), encData, "File was overwritten")

    }
    
    func testThatItDoesNotEncryptAnImageMessage() {
        
        // GIVEN
        let msg = ZMAssetClientMessage(originalImageData: testData, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        
        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        XCTAssertFalse(msg.isReadyToUploadFile)
        XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingPlaceholder)
    }
    
    func testThatItDoesNotEncryptAFileMessageSentBySomeoneElse() {
        
        // GIVEN
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.delivered = true
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageReadyToBeDownloaded() {
        
        // GIVEN
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .uploaded
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageFailedToUpload() {
        
        // GIVEN
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .failedUpload
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageFailedToDownload() {
        
        // GIVEN
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .failedDownload
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageNotFromThisDevice() {
        
        // GIVEN
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .uploading
        msg.delivered = true
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }

    func testThatItReturnsAFetchRequestMatchingTheRightObjects() {
        
        // GIVEN
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .uploading
        msg.delivered = false
        
        let otherMsg = ZMAssetClientMessage(originalImageData: testData, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        otherMsg.transferState = .failedUpload
        otherMsg.delivered = false
        
        
//        let wrongMetadata = ZMFileMetadata(fileURL: testDataURL)
        let wrongMsg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        wrongMsg.transferState = .uploading
        wrongMsg.delivered = true
        self.syncMOC.saveOrRollback()
        
        // WHEN
        let req = sut.fetchRequestForTrackedObjects()!
        
        // THEN
        guard let objects = try! self.syncMOC.fetch(req) as? [ZMAssetClientMessage] else { XCTFail(); return; }
        XCTAssertEqual(objects, [msg])
    }
}


// MARK: - Ephemeral
extension FilePreprocessorTests {

    func testThatItEncryptsAnEphemeralFileMessageSentByMe() {
        
        // GIVEN
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:10.0)
        msg.transferState = .uploading
        msg.delivered = false
        self.syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        self.syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)
        XCTAssertTrue(msg.isEphemeral)
        
        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "No file")
        XCTAssertTrue(msg.isEphemeral)
    }
    
    func testThatItSetsTheEncryptionKeysOnTheEphemeralFileMessage() {
        
        // GIVEN
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:10.0)
        msg.transferState = .uploading
        msg.delivered = false
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        let encryptedData = self.uiMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true)
        
        XCTAssertEqual(msg.genericAssetMessage.ephemeral.asset.uploaded.sha256, encryptedData?.zmSHA256Digest())
        if let key = msg.genericAssetMessage.ephemeral.asset.uploaded.otrKey , key.count > 0 {
            XCTAssertEqual(encryptedData?.zmDecryptPrefixedPlainTextIV(key: key), testData)
        }
        else {
            XCTFail("No key")
        }
    }
    
    func testThatItSetsReadyToUploadOnTheEphemeralFileMessage() {
        
        // GIVEN
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:10.0)
        XCTAssertTrue(msg.isEphemeral)
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        XCTAssertFalse(msg.isReadyToUploadFile)
        
        // WHEN
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // THEN
        XCTAssertTrue(msg.isReadyToUploadFile)
        XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingPlaceholder)
        XCTAssertTrue(msg.isEphemeral)
    }

}

