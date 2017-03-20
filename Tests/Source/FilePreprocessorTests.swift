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
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let name = "report.txt"
            self.sut = FilePreprocessor(managedObjectContext: self.syncMOC, filter: NSPredicate(format: "version > 2"))
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            
            msg.setValue(3, forKey: "version")
            XCTAssertEqual(msg.version, 3)
            
            msg.transferState = .uploading
            msg.delivered = false
            self.syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            self.syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)
            
            // WHEN
            self.sut.objectsDidChange([msg])
            
            // THEN
            XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "No file present")
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageWithAVersinonOtherThanTheSpecifiedVersion() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let name = "report.txt"
            self.sut = FilePreprocessor(managedObjectContext: self.syncMOC, filter: NSPredicate(value: false))
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            
            msg.setValue(3, forKey: "version")
            XCTAssertEqual(msg.version, 3)
            self.syncMOC.saveOrRollback()
            
            msg.transferState = .uploading
            msg.delivered = false
            self.syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            self.syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)
            
            // WHEN
            self.sut.objectsDidChange([msg])
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "File present where it should not be")
        }
    }
    
    func testThatItEncryptsAFileMessageSentByMe() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let name = "report.txt"
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            msg.transferState = .uploading
            msg.delivered = false
            self.syncMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            self.syncMOC.zm_fileAssetCache.deleteAssetData(msg.nonce, fileName: name, encrypted: true)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "No file")
        }
    }
    
    func testThatItSetsTheEncryptionKeysOnTheFileMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let name = "report.txt"
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            msg.transferState = .uploading
            msg.delivered = false
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
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
    }
    
    func testThatItSetsReadyToUploadOnTheFileMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let name = "report.txt"
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            XCTAssertFalse(msg.isReadyToUploadFile)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertTrue(msg.isReadyToUploadFile)
            XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingPlaceholder)
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageThatAlreadyHasAnEncryptedVersion() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
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
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertEqual(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), encData, "File was overwritten")
        }
    }
    
    func testThatItDoesNotEncryptAnImageMessage() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let msg = ZMAssetClientMessage(originalImageData: testData, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertFalse(msg.isReadyToUploadFile)
            XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingPlaceholder)
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageSentBySomeoneElse() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let name = "report.txt"
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            msg.delivered = true
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageReadyToBeDownloaded() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let name = "report.txt"
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            msg.transferState = .uploaded
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageFailedToUpload() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let name = "report.txt"
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            msg.transferState = .failedUpload
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageFailedToDownload() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let name = "report.txt"
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            msg.transferState = .failedDownload
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageNotFromThisDevice() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let name = "report.txt"
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            msg.transferState = .uploading
            msg.delivered = true
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "Should not have file")
        }
    }
    
    func testThatItReturnsAFetchRequestMatchingTheRightObjects() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            msg.transferState = .uploading
            msg.delivered = false
            
            let otherMsg = ZMAssetClientMessage(originalImageData: testData, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            otherMsg.transferState = .failedUpload
            otherMsg.delivered = false
            
            let wrongMsg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:0.0)
            wrongMsg.transferState = .uploading
            wrongMsg.delivered = true
            self.syncMOC.saveOrRollback()
            
            // WHEN
            let req = self.sut.fetchRequestForTrackedObjects()!
            
            // THEN
            guard let objects = try! self.syncMOC.fetch(req) as? [ZMAssetClientMessage] else { XCTFail(); return; }
            XCTAssertEqual(objects, [msg])
        }
    }
}


// MARK: - Ephemeral
extension FilePreprocessorTests {
    
    func testThatItEncryptsAnEphemeralFileMessageSentByMe() {
        self.syncMOC.performGroupedBlockAndWait {
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
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: name, encrypted: true), "No file")
            XCTAssertTrue(msg.isEphemeral)
        }
    }
    
    func testThatItSetsTheEncryptionKeysOnTheEphemeralFileMessage() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let name = "report.txt"
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:10.0)
            msg.transferState = .uploading
            msg.delivered = false
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
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
    }
    
    func testThatItSetsReadyToUploadOnTheEphemeralFileMessage() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let name = "report.txt"
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = ZMAssetClientMessage(fileMetadata: metadata, nonce: UUID.create(), managedObjectContext: self.syncMOC, expiresAfter:10.0)
            XCTAssertTrue(msg.isEphemeral)
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg.nonce, fileName: name, encrypted: false, data: testData)
            XCTAssertFalse(msg.isReadyToUploadFile)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertTrue(msg.isReadyToUploadFile)
            XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingPlaceholder)
            XCTAssertTrue(msg.isEphemeral)
        }
    }
    
}

