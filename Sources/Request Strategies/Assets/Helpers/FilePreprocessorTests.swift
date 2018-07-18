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
import WireDataModel
@testable import WireRequestStrategy


class FilePreprocessorTests : MessagingTestBase {

    var sut: FilePreprocessor!
    var oneToOneConversationOnSync : ZMConversation!
    
    override func setUp() {
        super.setUp()
        self.syncMOC.performGroupedAndWait { moc in
            self.sut = FilePreprocessor(managedObjectContext: moc, filter: NSPredicate(value: true))
            self.oneToOneConversationOnSync = moc.object(with: self.oneToOneConversation.objectID) as! ZMConversation
        }
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
}


private let testDataURL = Bundle(for: FilePreprocessorTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!
private let testData = try! Data(contentsOf: testDataURL)


// MARK: - File encryption
extension FilePreprocessorTests {
    
    func testThatItEncryptsAFileMessageWithTheSpecifiedVersion() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            self.sut = FilePreprocessor(managedObjectContext: self.syncMOC, filter: NSPredicate(format: "version > 2"))
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            XCTAssertEqual(msg.version, 3)
            
            self.syncMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            self.syncMOC.zm_fileAssetCache.deleteAssetData(msg, encrypted: true)
            
            // WHEN
            self.sut.objectsDidChange([msg])
            
            // THEN
            XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg, encrypted: true), "No file present")
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageWithAVersinonOtherThanTheSpecifiedVersion() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            self.sut = FilePreprocessor(managedObjectContext: self.syncMOC, filter: NSPredicate(value: false))
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            XCTAssertEqual(msg.version, 3)
            self.syncMOC.saveOrRollback()
            self.syncMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            self.syncMOC.zm_fileAssetCache.deleteAssetData(msg, encrypted: true)
            
            // WHEN
            self.sut.objectsDidChange([msg])
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg, encrypted: true), "File present where it should not be")
        }
    }
    
    func testThatItEncryptsAFileMessageSentByMe() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            self.syncMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            self.syncMOC.zm_fileAssetCache.deleteAssetData(msg, encrypted: true)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg, encrypted: true), "No file")
        }
    }
    
    func testThatItSetsTheEncryptionKeysOnTheFileMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            let encryptedData = self.uiMOC.zm_fileAssetCache.assetData(msg, encrypted: true)
            guard let genericAssetMessage = msg.genericAssetMessage else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(genericAssetMessage.asset.uploaded.sha256, encryptedData?.zmSHA256Digest())
            if let key = genericAssetMessage.asset.uploaded.otrKey , key.count > 0 {
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
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            msg.uploadState = .uploadingFullAsset
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            XCTAssertFalse(msg.v3_isReadyToUploadFile)
            XCTAssertTrue(ZMAssetClientMessage.v3_needsPreprocessingFilter.evaluate(with: msg))
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertTrue(msg.v3_isReadyToUploadFile)
            XCTAssertFalse(ZMAssetClientMessage.v3_needsPreprocessingFilter.evaluate(with: msg))
            XCTAssertEqual(msg.uploadState, AssetUploadState.uploadingFullAsset)
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageThatAlreadyHasAnEncryptedVersion() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let encData = "foobar".data(using: String.Encoding.utf8)!
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: true, data: encData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertEqual(self.syncMOC.zm_fileAssetCache.assetData(msg, encrypted: true), encData, "File was overwritten")
        }
    }
    
    func testThatItDoesNotEncryptAnImageMessage() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let msg = self.oneToOneConversationOnSync.appendMessage(withImageData: self.verySmallJPEGData()) as! ZMAssetClientMessage
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertFalse(msg.v3_isReadyToUploadFile)
            XCTAssertEqual(msg.uploadState, AssetUploadState.uploadingFullAsset)
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageSentBySomeoneElse() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            msg.delivered = true
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg, encrypted: true), "Should not have file")
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageReadyToBeDownloaded() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            msg.transferState = .uploaded
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg, encrypted: true), "Should not have file")
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageFailedToUpload() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            msg.transferState = .failedUpload
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg, encrypted: true), "Should not have file")
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageFailedToDownload() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            msg.transferState = .failedDownload
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg, encrypted: true), "Should not have file")
        }
    }
    
    func testThatItDoesNotEncryptAFileMessageNotFromThisDevice() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            msg.transferState = .uploading
            msg.delivered = true
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg, encrypted: true), "Should not have file")
        }
    }
    
    func testThatItReturnsAFetchRequestMatchingTheRightObjects() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            msg.transferState = .uploading
            msg.delivered = false
            
            let otherMsg = self.oneToOneConversationOnSync.appendMessage(withImageData: self.verySmallJPEGData()) as! ZMAssetClientMessage
            otherMsg.transferState = .failedUpload
            otherMsg.delivered = false
            
            let wrongMsg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
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
            self.oneToOneConversationOnSync.messageDestructionTimeout = .local(.tenSeconds)
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            self.syncMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            self.syncMOC.zm_fileAssetCache.deleteAssetData(msg, encrypted: true)
            XCTAssertTrue(msg.isEphemeral)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg, encrypted: true), "No file")
            XCTAssertTrue(msg.isEphemeral)
        }
    }
    
    func testThatItSetsTheEncryptionKeysOnTheEphemeralFileMessage() {
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            self.oneToOneConversationOnSync.messageDestructionTimeout = .local(.tenSeconds)
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            let encryptedData = self.uiMOC.zm_fileAssetCache.assetData(msg, encrypted: true)
            guard let genericAssetMessage = msg.genericAssetMessage else {
                XCTFail()
                return
            }
            XCTAssertEqual(genericAssetMessage.ephemeral.asset.uploaded.sha256, encryptedData?.zmSHA256Digest())
            if let key = genericAssetMessage.ephemeral.asset.uploaded.otrKey , key.count > 0 {
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
            self.oneToOneConversationOnSync.messageDestructionTimeout = .local(.tenSeconds)
            let metadata = ZMFileMetadata(fileURL: testDataURL)
            let msg = self.oneToOneConversationOnSync.appendMessage(with: metadata) as! ZMAssetClientMessage
            XCTAssertTrue(msg.isEphemeral)
            self.uiMOC.zm_fileAssetCache.storeAssetData(msg, encrypted: false, data: testData)
            do {
                guard let asset = msg.genericAssetMessage?.assetData else { return XCTFail() }
                XCTAssertFalse(asset.uploaded.hasOtrKey())
                XCTAssertFalse(asset.uploaded.hasSha256())
            }
            
            // WHEN
            self.sut.objectsDidChange(Set(arrayLiteral: msg))
            
            // THEN
            do {
                guard let asset = msg.genericAssetMessage?.assetData else { return XCTFail() }
                XCTAssert(asset.uploaded.hasOtrKey())
                XCTAssert(asset.uploaded.hasSha256())
            }
            XCTAssertFalse(msg.v3_isReadyToUploadFile)
            XCTAssertEqual(msg.uploadState, AssetUploadState.uploadingPlaceholder)
            XCTAssertTrue(msg.isEphemeral)
        }
    }
    
}

