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


class FilePreprocessorTests : MessagingTest {

    var sut: FilePreprocessor!

    override func setUp() {
        super.setUp()
        sut = FilePreprocessor(managedObjectContext: self.syncMOC, versionPredicate: NSPredicate(value: true))
    }

}


private let testDataURL = Bundle(for: FilePreprocessorTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!
private let testData = try! Data(contentsOf: testDataURL)


// MARK: - File encryption
extension FilePreprocessorTests {

    func testThatItEncryptsAFileMessageWithTheSpecifiedVersion() {

        // given
        let name = "report.txt"
        sut = FilePreprocessor(managedObjectContext: syncMOC, versionPredicate: NSPredicate(format: "version > 2"))
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: syncMOC, expiresAfter:0.0)

        msg.setValue(3, forKey: "version")
        XCTAssertEqual(msg.version, 3)

        msg.transferState = .uploading
        msg.delivered = false
        syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)

        // when
        sut.objectsDidChange([msg])
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")

        // then
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "No file present")
    }

    func testThatItDoesNotEncryptAFileMessageWithAVersinonOtherThanTheSpecifiedVersion() {

        // given
        let name = "report.txt"
        sut = FilePreprocessor(managedObjectContext: syncMOC, versionPredicate: NSPredicate(value: false))
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: syncMOC, expiresAfter:0.0)

        msg.setValue(3, forKey: "version")
        XCTAssertEqual(msg.version, 3)
        syncMOC.saveOrRollback()

        msg.transferState = .uploading
        msg.delivered = false
        syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)

        // when
        sut.objectsDidChange([msg])
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")

        // then
        XCTAssertNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "File present where it should not be")
    }
    
    func testThatItEncryptsAFileMessageSentByMe() {
        
        // given
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .uploading
        msg.delivered = false
        self.syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        self.syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")

        // then
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "No file")
    }

    func testThatItSetsTheEncryptionKeysOnTheFileMessage() {
        
        // given
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .uploading
        msg.delivered = false
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)

        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
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
        
        // given
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        XCTAssertFalse(msg.isReadyToUploadFile)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
        XCTAssertTrue(msg.isReadyToUploadFile)
        XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingPlaceholder)
    }
    
    func testThatItDoesNotEncryptAFileMessageThatAlreadyHasAnEncryptedVersion() {
        
        // given
        let encData = "foobar".data(using: String.Encoding.utf8)!
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .uploading
        msg.delivered = false
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: true, data: encData)

        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
        XCTAssertEqual(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), encData, "File was overwritten")

    }
    
    func testThatItDoesNotEncryptAnImageMessage() {
        
        // given
        let msg = ZMAssetClientMessage(originalImageData: testData, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
        XCTAssertFalse(msg.isReadyToUploadFile)
        XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingPlaceholder)
    }
    
    func testThatItDoesNotEncryptAFileMessageSentBySomeoneElse() {
        
        // given
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.delivered = true
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageReadyToBeDownloaded() {
        
        // given
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .uploaded
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageFailedToUpload() {
        
        // given
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .failedUpload
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageFailedToDownload() {
        
        // given
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .failedDownload
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }
    
    func testThatItDoesNotEncryptAFileMessageNotFromThisDevice() {
        
        // given
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
        msg.transferState = .uploading
        msg.delivered = true
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
    }

    func testThatItReturnsAFetchRequestMatchingTheRightObjects() {
        
        // given
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
        
        // when
        let req = sut.fetchRequestForTrackedObjects()!
        
        // then
        guard let objects = try! self.syncMOC.fetch(req) as? [ZMAssetClientMessage] else { XCTFail(); return; }
        XCTAssertEqual(objects, [msg])
    }
}


// MARK: - Ephemeral
extension FilePreprocessorTests {

    func testThatItEncryptsAnEphemeralFileMessageSentByMe() {
        
        // given
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:10.0)
        msg.transferState = .uploading
        msg.delivered = false
        self.syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        self.syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)
        XCTAssertTrue(msg.isEphemeral)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "No file")
        XCTAssertTrue(msg.isEphemeral)
    }
    
    func testThatItSetsTheEncryptionKeysOnTheEphemeralFileMessage() {
        
        // given
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:10.0)
        msg.transferState = .uploading
        msg.delivered = false
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
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
        
        // given
        let name = "report.txt"
        let metadata = ZMFileMetadata(fileURL: testDataURL)
        let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:10.0)
        XCTAssertTrue(msg.isEphemeral)
        self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
        XCTAssertFalse(msg.isReadyToUploadFile)
        
        // when
        sut.objectsDidChange(Set(arrayLiteral: msg))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), "Timeout")
        
        // then
        XCTAssertTrue(msg.isReadyToUploadFile)
        XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingPlaceholder)
        XCTAssertTrue(msg.isEphemeral)
    }

}

