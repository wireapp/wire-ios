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


import Foundation
@testable import ZMCDataModel

class ZMAssetClientMessageTests : BaseZMClientMessageTests {
    
    var message: ZMAssetClientMessage!
    
    override func setUp() {
        super.setUp()
        self.setUpCaches()
    }
    
    override func tearDown() {
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(2))
        super.tearDown()
    }
    
    func appendImageMessage() {
        let imageData = verySmallJPEGData()
        let messageNonce = NSUUID.createUUID()
        message = conversation.appendOTRMessageWithImageData(imageData, nonce: messageNonce)
        
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImageWithData(imageData)
        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.length), mimeType:"image/jpeg")
        
        let keys = ZMImageAssetEncryptionKeys(otrKey: NSData.randomEncryptionKey(), macKey: NSData.zmRandomSHA256Key(), mac: NSData.zmRandomSHA256Key())
        
        let mediumMessage = ZMGenericMessage(mediumImageProperties: properties, processedImageProperties: properties, encryptionKeys: keys, nonce: messageNonce.transportString(), format: .Medium)
        message.addGenericMessage(mediumMessage)
        
        let previewMessage = ZMGenericMessage(mediumImageProperties: properties, processedImageProperties: properties, encryptionKeys: keys, nonce: messageNonce.transportString(), format: .Preview)
        message.addGenericMessage(previewMessage)
    }
    
    func appendImageMessage(format: ZMImageFormat) -> ZMAssetClientMessage {
        let otherFormat = format == ZMImageFormat.Medium ? ZMImageFormat.Preview : ZMImageFormat.Medium
        let imageData = verySmallJPEGData()
        let messageNonce = NSUUID.createUUID()
        let message = conversation.appendOTRMessageWithImageData(imageData, nonce: messageNonce)
        
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImageWithData(imageData)
        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.length), mimeType:"image/jpeg")
        
        let keys = ZMImageAssetEncryptionKeys(otrKey: NSData.randomEncryptionKey(), macKey: NSData.zmRandomSHA256Key(), mac: NSData.zmRandomSHA256Key())
        
        let imageMessage = ZMGenericMessage(mediumImageProperties: properties, processedImageProperties: properties, encryptionKeys: keys, nonce: messageNonce.transportString(), format: format)
        let emptyImageMessage = ZMGenericMessage(mediumImageProperties: nil, processedImageProperties: nil, encryptionKeys: nil, nonce: messageNonce.transportString(), format: otherFormat)
        message.addGenericMessage(imageMessage)
        message.addGenericMessage(emptyImageMessage)
        
        return message
    }

    func testThatItStoresPlainImageMessageDataForPreview() {
        let message = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC);
        message.nonce = NSUUID.createUUID()
        
        let imageData = self.verySmallJPEGData()
        XCTAssertNotNil(message.imageAssetStorage!.updateMessageWithImageData(imageData, forFormat: ZMImageFormat.Preview))
        
        let storedData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.Preview, encrypted: message.isEncrypted)
        AssertOptionalNotNil(storedData) { storedData in
            XCTAssertEqual(storedData, imageData)
        }
    }
    
    func testThatItStoresPlainImageMessageDataForMedium() {
        let message = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC);
        message.nonce = NSUUID.createUUID()
        
        let imageData = self.verySmallJPEGData()
        XCTAssertNotNil(message.imageAssetStorage!.updateMessageWithImageData(imageData, forFormat: ZMImageFormat.Medium))
        
        let storedData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.Medium, encrypted: message.isEncrypted)
        AssertOptionalNotNil(storedData) { storedData in
            XCTAssertEqual(storedData, imageData)
        }
    }
    
    func testThatItDecryptsEncryptedImageMessageData() {
        //given
        let message = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC);
        message.nonce = NSUUID.createUUID()
        message.isEncrypted = true
        let imageData = self.verySmallJPEGData()
        
        self.uiMOC.zm_imageAssetCache.storeAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false, data: imageData)
        
        let keys = self.uiMOC.zm_imageAssetCache.encryptFileAndComputeSHA256Digest(message.nonce, format: ZMImageFormat.Medium)
        let encryptedImageData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.Medium, encrypted: true)!
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)
        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImageWithData(imageData), length: UInt(imageData.length), mimeType: "image/jpeg")
        message.addGenericMessage(ZMGenericMessage(mediumImageProperties: imageProperties, processedImageProperties: imageProperties, encryptionKeys: keys, nonce: message.nonce.transportString(), format: ZMImageFormat.Medium))
        
        // when
        XCTAssertNotNil(message.imageAssetStorage!.updateMessageWithImageData(encryptedImageData, forFormat: ZMImageFormat.Medium))
        
        let decryptedImageData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)
        AssertOptionalNotNil(decryptedImageData) { decryptedImageData in
            XCTAssertEqual(decryptedImageData, imageData)
        }
    }
    
    func testThatItDeletesMessageIfImageMessageDataCanNotBeDecrypted() {
        //given
        let message = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC);
        message.nonce = NSUUID.createUUID()
        message.isEncrypted = true
        let imageData = self.verySmallJPEGData()
        
        //store original image
        self.uiMOC.zm_imageAssetCache.storeAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false, data: imageData)
        
        //encrypt image
        let keys = self.uiMOC.zm_imageAssetCache.encryptFileAndComputeSHA256Digest(message.nonce, format: ZMImageFormat.Medium)
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: true)
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)

        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImageWithData(imageData), length: UInt(imageData.length), mimeType: "image/jpeg")
        message.addGenericMessage(ZMGenericMessage(mediumImageProperties: imageProperties, processedImageProperties: imageProperties, encryptionKeys: keys, nonce: message.nonce.transportString(), format: ZMImageFormat.Medium))
        
        // when
        //pass in some wrong data (i.e. plain data instead of encrypted)
        XCTAssertNil(message.imageAssetStorage!.updateMessageWithImageData(imageData, forFormat: ZMImageFormat.Medium))
        
        let decryptedImageData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)
        XCTAssertNil(decryptedImageData)
        XCTAssertTrue(message.deleted);
    }
    
    
    func testThatItMarksMediumNeededToBeDownloadedIfNoEncryptedNoDecryptedDataStored() {
        
        let message = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC);
        message.nonce = NSUUID.createUUID()
        message.isEncrypted = true
        let imageData = self.verySmallJPEGData()
        
        self.uiMOC.zm_imageAssetCache.storeAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false, data: imageData)
        
        let keys = self.uiMOC.zm_imageAssetCache.encryptFileAndComputeSHA256Digest(message.nonce, format: ZMImageFormat.Medium)
        let encryptedImageData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.Medium, encrypted: true)!
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)
        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImageWithData(imageData), length: UInt(imageData.length), mimeType: "image/jpeg")
        message.addGenericMessage(ZMGenericMessage(mediumImageProperties: imageProperties, processedImageProperties: imageProperties, encryptionKeys: keys, nonce: message.nonce.transportString(), format: ZMImageFormat.Medium))
        
        // when
        XCTAssertNotNil(message.imageAssetStorage!.updateMessageWithImageData(encryptedImageData, forFormat: ZMImageFormat.Medium))
        XCTAssertTrue(message.hasDownloadedImage)
        
        // pretend that there are no encrypted no decrypted message data stored
        // i.e. cache folder is cleared but message is already processed
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: ZMImageFormat.Medium, encrypted: false)
        
        XCTAssertNil(message.imageMessageData?.mediumData)
        XCTAssertFalse(message.hasDownloadedImage)
    }
    
}

// MARK: - ZMAsset / ZMFileMessageData

extension ZMAssetClientMessageTests {
    
    func testThatItCreatesFileAssetMessageInTheRightStateToBeUploaded()
    {
        // given
        let nonce = NSUUID.createUUID()
        let mimeType = "text/plain"
        let data = createTestFile(testURL)
        defer { removeTestFile(testURL) }
        let fileMetadata = ZMFileMetadata(fileURL: testURL)
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC)
        
        // then
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.delivered)
        XCTAssertEqual(sut.transferState, ZMFileTransferState.Uploading)
        XCTAssertEqual(sut.filename, testURL.lastPathComponent)
        XCTAssertNotNil(sut.fileMessageData)
    }
    
    func testThatItHasDownloadedFileWhenTheFileIsOnDisk()
    {
        // given
        let nonce = NSUUID.createUUID()
        let mimeType = "text/plain"
        let data = createTestFile(testURL)
        defer { removeTestFile(testURL) }
        let fileMetadata = ZMFileMetadata(fileURL: testURL)
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC)
        
        // then
        XCTAssertTrue(sut.hasDownloadedFile)
        XCTAssertFalse(sut.hasDownloadedImage)
    }
    
    func testThatItHasNoDownloadedFileWhenTheFileIsNotOnDisk()
    {
        // given
        let nonce = NSUUID.createUUID()
        let mimeType = "text/plain"
        let data = createTestFile(testURL)
        defer { removeTestFile(testURL) }
        let fileMetadata = ZMFileMetadata(fileURL: testURL)
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC)
        
        self.uiMOC.zm_fileAssetCache.deleteAssetData(sut.nonce, fileName: sut.filename!, encrypted: false)
        
        // then
        XCTAssertFalse(sut.hasDownloadedFile)
        XCTAssertFalse(sut.hasDownloadedImage)
    }
    
    func testThatItHasDownloadedImageWhenTheProcessedThumbnailIsOnDisk()
    {
        // given
        let nonce = NSUUID.createUUID()
        let mimeType = "video/mp4"
        let data = createTestFile(testURL)
        defer { removeTestFile(testURL) }
        let fileMetadata = ZMFileMetadata(fileURL: testURL)
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC)
        
        self.uiMOC.zm_imageAssetCache.storeAssetData(sut.nonce, format: .Medium, encrypted: false, data: NSData.secureRandomDataOfLength(100))
        defer { self.uiMOC.zm_imageAssetCache.deleteAssetData(sut.nonce, format: .Medium, encrypted: false) }
        
        // then
        XCTAssertTrue(sut.hasDownloadedImage)
    }
    
    func testThatItHasDownloadedImageWhenTheOriginalThumbnailIsOnDisk()
    {
        // given
        let nonce = NSUUID.createUUID()
        let mimeType = "video/mp4"
        let data = createTestFile(testURL)
        defer { removeTestFile(testURL) }
        let fileMetadata = ZMFileMetadata(fileURL: testURL)
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC)
        
        self.uiMOC.zm_imageAssetCache.storeAssetData(sut.nonce, format: .Original, encrypted: false, data: NSData.secureRandomDataOfLength(100))
        defer { self.uiMOC.zm_imageAssetCache.deleteAssetData(sut.nonce, format: .Medium, encrypted: false) }
        
        // then
        XCTAssertTrue(sut.hasDownloadedImage)
    }
    
    func testThatAnImageAssetHasNoFileMessageData()
    {
        // given
        let nonce = NSUUID.createUUID()
        let data = createTestFile(testURL)
        
        // when
        let sut = ZMAssetClientMessage(
            originalImageData: data,
            nonce: nonce,
            managedObjectContext: self.uiMOC
        )
        
        // then
        XCTAssertNil(sut.filename)
        XCTAssertNil(sut.fileMessageData)
    }
    
    func testThatItSetsTheGenericAssetMessageWhenCreatingMessage()
    {
        // given
        let nonce = NSUUID.createUUID()
        let mimeType = "text/plain"
        let filename = "document.txt"
        let url = testURLWithFilename(filename)
        let data = createTestFile(url)
        defer { removeTestFile(url) }
        let size = UInt64(data.length)
        let fileMetadata = ZMFileMetadata(fileURL: url)
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC)
        
        XCTAssertNotNil(sut)
        
        // then
        let assetMessage = sut.genericAssetMessage
        XCTAssertNotNil(assetMessage)
        XCTAssertEqual(assetMessage?.messageId, nonce.transportString())
        XCTAssertTrue(assetMessage!.hasAsset())
        XCTAssertNotNil(assetMessage?.asset)
        XCTAssertTrue(assetMessage!.asset.hasOriginal())
        
        let original = assetMessage?.asset.original
        XCTAssertNotNil(original)
        XCTAssertEqual(original?.name, filename)
        XCTAssertEqual(original?.mimeType, mimeType)
        XCTAssertEqual(original?.size, size)
    }
    
    func testThatItMergesMultipleGenericAssetMessagesForFileMessages()
    {
        let nonce = NSUUID.createUUID()
        let mimeType = "text/plain"
        let filename = "document.txt"
        let url = testURLWithFilename(filename)
        let data = createTestFile(url)
        let fileMetadata = ZMFileMetadata(fileURL: url)
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC)

        XCTAssertNotNil(sut)
        
        let otrKey = NSData.randomEncryptionKey()
        let encryptedData = data.zmEncryptPrefixingPlainTextIVWithKey(otrKey)
        let sha256 = encryptedData.zmSHA256Digest()
        let builder = ZMAssetImageMetaData.builder()
        builder.setWidth(10)
        builder.setHeight(10)
        let preview = ZMAssetPreview.preview(
            withSize: UInt64(data.length),
            mimeType: mimeType,
            remoteData: ZMAssetRemoteData.remoteData(withOTRKey: otrKey, sha256: sha256),
            imageMetaData: builder.build())
        let previewAsset = ZMAsset.asset(preview: preview)
        let previewMessage = ZMGenericMessage.genericMessage(withAsset: previewAsset, messageID: nonce.transportString())

        // when
        sut.addGenericMessage(previewMessage)
        
        // then
        XCTAssertEqual(sut.genericAssetMessage?.messageId, nonce.transportString())
        
        guard let asset = sut.genericAssetMessage?.asset else { return XCTFail() }
        XCTAssertNotNil(asset)
        XCTAssertTrue(asset.hasOriginal())
        XCTAssertTrue(asset.hasPreview())
        XCTAssertEqual(asset.original.name, filename)
        XCTAssertEqual(sut.fileMessageData?.filename, filename)
        XCTAssertEqual(asset.original.mimeType, mimeType)
        XCTAssertEqual(asset.original.size, UInt64(data.length))
        XCTAssertEqual(asset.preview, preview)
    }
    
    func testThatItUpdatesTheMetaDataWhenOriginalAssetMessageGetMerged()
    {
        // given
        let nonce = NSUUID.createUUID()
        let sut = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(uiMOC)
        sut.nonce = nonce
        let mimeType = "text/plain"
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.genericMessage(
            withAsset: .asset(withOriginal: .original(withSize: 256, mimeType: mimeType, name: name!)),
            messageID: nonce.transportString()
        )
        sut.updateWithGenericMessage(originalMessage, updateEvent: ZMUpdateEvent())
        
        // then
        XCTAssertEqual(sut.fileMessageData?.size, 256)
        XCTAssertEqual(sut.fileMessageData?.mimeType, mimeType)
        XCTAssertEqual(sut.fileMessageData?.filename, name)
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.Uploading)
    }
    
    func testThatItUpdatesTheTransferStateWhenTheUploadedMessageIsMerged()
    {
        // given
        let nonce = NSUUID.createUUID()
        let sut = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(uiMOC)
        sut.nonce = nonce
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.genericMessage(withUploadedOTRKey: NSData.zmRandomSHA256Key(), sha256: NSData.zmRandomSHA256Key(), messageID: nonce.transportString())
        sut.updateWithGenericMessage(originalMessage, updateEvent: ZMUpdateEvent())
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.Uploaded)
    }
    
    func testThatItUpdatesTheTransferStateWhenTheNotUploadedCanceledMessageIsMerged()
    {
        // given
        let nonce = NSUUID.createUUID()
        let sut = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(uiMOC)
        sut.nonce = nonce
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.genericMessage(withNotUploaded: .CANCELLED, messageID: nonce.transportString())
        sut.updateWithGenericMessage(originalMessage, updateEvent: ZMUpdateEvent())
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.CancelledUpload)
    }
    
    /// This is testing a race condition on the receiver side if the sender cancels but not fast enough, and he BE just got the entire payload
    func testThatItUpdatesTheTransferStateWhenTheCanceledMessageIsMergedAfterUploadingSuccessfully()
    {
        // given
        let nonce = NSUUID.createUUID()
        let sut = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(uiMOC)
        sut.nonce = nonce
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let uploadedMessage = ZMGenericMessage.genericMessage(withUploadedOTRKey: NSData.zmRandomSHA256Key(), sha256: NSData.zmRandomSHA256Key(), messageID: nonce.transportString())
        sut.updateWithGenericMessage(uploadedMessage, updateEvent: ZMUpdateEvent())
        let canceledMessage = ZMGenericMessage.genericMessage(withNotUploaded: .CANCELLED, messageID: nonce.transportString())
        sut.updateWithGenericMessage(canceledMessage, updateEvent: ZMUpdateEvent())
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.CancelledUpload)
    }
    
    func testThatItUpdatesTheTransferStateWhenTheNotUploadedFailedMessageIsMerged()
    {
        // given
        let nonce = NSUUID.createUUID()
        let sut = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(uiMOC)
        sut.nonce = nonce
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.genericMessage(withNotUploaded: .FAILED, messageID: nonce.transportString())
        sut.updateWithGenericMessage(originalMessage, updateEvent: ZMUpdateEvent())
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.FailedUpload)
    }
    
    func testThatItUpdatesTheAssetIdWhenTheUploadedMessageIsMerged()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.remoteIdentifier = NSUUID.createUUID()
        let assetId = NSUUID.createUUID()
        let nonce = NSUUID.createUUID()
        let sut = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(uiMOC)
        sut.nonce = nonce
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        let dataPayload = [
            "id": assetId.transportString()
        ]
        
        let payload = self.payloadForMessageInConversation(conversation, type: EventConversationAddOTRAsset, data: dataPayload)
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: NSUUID.createUUID())
        // when
        let originalMessage = ZMGenericMessage.genericMessage(withUploadedOTRKey: NSData.zmRandomSHA256Key(), sha256: NSData.zmRandomSHA256Key(), messageID: nonce.transportString())
        sut.updateWithGenericMessage(originalMessage, updateEvent: updateEvent)
        
        // then
        XCTAssertEqual(sut.assetId, assetId)
    }
    
    
    func testThatItReturnsAValidFileMessageData() {
        self.syncMOC.performBlockAndWait {
            // given
            let nonce = NSUUID.createUUID()
            let mimeType = "text/plain"
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            // when
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC)
            
            // then
            XCTAssertNotNil(sut)
            XCTAssertNotNil(sut.fileMessageData)
        }
    }
    
    func testThatItReturnsTheEncryptedUploadedDataWhenItHasAUploadedGenericMessageInTheDataSet() {
        self.syncMOC.performBlockAndWait { 
            // given
            let nonce = NSUUID.createUUID()
            let mimeType = "text/plain"
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC)
            
            // when
            let otrKey = NSData.randomEncryptionKey()
            let sha256 = NSData.zmRandomSHA256Key()
            sut.addGenericMessage(.genericMessage(withUploadedOTRKey: otrKey, sha256: sha256, messageID: nonce.transportString()))
            
            // then
            XCTAssertNotNil(sut)
            guard let asset = sut.genericAssetMessage?.asset else { return XCTFail() }
            XCTAssertTrue(asset.hasUploaded())
            let uploaded = asset.uploaded
            XCTAssertEqual(uploaded.otrKey, otrKey)
            XCTAssertEqual(uploaded.sha256, sha256)
        }
        
    }
    
    func testThatItAddsAnUploadedGenericMessageToTheDataSet() {
        self.syncMOC.performBlockAndWait {
            // given
            let nonce = NSUUID.createUUID()
            let mimeType = "text/plain"
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let selfClient = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
            selfClient.remoteIdentifier = self.name
            selfClient.user = .selfUserInContext(self.syncMOC)
            self.syncMOC.setPersistentStoreMetadata(selfClient.remoteIdentifier, forKey: "PersistedClientId")
            XCTAssertNotNil(ZMUser.selfUserInContext(self.syncMOC).selfClient())
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC)
            
            // when
            sut.addGenericMessage(.genericMessage(
                withUploadedOTRKey: .randomEncryptionKey(),
                sha256: .zmRandomSHA256Key(),
                messageID: nonce.transportString()
                )
            )
            
            // then
            XCTAssertNotNil(sut)
            let encryptedUpstreamMetaData = sut.encryptedMessagePayloadForDataType(.FullAsset)
            XCTAssertNotNil(encryptedUpstreamMetaData)
            self.syncMOC.setPersistentStoreMetadata(nil, forKey: "PersistedClientId")
        }
    }
    
    func testThatItReturnsTheEncryptedPayloadDataForThePlaceholderMessage() {
        self.syncMOC.performBlockAndWait {
            
            // given
            let nonce = NSUUID.createUUID()
            let mimeType = "text/plain"
            let filename = "document.txt"
            let url = self.testURLWithFilename(filename)
            let data = self.createTestFile(url)
            defer { self.removeTestFile(url) }
            let fileMetadata = ZMFileMetadata(fileURL: url)
            
            // when
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC)
            
            self.conversation.mutableMessages.addObject(sut)
            
            // then
            XCTAssertNotNil(sut)
            XCTAssertTrue(sut.genericAssetMessage!.asset.hasOriginal())
            
            guard let encryptedData = sut.encryptedMessagePayloadForDataType(.Placeholder) else { return XCTFail() }
            guard let genericMessage = self.decryptedMessageData(encryptedData, forClient: self.user1Client1) else { return XCTFail() }
            
            XCTAssertNotNil(genericMessage)
            XCTAssertTrue(genericMessage.hasAsset())
            XCTAssertTrue(genericMessage.asset.hasOriginal())
            
            let original = genericMessage.asset.original
            XCTAssertEqual(original.name, filename)
            XCTAssertEqual(original.mimeType, mimeType)
            XCTAssertEqual(original.size, UInt64(data.length))
        }
    }
    
    func testThatItReturnsTheEncryptedMetaDataForTheFileDataMessage() {
        self.syncMOC.performBlockAndWait {
            // given
            let nonce = NSUUID.createUUID()
            let mimeType = "text/plain"
            let filename = "document.txt"
            let url = self.testURLWithFilename(filename)
            let data = self.createTestFile(url)
            defer { self.removeTestFile(url) }
            let fileMetadata = ZMFileMetadata(fileURL: url)
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC)
            
            self.conversation.mutableMessages.addObject(sut)
            
            // when
            let (otrKey, sha256) = (NSData.randomEncryptionKey(), NSData.zmRandomSHA256Key())
            sut.addGenericMessage(.genericMessage(withUploadedOTRKey: otrKey, sha256: sha256, messageID: sut.nonce.transportString()))
            
            // then
            guard let encryptedData = sut.encryptedMessagePayloadForDataType(.FullAsset) else { return XCTFail() }
            guard let genericMessage = self.decryptedMessageData(encryptedData, forClient: self.user1Client1) else { return XCTFail() }
            
            XCTAssertNotNil(genericMessage)
            XCTAssertTrue(genericMessage.hasAsset())
            
            XCTAssertTrue(genericMessage.asset.hasUploaded())
            let uploaded = genericMessage.asset.uploaded
            XCTAssertEqual(uploaded.otrKey, otrKey)
            XCTAssertEqual(uploaded.sha256, sha256)
            
            XCTAssertTrue(genericMessage.asset.hasOriginal())
            let original = genericMessage.asset.original
            XCTAssertEqual(original.name, filename)
            XCTAssertEqual(original.mimeType, mimeType)
            XCTAssertEqual(original.size, UInt64(data.length))
            
            XCTAssertFalse(original.hasVideo())
        }
    }
    
    func testThatItReturnsTheEncryptedMetaDataForAVideoDataMessage() {
        self.syncMOC.performBlockAndWait {
            
            // given
            let nonce = NSUUID.createUUID()
            let mimeType = "video/mp4"
            let duration : NSTimeInterval = 15000
            let dimensions = CGSizeMake(1024, 768)
            let name = "cats.mp4"
            let url = self.testURLWithFilename(name)
            let data = self.createTestFile(url)
            let size = data.length
            defer { self.removeTestFile(url) }
            let videoMetadata = ZMVideoMetadata(fileURL: url, duration: duration, dimensions: dimensions)
            let sut = ZMAssetClientMessage(
                fileMetadata: videoMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC)
            
            self.conversation.mutableMessages.addObject(sut)
            
            // when
            let (otrKey, sha256) = (NSData.randomEncryptionKey(), NSData.zmRandomSHA256Key())
            sut.addGenericMessage(.genericMessage(withUploadedOTRKey: otrKey, sha256: sha256, messageID: sut.nonce.transportString()))
            
            // then
            guard let encryptedData = sut.encryptedMessagePayloadForDataType(.FullAsset) else { return XCTFail() }
            guard let genericMessage = self.decryptedMessageData(encryptedData, forClient: self.user1Client1) else { return XCTFail() }
            
            XCTAssertNotNil(genericMessage)
            XCTAssertTrue(genericMessage.hasAsset())
            
            XCTAssertTrue(genericMessage.asset.hasUploaded())
            let uploaded = genericMessage.asset.uploaded
            XCTAssertEqual(uploaded.otrKey, otrKey)
            XCTAssertEqual(uploaded.sha256, sha256)
            
            XCTAssertTrue(genericMessage.asset.hasOriginal())
            let original = genericMessage.asset.original
            XCTAssertEqual(original.name, name)
            XCTAssertEqual(original.mimeType, mimeType)
            XCTAssertEqual(original.size, UInt64(size))
            
            XCTAssertTrue(original.hasVideo())
            let video = original.video
            XCTAssertEqual(video.durationInMillis, UInt64(duration * 1000))
            XCTAssertEqual(video.width, Int32(dimensions.width))
            XCTAssertEqual(video.height, Int32(dimensions.height))
        }
    }
    
    func testThatItSetsTheCorrectStateWhen_RequestFileDownload_IsBeingCalled() {
        // given
        let sut = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(uiMOC)
        sut.nonce = .createUUID()
        let original = ZMGenericMessage.genericMessage(withAsset: .asset(withOriginal: .original(withSize: 256, mimeType: "text/plain", name: name!)), messageID: sut.nonce.transportString())
        sut.addGenericMessage(original)
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut.fileMessageData)
        
        // when
        sut.fileMessageData?.requestFileDownload()
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.Downloading)
    }
    
    func testThatItCancelsUpload() {
        self.syncMOC.performBlockAndWait {
            
            // given
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            XCTAssertEqual(sut.transferState, ZMFileTransferState.Uploading)
            
            // when
            sut.fileMessageData?.cancelTransfer()
            
            // then
            XCTAssertEqual(sut.transferState, ZMFileTransferState.CancelledUpload)
            XCTAssertEqual(sut.progress, 0.0)
        }
    }
    
    func testThatItCanCancelsUploadMultipleTimes() {
        // given
        self.syncMOC.performBlockAndWait {
            
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            XCTAssertEqual(sut.transferState, ZMFileTransferState.Uploading)
            
            // when / then
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.CancelledUpload)
            
            sut.resend()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.Uploading)
            XCTAssertEqual(sut.progress, 0.0);
            
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.CancelledUpload)
            
            sut.resend()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.Uploading)
            XCTAssertEqual(sut.progress, 0.0)
        }
        
    }
    
    func testThatItCancelsDownload() {
        self.syncMOC.performBlockAndWait {
            
            // given
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            sut.transferState = .Downloading
            sut.delivered = true
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when
            sut.fileMessageData?.cancelTransfer()
            
            // then
            XCTAssertEqual(sut.transferState, ZMFileTransferState.Uploaded)
            XCTAssertEqual(sut.progress, 0.0)
        }
    }
    
    func testThatItAppendsA_NotUploadedCancelled_MessageWhenUploadFromThisDeviceIsCancelled() {
        self.syncMOC.performBlockAndWait {
            
            // given
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            sut.transferState = .Uploading
            sut.delivered = false
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when
            sut.fileMessageData?.cancelTransfer()
            
            // then
            let messages = sut.dataSet.flatMap { $0.genericMessage! }
            let assets = messages.filter { $0.hasAsset() }.flatMap { $0.asset }
            XCTAssertEqual(assets.count, 2)
            let notUploaded = assets.filter { $0.hasNotUploaded() }.flatMap { $0.notUploaded }
            XCTAssertEqual(notUploaded.count, 1)
            XCTAssertEqual(notUploaded.first, ZMAssetNotUploaded.CANCELLED)
            
            XCTAssertEqual(sut.transferState, ZMFileTransferState.CancelledUpload)
            XCTAssertEqual(sut.progress, 0.0)
        }
    }
    
    func testThatItSetsTheTransferStateToDonwloadedWhen_RequestFileDownload_IsCalledButFileIsAlreadyOnDisk() {
        self.syncMOC.performBlockAndWait {
            
            // given
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            sut.transferState = .Uploaded
            sut.delivered = true
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when
            sut.fileMessageData?.requestFileDownload()
            
            // then
            XCTAssertEqual(sut.transferState, ZMFileTransferState.Downloaded)
        }
    }
    
    func testThatItItReturnsTheGenericMessageDataAndInculdesTheNotUploadedWhenItIsPresent_Placeholder() {
        self.syncMOC.performBlockAndWait {
            
            // given
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            sut.delivered = true
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when we cancel the transfer
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.CancelledUpload)
            
            // then the generic message data should include the not uploaded
            let assetMessage = sut.genericAssetMessage
            let genericMessage = sut.genericMessageForDataType(.Placeholder)
            
            XCTAssertTrue(assetMessage!.asset.hasNotUploaded())
            XCTAssertEqual(assetMessage?.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
            XCTAssertTrue(genericMessage.asset.hasNotUploaded())
            XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        }
    }
    
    func testThatItItReturnsTheEncryptedGenericMessageDataIncludingThe_NotUploaded_WhenItIsPresent() {
        self.syncMOC.performBlockAndWait {
            // given
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            self.conversation.mutableMessages.addObject(sut)
            sut.delivered = true
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when we cancel the transfer
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.CancelledUpload)
            
            // then the genereted encrypted message should include the Asset.Original and Asset.NotUploaded
            guard let encryptedData = sut.encryptedMessagePayloadForDataType(.Placeholder) else { return XCTFail() }
            guard let genericMessage = self.decryptedMessageData(encryptedData, forClient: self.user1Client1) else { return XCTFail() }
            
            XCTAssertTrue(genericMessage.asset.hasNotUploaded())
            XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
            XCTAssertTrue(genericMessage.asset.hasOriginal())
        }
    }
    
    func testThatItPostsANotificationWhenTheDownloadOfTheMessageIsCancelled() {
        self.syncMOC.performBlockAndWait {
            
            // given
            let sut = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.syncMOC)
            sut.nonce = .createUUID()
            let original = ZMGenericMessage.genericMessage(withAsset: .asset(withOriginal: .original(withSize: 256, mimeType: "text/plain", name: self.name!)), messageID: sut.nonce.transportString())
            sut.addGenericMessage(original)
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())

            _ = self.expectationForNotification(ZMAssetClientMessageDidCancelFileDownloadNotificationName, object:sut.objectID, handler: nil)
            
            sut.requestFileDownload()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.Downloading)
            
            // when
            sut.fileMessageData?.cancelTransfer()
            
            // then
            XCTAssertEqual(sut.transferState, ZMFileTransferState.Uploaded)
        }
    }
    
    func testThatItPreparesMessageForResend() {
        self.syncMOC.performBlockAndWait {
            
            // given
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            self.conversation.mutableMessages.addObject(sut)
            sut.delivered = true
            sut.progress = 56
            sut.transferState = .FailedUpload
            sut.uploadState = .UploadingFailed
            
            // when
            sut.resend()
            
            // then
            XCTAssertEqual(sut.uploadState, ZMAssetUploadState.UploadingPlaceholder)
            XCTAssertFalse(sut.delivered)
            XCTAssertEqual(sut.transferState, ZMFileTransferState.Uploading)
            XCTAssertEqual(sut.progress, 0)
        }
    }
    
    func testThatItReturnsNilAssetIdOnANewlyCreatedMessage() {
        self.syncMOC.performBlockAndWait {
            
            // given
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            // then
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
        }
    }
    
    func testThatItReturnsAssetIdWhenSettingItDirectly() {
        self.syncMOC.performBlockAndWait {
            
            // given
            let previewSize : UInt64 = 46
            let previewMimeType = "image/jpg"
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: NSData.zmRandomSHA256Key(), sha256: NSData.zmRandomSHA256Key())
            let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            
            let uuid = NSUUID.createUUID().transportString()
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            sut.addGenericMessage(ZMGenericMessage.genericMessage(withAsset: asset, messageID: "\(sut.nonce)"))
            
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            
            // when
            sut.fileMessageData!.thumbnailAssetID = uuid
            
            // then
            XCTAssertEqual(sut.fileMessageData?.thumbnailAssetID, uuid)
            // testing that other properties are kept
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.otrKey, remoteData.otrKey)
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.sha256, remoteData.sha256)
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.image.width, imageMetaData.width)
            XCTAssertEqual(sut.genericAssetMessage?.asset.original.name, sut.filename)
        }
    }
    
    func testThatItSetsAssetIdWhenUpdatingFromAPreviewMessage() {
        self.syncMOC.performBlockAndWait {
            
            // given
            let previewSize : UInt64 = 46
            let previewMimeType = "image/jpg"
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: NSData.zmRandomSHA256Key(), sha256: NSData.zmRandomSHA256Key())
            let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            
            let uuid = NSUUID.createUUID().transportString()
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            let genericMessage = ZMGenericMessage.genericMessage(withAsset: asset, messageID: "\(sut.nonce)")
            let payload : [String : AnyObject] = [
                "type" : "conversation.otr-asset-add",
                "data" : [
                    "id" : uuid
                ]
            ]
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: NSUUID.createUUID())
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            
            // when
            sut.updateWithGenericMessage(genericMessage, updateEvent: updateEvent)
            
            // then
            XCTAssertEqual(sut.fileMessageData?.thumbnailAssetID, uuid)
            // testing that other properties are kept
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.otrKey, remoteData.otrKey)
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.sha256, remoteData.sha256)
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.image.width, imageMetaData.width)
            XCTAssertEqual(sut.genericAssetMessage?.asset.original.name, sut.filename)
        }
    }
    
    func testThatItDoesNotSetAssetIdWhenUpdatingFromAnUploadedMessage() {
        self.syncMOC.performBlockAndWait {
            
            // given
            let previewSize : UInt64 = 46
            let previewMimeType = "image/jpg"
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: NSData.zmRandomSHA256Key(), sha256: NSData.zmRandomSHA256Key())
            let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            
            let uuid = NSUUID.createUUID().transportString()
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            
            let assetWithUploaded = ZMAsset.asset(withUploadedOTRKey: NSData.zmRandomSHA256Key(), sha256: NSData.zmRandomSHA256Key())
            let assetWithPreview = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            let builder = ZMAssetBuilder()
            builder.mergeFrom(assetWithUploaded)
            builder.mergePreview(assetWithPreview.preview)
            let asset = builder.build()
            
            let genericMessage = ZMGenericMessage.genericMessage(withAsset: asset, messageID: "\(sut.nonce)")
            let payload : [String : AnyObject] = [
                "type" : "conversation.otr-asset-add",
                "data" : [
                    "id" : NSUUID.createUUID().transportString()
                ]
            ]
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: NSUUID.createUUID())
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            
            
            // when
            sut.updateWithGenericMessage(genericMessage, updateEvent: updateEvent)
            
            // then
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            // testing that other properties are kept
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.otrKey, remoteData.otrKey)
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.sha256, remoteData.sha256)
            XCTAssertEqual(sut.genericAssetMessage?.asset.preview.image.width, imageMetaData.width)
            XCTAssertEqual(sut.genericAssetMessage?.asset.original.name, sut.filename)
        }
    }
    
    func testThatItClearsGenericAssetMessageCacheWhenFaulting() {
        // given
        let previewSize : UInt64 = 46
        let previewMimeType = "image/jpg"
        let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: NSData.zmRandomSHA256Key(), sha256: NSData.zmRandomSHA256Key())
        let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
        
        let uuid = NSUUID.createUUID().transportString()
        _ = createTestFile(self.testURL)
        defer { self.removeTestFile(self.testURL) }
        let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
        
        let sut = ZMAssetClientMessage(fileMetadata: fileMetadata,
                                       nonce: NSUUID.createUUID(),
                                       managedObjectContext: uiMOC)
        
        XCTAssertFalse(sut.genericAssetMessage!.asset.hasPreview())
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // when
        uiMOC.refreshObject(sut, mergeChanges: false) // Turn object into fault
        
        self.syncMOC.performBlockAndWait {
            let sutInSyncContext = self.syncMOC.objectWithID(sut.objectID) as! ZMAssetClientMessage
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            let genericMessage = ZMGenericMessage.genericMessage(withAsset: asset, messageID: "\(sut.nonce)")
            let payload : [String : AnyObject] = [
                "type" : "conversation.otr-asset-add",
                "data" : [
                    "id" : uuid
                ]
            ]
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: NSUUID.createUUID())
            XCTAssertNil(sutInSyncContext.fileMessageData?.thumbnailAssetID)
            
            sutInSyncContext.updateWithGenericMessage(genericMessage, updateEvent: updateEvent) // Append preview
            XCTAssertTrue(self.syncMOC.saveOrRollback())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        // properties changed in sync context are visible
        XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.otrKey, remoteData.otrKey)
        XCTAssertEqual(sut.genericAssetMessage?.asset.preview.remote.sha256, remoteData.sha256)
        XCTAssertEqual(sut.genericAssetMessage?.asset.preview.image.width, imageMetaData.width)
    }
}

// MARK: UploadState
extension ZMAssetClientMessageTests {
    
    func testThatItStoresThumbnailDataIfAvailable() {
        self.syncMOC.performBlockAndWait {
            
            // given
            let thumbnail = self.verySmallJPEGData()
            let nonce = NSUUID()
            self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL, thumbnail: thumbnail)
            
            // when
            let message = ZMAssetClientMessage(fileMetadata: fileMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC)
            
            // then
            let storedThumbail = message.managedObjectContext?.zm_imageAssetCache.assetData(message.nonce, format: .Original, encrypted: false)
            XCTAssertNotNil(storedThumbail)
            XCTAssertEqual(storedThumbail, thumbnail)
        }
    }
    func testThatItDoesNotStoresThumbnailDataIfEmpty() {
        self.syncMOC.performBlockAndWait {
            
            // given
            let textFile = self.testURLWithFilename("robert.txt")
            
            let thumbnail = NSData()
            let nonce = NSUUID()
            self.createTestFile(textFile)
            defer { self.removeTestFile(textFile) }
            
            let fileMetadata = ZMFileMetadata(fileURL: textFile, thumbnail: thumbnail)
            
            // when
            let message = ZMAssetClientMessage(fileMetadata: fileMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC)
            
            // then
            let storedThumbail = message.managedObjectContext?.zm_imageAssetCache.assetData(message.nonce, format: .Original, encrypted: false)
            XCTAssertNil(storedThumbail)
        }
    }
}


// MARK: Helpers
extension ZMAssetClientMessageTests {
    
    var testURL: NSURL {
        return testURLWithFilename("file.dat")
    }
    
    func testURLWithFilename(filename: String) -> NSURL {
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let documentsURL = NSURL(fileURLWithPath: documents)
        return documentsURL.URLByAppendingPathComponent(filename)
    }
    
    func createTestFile(url: NSURL) -> NSData {
        let data: NSData! = "Some other data".dataUsingEncoding(NSUTF8StringEncoding)
        try! data.writeToURL(url, options: [])
        return data
    }
    
    func removeTestFile(url: NSURL) {
        do {
            let fm = NSFileManager.defaultManager()
            try fm.removeItemAtURL(url)
        } catch {
            XCTFail("Error removing file: \(error)")
        }
    }
    
    func decryptedMessageData(data: NSData, forClient client: UserClient) -> ZMGenericMessage? {
        let otrMessage = ZMNewOtrMessage.builder().mergeFromData(data).build() as? ZMNewOtrMessage
        XCTAssertNotNil(otrMessage, "Unable to generate OTR message")
        let clientEntries = otrMessage?.recipients.flatMap { $0 as? ZMUserEntry }.flatMap { $0.clients }.flatten()

        guard let entry = clientEntries?.first as? ZMClientEntry else { XCTFail("Unable to get client entry"); return nil }
        
        var message : ZMGenericMessage?
        self.syncMOC.zm_cryptKeyStore.encryptionContext.perform { (sessionsDirectory) in
            do {
                let decryptedData = try sessionsDirectory.decrypt(entry.text, senderClientId: client.remoteIdentifier)
                message = ZMGenericMessage.builder().mergeFromData(decryptedData).build() as? ZMGenericMessage
            } catch {
                XCTFail("Failed to decrypt generic message: \(error)")
            }
        }
        return message
    }
    
    func createOtherClientAndConversation() -> (UserClient, ZMConversation) {
        let otherUser = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
        otherUser.remoteIdentifier = .createUUID()
        let otherClient = createClientForUser(otherUser, createSessionWithSelfUser: true)
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
        conversation.conversationType = .Group
        conversation.addParticipant(otherUser)
        XCTAssertTrue(self.syncMOC.saveOrRollback())
        
        return (otherClient, conversation)
    }
}

// MARK: - Associated Task Identifier
extension ZMAssetClientMessageTests {
    
    func testThatItStoresTheAssociatedTaskIdentifier() {
        // given
        let sut = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.syncMOC)
        
        // when
        let identifier = ZMTaskIdentifier(identifier: 42, sessionIdentifier: "foo")
        sut.associatedTaskIdentifier = identifier
        XCTAssertTrue(self.syncMOC.saveOrRollback())
        self.syncMOC.refreshObject(sut, mergeChanges: false)
        
        // then
        XCTAssertEqual(sut.associatedTaskIdentifier, identifier)
    }
    
}

// MARK: - Message generation
extension ZMAssetClientMessageTests {
    
    func testThatItSetsGenericMediumAndPreviewDataWhenCreatingMessage()
    {
        // given
        let nonce = NSUUID.createUUID()
        let image = self.verySmallJPEGData()
        
        // when
        let sut = ZMAssetClientMessage(originalImageData: image, nonce: nonce, managedObjectContext: self.uiMOC)
        let imageMessageStorage = sut.imageAssetStorage!
        
        // then
        XCTAssertNotNil(imageMessageStorage.mediumGenericMessage)
        XCTAssertNotNil(imageMessageStorage.previewGenericMessage)
        
    }
    
    func testThatItSavesTheOriginalFileWhenCreatingMessage()
    {
        // given
        let nonce = NSUUID.createUUID()
        let image = self.verySmallJPEGData()
        
        // when
        _ = ZMAssetClientMessage(originalImageData: image, nonce: nonce, managedObjectContext: self.uiMOC)
        
        // then
        let fileData = self.uiMOC.zm_imageAssetCache.assetData(nonce, format: .Original, encrypted: false)
        XCTAssertEqual(fileData, image)
    }

    func testThatItSetsTheOriginalImageSize()
    {
        // given
        let nonce = NSUUID.createUUID()
        let image = self.verySmallJPEGData()
        let expectedSize = ZMImagePreprocessor.sizeOfPrerotatedImageWithData(image)
        
        // when
        let sut = ZMAssetClientMessage(originalImageData: image, nonce: nonce, managedObjectContext: self.uiMOC)
        let imageMessageStorage = sut.imageAssetStorage!
        
        // then
        XCTAssertEqual(expectedSize, imageMessageStorage.originalImageSize())
    }
}

// MARK: - Payload generation
extension ZMAssetClientMessageTests {
    
    func assertPayloadData(payload: NSData!, forMessage message: ZMAssetClientMessage, format: ZMImageFormat) {
        
        let imageMessageStorage = message.imageAssetStorage!
        let assetMetadata = ZMOtrAssetMetaBuilder().mergeFromData(payload).build() as? ZMOtrAssetMeta
        
        AssertOptionalNotNil(assetMetadata) { assetMetadata in
            XCTAssertEqual(assetMetadata.isInline(), imageMessageStorage.isInlineForFormat(format))
            XCTAssertEqual(assetMetadata.nativePush(), imageMessageStorage.isUsingNativePushForFormat(format))
            
            XCTAssertEqual(assetMetadata.sender.client, self.selfClient1.clientId.client)

            self.assertRecipients(assetMetadata.recipients as! [ZMUserEntry])
        }
    }
    
    func testThatItCreatesPayloadData_Medium() {
        
        //given
        let message = appendImageMessage(.Medium)
        
        //when
        let payload = message.imageAssetStorage!.encryptedMessagePayloadForImageFormat(.Medium)?.data()
        
        //then
        assertPayloadData(payload, forMessage: message, format: .Medium)
    }
    
    func testThatItCreatesPayloadData_Preview() {
        
        //given
        let message = appendImageMessage(ZMImageFormat.Preview)
        
        //when
        let payload = message.imageAssetStorage!.encryptedMessagePayloadForImageFormat(.Preview)?.data()
        
        //then
        assertPayloadData(payload, forMessage: message, format: .Preview)
    }
}

// MARK: - Post event
extension ZMAssetClientMessageTests {
    
    func testThatItSetsConversationLastServerTimestampWhenPostingPreview() {
        // given
        let message = appendImageMessage(.Preview)
        let date  = NSDate()
        let payload : [NSObject : AnyObject] = ["deleted" : [String:String](), "missing" : [String:String](), "redundant":[String:String](), "time" : date.transportString()]
        
        message.uploadState = .UploadingPlaceholder
        
        // when
        message.updateWithPostPayload(payload, updatedKeys: Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey))
        
        // then
        XCTAssertEqual(message.serverTimestamp, message.conversation?.lastServerTimeStamp)
    }
    
    func testThatItDoesNotSetConversationLastServerTimestampWhenPostingMedium() {
        // given
        let message = appendImageMessage(.Medium)
        let date  = NSDate()
        let payload : [NSObject : AnyObject] = ["deleted" : [String:String](), "missing" : [String:String](), "redundant":[String:String](), "time" : date.transportString()]
        message.uploadState = .UploadingFullAsset
        
        // when
        message.updateWithPostPayload(payload, updatedKeys: Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey))
        
        // then
        XCTAssertNotEqual(message.serverTimestamp, message.conversation?.lastServerTimeStamp)
    }
    
}


// MARK: - Image owner
extension ZMAssetClientMessageTests {
    
    func sampleImageData() -> NSData {
        return self.verySmallJPEGData()
    }
    
    func sampleProcessedImageData(format: ZMImageFormat) -> NSData {
        return "\(StringFromImageFormat(format)) fake data".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
    }
    
    func sampleImageProperties(format: ZMImageFormat) -> ZMIImageProperties {
        let mult = format == .Medium ? 100 : 1
        return ZMIImageProperties(size: CGSizeMake(CGFloat(300*mult), CGFloat(100*mult)), length: UInt(100*mult), mimeType: "image/jpeg")!
    }

    func createAssetClientMessageWithSampleImageAndEncryptionKeys(storeOriginal: Bool, storeEncrypted: Bool, storeProcessed: Bool, imageData: NSData? = nil) -> ZMAssetClientMessage {
        let directory = self.uiMOC.zm_imageAssetCache
        let nonce = NSUUID.createUUID()
        let imageData = imageData ?? sampleImageData()
        var genericMessage : [ZMImageFormat : ZMGenericMessage] = [:]
        
        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {
            let processedData = sampleProcessedImageData(format)
            let otrKey = NSData.randomEncryptionKey()
            let encryptedData = processedData.zmEncryptPrefixingPlainTextIVWithKey(otrKey)
            let sha256 = encryptedData.zmSHA256Digest()
            let encryptionKeys = ZMImageAssetEncryptionKeys(otrKey: otrKey, sha256: sha256)
            genericMessage[format] = ZMGenericMessage(
                mediumImageProperties: storeProcessed ? self.sampleImageProperties(.Medium) : nil,
                processedImageProperties: storeProcessed ? self.sampleImageProperties(format) : nil,
                encryptionKeys: storeEncrypted ? encryptionKeys : nil,
                nonce: nonce.transportString(),
                format: format)
            
            if(storeProcessed) {
                directory.storeAssetData(nonce, format: format, encrypted: false, data: processedData)
            }
            if(storeEncrypted) {
                directory.storeAssetData(nonce, format: format, encrypted: true, data: encryptedData)
            }
        }
        
        if(storeOriginal) {
            directory.storeAssetData(nonce, format: .Original, encrypted: false, data: imageData)
        }
        let assetMessage = ZMAssetClientMessage.insertNewObjectInManagedObjectContext(self.uiMOC)
        
        assetMessage?.addGenericMessage(genericMessage[.Preview]!)
        assetMessage?.addGenericMessage(genericMessage[.Medium]!)
        assetMessage?.assetId = nonce
        return assetMessage
    }

    func testThatOriginalImageDataReturnsTheOriginalFileIfTheFileIsPresent() {
        // given
        let expectedData = self.sampleImageData()
        let sut = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false, imageData: expectedData)
        
        // when
        let data = sut.imageAssetStorage!.originalImageData()
        
        // then
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.hash, expectedData.hash)
    }

    func testThatOriginalImageDataReturnsNilIfThereIsNoFile() {
        // given
        let sut = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertNil(sut.imageAssetStorage!.originalImageData())
    }

    func testThatIsPublicForFormatReturnsNoForAllFormats() {
        // given
        let formats = [ZMImageFormat.Medium, ZMImageFormat.Invalid, ZMImageFormat.Original, ZMImageFormat.Preview, ZMImageFormat.Profile]
        
        // when
        let sut = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)

        // then
        for format in formats {
            XCTAssertFalse(sut.imageAssetStorage!.isPublicForFormat(format))
        }
    }

    func testThatEncryptedDataForFormatReturnsValuesFromEncryptedFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: true, storeProcessed: true)
        
        for format in [ZMImageFormat.Preview, ZMImageFormat.Medium] {
            // when
            let data = message.imageAssetStorage!.imageDataForFormat(format, encrypted: true)
            
            // then
            let dataOnFile = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: format, encrypted: true)
            XCTAssertEqual(dataOnFile, data)
        }
    }
    
    func testThatImageDataForFormatReturnsValuesFromProcessedFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: true, storeProcessed: true)
        
        for format in [ZMImageFormat.Preview, ZMImageFormat.Medium] {
            // when
            let data = message.imageAssetStorage!.imageDataForFormat(format, encrypted: false)
            
            // then
            let dataOnFile = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format:format, encrypted: false)
            XCTAssertEqual(dataOnFile, data)
        }
    }
    
    func testThatImageDataForFormatReturnsNilWhenThereIsNoFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        for format in [ZMImageFormat.Preview, ZMImageFormat.Medium] {
            
            // when
            let plainData = message.imageAssetStorage!.imageDataForFormat(format, encrypted: false)
            let encryptedData = message.imageAssetStorage!.imageDataForFormat(format, encrypted: true)
            
            // then
            XCTAssertNil(plainData)
            XCTAssertNil(encryptedData)
            
        }
    }

    func testThatItReturnsTheOriginalImageSize() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        
        for _ in [ZMImageFormat.Preview, ZMImageFormat.Medium] {
            
            // when
            let originalSize = message.imageAssetStorage!.originalImageSize()
            
            // then
            XCTAssertEqual(originalSize, self.sampleImageProperties(.Medium).size)
            
        }
    }
    
    func testThatItReturnsZeroOriginalImageSizeIfItWasNotSet() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        for _ in [ZMImageFormat.Preview, ZMImageFormat.Medium] {
            
            // when
            let originalSize = message.imageAssetStorage!.originalImageSize()
            
            // then
            XCTAssertEqual(originalSize, CGSizeMake(0,0))
            
        }
    }
    
    func testThatItReturnsTheRightRequiredImageFormats() {
        
        // given
        let expected = NSOrderedSet(array: [ZMImageFormat.Medium, ZMImageFormat.Preview].map { NSNumber(unsignedLong: $0.rawValue)})
        
        // when
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertEqual(message.imageAssetStorage!.requiredImageFormats(), expected);

    }
    
    func testThatItReturnsTheRightValueForInlineForFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)

        // then
        XCTAssertFalse(message.imageAssetStorage!.isInlineForFormat(.Medium));
        XCTAssertTrue(message.imageAssetStorage!.isInlineForFormat(.Preview));
        XCTAssertFalse(message.imageAssetStorage!.isInlineForFormat(.Original));
        XCTAssertFalse(message.imageAssetStorage!.isInlineForFormat(.Profile));
        XCTAssertFalse(message.imageAssetStorage!.isInlineForFormat(.Invalid));
    }

    func testThatItReturnsTheRightValueForUsingNativePushForFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertTrue(message.imageAssetStorage!.isUsingNativePushForFormat(.Medium));
        XCTAssertFalse(message.imageAssetStorage!.isUsingNativePushForFormat(.Preview));
        XCTAssertFalse(message.imageAssetStorage!.isUsingNativePushForFormat(.Original));
        XCTAssertFalse(message.imageAssetStorage!.isUsingNativePushForFormat(.Profile));
        XCTAssertFalse(message.imageAssetStorage!.isUsingNativePushForFormat(.Invalid));
    }
    
    func testThatItClearsOnlyTheOriginalImageFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: true, storeProcessed: true)
        
        // when
        message.imageAssetStorage!.processingDidFinish()
        
        // then
        let directory = self.uiMOC.zm_imageAssetCache
        XCTAssertNil(directory.assetData(message.nonce, format: .Original, encrypted: false))
        XCTAssertNil(message.imageAssetStorage!.originalImageData())
        XCTAssertNotNil(directory.assetData(message.nonce, format: .Medium, encrypted: false))
        XCTAssertNotNil(directory.assetData(message.nonce, format: .Preview, encrypted: false))
        XCTAssertNotNil(directory.assetData(message.nonce, format: .Medium, encrypted: true))
        XCTAssertNotNil(directory.assetData(message.nonce, format: .Preview, encrypted: true))
    }

    func testThatItSetsTheCorrectImageDataPropertiesWhenSettingTheData() {
        
        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
            let testData = "foobar".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            let testProperties = ZMIImageProperties(size: CGSizeMake(33,55), length: UInt(10), mimeType: "image/tiff")
            
            // when
            message.imageAssetStorage!.setImageData(testData, forFormat: format, properties: testProperties)
            
            // then
            XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(format)!.image.width, 33)
            XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(format)!.image.height, 55)
            XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(format)!.image.size, 10)
            XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(format)!.image.mimeType, "image/tiff")
        }
    }
    
    func testThatItStoresTheRightEncryptionKeysNoMatterInWhichOrderTheDataIsSet() {
        
        // given
        let dataPreview = "FOOOOOO".dataUsingEncoding(NSUTF8StringEncoding)
        let dataMedium = "xxxxxxxxx".dataUsingEncoding(NSUTF8StringEncoding)
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        message.isEncrypted = true
        let testProperties = ZMIImageProperties(size: CGSizeMake(33,55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.imageAssetStorage!.setImageData(dataPreview, forFormat: .Preview, properties: testProperties) // simulate various order of setting
        message.imageAssetStorage!.setImageData(dataMedium, forFormat: .Medium, properties: testProperties)
        message.imageAssetStorage!.setImageData(dataPreview, forFormat: .Preview, properties: testProperties)
        message.imageAssetStorage!.setImageData(dataMedium, forFormat: .Medium, properties: testProperties)

        // then
        let dataOnDiskForPreview = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: .Preview, encrypted: true)!
        let dataOnDiskForMedium = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: .Medium, encrypted: true)!
        
        XCTAssertEqual(dataOnDiskForPreview.zmSHA256Digest(), message.imageAssetStorage!.previewGenericMessage!.image.sha256)
        XCTAssertEqual(dataOnDiskForMedium.zmSHA256Digest(), message.imageAssetStorage!.mediumGenericMessage!.image.sha256)
    }
    
    func testThatItSetsTheMediumSizeOnThePreviewOriginalSize_SetPreviewFirst() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        let testData = "foobar".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let testMediumProperties = ZMIImageProperties(size: CGSizeMake(111,100), length: UInt(1000), mimeType: "image/tiff")
        let testPreviewProperties = ZMIImageProperties(size: CGSizeMake(80,55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.imageAssetStorage!.setImageData(testData, forFormat: .Preview, properties: testPreviewProperties)
        message.imageAssetStorage!.setImageData(testData, forFormat: .Medium, properties: testMediumProperties)
        
        // then
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.width, 80)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.height, 55)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.size, 10)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.mimeType, "image/tiff")
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.width, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.height, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.size, 1000)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.mimeType, "image/tiff")
    }
    
    func testThatItSetsTheMediumSizeOnThePreviewOriginalSize_SetMediumFirst() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        let testData = "foobar".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let testMediumProperties = ZMIImageProperties(size: CGSizeMake(111,100), length: UInt(1000), mimeType: "image/tiff")
        let testPreviewProperties = ZMIImageProperties(size: CGSizeMake(80,55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.imageAssetStorage!.setImageData(testData, forFormat: .Medium, properties: testMediumProperties)
        message.imageAssetStorage!.setImageData(testData, forFormat: .Preview, properties: testPreviewProperties)
        
        // then
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.width, 80)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.height, 55)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.size, 10)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Preview)!.image.mimeType, "image/tiff")
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.width, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.height, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.size, 1000)
        XCTAssertEqual(message.imageAssetStorage!.genericMessageForFormat(.Medium)!.image.mimeType, "image/tiff")
    }
    
    func testThatItSavesTheImageDataToFileInPlainTextAndEncryptedWhenSettingTheDataOnAnEncryptedMessage() {
        
        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
            message.isEncrypted = true
            let testProperties = ZMIImageProperties(size: CGSizeMake(33,55), length: UInt(10), mimeType: "image/tiff")
            let data = sampleProcessedImageData(format)
            
            // when
            message.imageAssetStorage!.setImageData(data, forFormat: format, properties: testProperties)
            
            // then
            XCTAssertEqual(self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: format, encrypted: false), data)
            XCTAssertEqual(message.imageAssetStorage!.imageDataForFormat(format, encrypted: false), data)
            AssertOptionalNotNil(self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: format, encrypted: true)) {
                let decrypted = $0.zmDecryptPrefixedPlainTextIVWithKey(message.imageAssetStorage!.genericMessageForFormat(format)!.image.otrKey)
                let sha = $0.zmSHA256Digest()
                XCTAssertEqual(decrypted, data)
                XCTAssertEqual(sha, message.imageAssetStorage!.genericMessageForFormat(format)!.image.sha256)
            }
        }
    }

    func testThatItReturnsNilEncryptedDataIfTheImageIsNotEncrypted() {

        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
            
            // then
            XCTAssertNil(message.imageAssetStorage!.imageDataForFormat(format, encrypted: true))
        }
    }
    
    func testThatItReturnsImageDataIdentifier() {
        // given
        let message1 = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        let message2 = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // when
        let id1 = message1.imageMessageData?.imageDataIdentifier
        let id2 = message2.imageMessageData?.imageDataIdentifier
        
        
        // then
        XCTAssertNotNil(id1)
        XCTAssertNotNil(id2)
        XCTAssertNotEqual(id1, id2)
        
        XCTAssertEqual(id1, message1.imageMessageData?.imageDataIdentifier) // not random!
    }
    
    func testThatImageDataIdentifierChangesWhenChangingProcessedImage() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        let oldId = message.imageMessageData?.imageDataIdentifier
        let properties = ZMIImageProperties(size: CGSizeMake(300,300), length: 234, mimeType: "image/jpg")
        
        // when
        message.imageAssetStorage!.setImageData(self.verySmallJPEGData(), forFormat: .Medium, properties: properties)
        
        // then
        let id = message.imageMessageData?.imageDataIdentifier
        XCTAssertNotEqual(id, oldId)
    }
    
    func testThatItHasDownloadedImageWhenTheImageIsOnDisk() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        
        // then
        XCTAssertTrue(message.hasDownloadedImage)
    }
    
    func testThatItHasDownloadedImageWhenTheOriginalIsOnDisk() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertTrue(message.hasDownloadedImage)
    }
    
    func testThatDoesNotHaveDownloadedImageWhenTheImageIsNotOnDisk() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        
        // when
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: .Medium, encrypted: false)
        
        // then
        XCTAssertFalse(message.hasDownloadedImage)
    }
    
    func testThatRequestingImageDownloadFiresANotification() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        message.managedObjectContext?.saveOrRollback()
        
        // expect
        let _ = self.expectationForNotification(ZMAssetClientMessage.ImageDownloadNotificationName, object: message.objectID, handler: nil)
        
        // when
        message.requestImageDownload()

        // then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
    }
}


// MARK: - UpdateEvents
extension ZMAssetClientMessageTests {
    
    func testThatItCreatesOTRAssetMessagesFromMediumUpdateEvent() {
        let previewAssetId = NSUUID.createUUID()
        let mediumAssetId = NSUUID.createUUID()
        
        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {

            // given
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
            conversation.remoteIdentifier = NSUUID.createUUID()
            let nonce = NSUUID.createUUID()
            let imageData = self.verySmallJPEGData()
            let assetId = format == .Medium ? mediumAssetId : previewAssetId
            let genericMessage = ZMGenericMessage(imageData: imageData, format: format, nonce: nonce.transportString())
            let dataPayload = [
                "info" : genericMessage.data().base64String(),
                "id" : assetId.transportString()
            ]
            
            let payload = self.payloadForMessageInConversation(conversation, type: EventConversationAddOTRAsset, data: dataPayload)
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)
            
            // when
            var sut : ZMAssetClientMessage? = nil
            self.performPretendingUiMocIsSyncMoc { () -> Void in
                sut = ZMAssetClientMessage.createOrUpdateMessageFromUpdateEvent(updateEvent, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
            }
            
            // then
            XCTAssertNotNil(sut)
            XCTAssertEqual(sut!.conversation, conversation)
            XCTAssertEqual(sut!.sender?.remoteIdentifier!.transportString(), payload["from"] as? String)
            XCTAssertEqual(sut!.serverTimestamp?.transportString(), payload["time"] as? String)
            
            XCTAssertTrue(sut!.isEncrypted)
            XCTAssertFalse(sut!.isPlainText)
            XCTAssertEqual(sut!.nonce, nonce)
            XCTAssertEqual(sut!.imageAssetStorage!.genericMessageForFormat(format)?.data(), genericMessage.data())
            XCTAssertEqual(sut!.assetId, format == .Medium ? mediumAssetId : nil)
        }
    }

    func testThatItCreatesOTRAssetMessagesFromFileThumbnailUpdateEvent() {

        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.remoteIdentifier = NSUUID.createUUID()
        let nonce = NSUUID.createUUID()
        let thumbnailId = NSUUID.createUUID()
        let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: NSData.zmRandomSHA256Key(), sha256: NSData.zmRandomSHA256Key())
        let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
        let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: 256, mimeType: "video/mp4", remoteData: remoteData, imageMetaData: imageMetaData))
        
        let genericMessage = ZMGenericMessage.genericMessage(withAsset: asset, messageID: nonce.transportString())
        
        let dataPayload = [
            "info" : genericMessage.data().base64String(),
            "id" : thumbnailId.transportString()
        ]
        
        let payload = self.payloadForMessageInConversation(conversation, type: EventConversationAddOTRAsset, data: dataPayload)
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)
        
        // when
        var sut: ZMAssetClientMessage!
        performPretendingUiMocIsSyncMoc {
            sut = ZMAssetClientMessage.createOrUpdateMessageFromUpdateEvent(updateEvent, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.conversation?.remoteIdentifier, conversation.remoteIdentifier)
        XCTAssertEqual(sut.sender?.remoteIdentifier!.transportString(), payload["from"] as? String)
        XCTAssertEqual(sut.serverTimestamp?.transportString(), payload["time"] as? String)
        XCTAssertEqual(sut.fileMessageData?.thumbnailAssetID, thumbnailId.transportString())
        
        XCTAssertTrue(sut.isEncrypted)
        XCTAssertFalse(sut.isPlainText)
        XCTAssertEqual(sut.nonce, nonce)
        XCTAssertNotNil(sut.fileMessageData)
    }
    
    func testThatItDoesNotUpdateTheTimestampIfLater() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.remoteIdentifier = NSUUID.createUUID()
            let nonce = NSUUID.createUUID()
            let thumbnailId = NSUUID.createUUID()
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: NSData.zmRandomSHA256Key(), sha256: NSData.zmRandomSHA256Key())
            let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: 256, mimeType: "video/mp4", remoteData: remoteData, imageMetaData: imageMetaData))
            let firstDate = NSDate(timeIntervalSince1970: 12334)
            let secondDate = firstDate.dateByAddingTimeInterval(234444)
            
            let genericMessage = ZMGenericMessage.genericMessage(withAsset: asset, messageID: nonce.transportString())
            
            let dataPayload = [
                "info" : genericMessage.data().base64String(),
                "id" : thumbnailId.transportString()
            ]
            
            let payload1 = self.payloadForMessageInConversation(conversation, type: EventConversationAddOTRAsset, data: dataPayload, time: firstDate)
            let updateEvent1 = ZMUpdateEvent(fromEventStreamPayload: payload1, uuid: nil)
            let payload2 = self.payloadForMessageInConversation(conversation, type: EventConversationAddOTRAsset, data: dataPayload, time: secondDate)
            let updateEvent2 = ZMUpdateEvent(fromEventStreamPayload: payload2, uuid: nil)
            
            
            // when
            let sut = ZMAssetClientMessage.createOrUpdateMessageFromUpdateEvent(updateEvent1, inManagedObjectContext: self.syncMOC, prefetchResult: nil)
            sut.updateWithUpdateEvent(updateEvent2, forConversation: conversation, isUpdatingExistingMessage: true)
            
            // then
            XCTAssertEqual(sut.serverTimestamp, firstDate)

        }
    }
    
    func testThatItUpdatesTheTimestampIfEarlier() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.remoteIdentifier = NSUUID.createUUID()
            let nonce = NSUUID.createUUID()
            let thumbnailId = NSUUID.createUUID()
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: NSData.zmRandomSHA256Key(), sha256: NSData.zmRandomSHA256Key())
            let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: 256, mimeType: "video/mp4", remoteData: remoteData, imageMetaData: imageMetaData))
            let firstDate = NSDate(timeIntervalSince1970: 12334)
            let secondDate = firstDate.dateByAddingTimeInterval(234444)
            
            let genericMessage = ZMGenericMessage.genericMessage(withAsset: asset, messageID: nonce.transportString())
            
            let dataPayload = [
                "info" : genericMessage.data().base64String(),
                "id" : thumbnailId.transportString()
            ]
            
            let payload1 = self.payloadForMessageInConversation(conversation, type: EventConversationAddOTRAsset, data: dataPayload, time: secondDate)
            let updateEvent1 = ZMUpdateEvent(fromEventStreamPayload: payload1, uuid: nil)
            let payload2 = self.payloadForMessageInConversation(conversation, type: EventConversationAddOTRAsset, data: dataPayload, time: firstDate)
            let updateEvent2 = ZMUpdateEvent(fromEventStreamPayload: payload2, uuid: nil)
            
            
            // when
            let sut = ZMAssetClientMessage.createOrUpdateMessageFromUpdateEvent(updateEvent1, inManagedObjectContext: self.syncMOC, prefetchResult: nil)
            sut.updateWithUpdateEvent(updateEvent2, forConversation: conversation, isUpdatingExistingMessage: true)
            
            // then
            XCTAssertEqual(sut.serverTimestamp, firstDate)
        }
    }
}

// MARK: - GIF Data

extension ZMAssetClientMessageTests {
    
    func testThatIsNotAnAnimatedGifWhenItHasNoMediumData() {
        
        // given
        let data = sampleProcessedImageData(.Preview)
        let message = ZMAssetClientMessage(originalImageData: data, nonce: .createUUID(), managedObjectContext: uiMOC)
        message.isEncrypted = true
        let testProperties = ZMIImageProperties(size: CGSizeMake(33,55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.imageAssetStorage!.setImageData(data, forFormat: .Preview, properties: testProperties)
        
        // then
        XCTAssertFalse(message.imageMessageData!.isAnimatedGIF);
    }
}

// MARK: - Message Deletion

extension ZMAssetClientMessageTests {
    
    func testThatAnAssetClientMessageWithFileDataCanBeDeleted_Sent() {
        checkThatFileMessageCanBeDeleted(true, .Sent)
    }
    
    func testThatAnAssetClientMessageWithFileDataCanBeDeleted_Delivered() {
        checkThatFileMessageCanBeDeleted(true, .Delivered)
    }
    
    func testThatAnAssetClientMessageWithFileDataCanBeDeleted_Expired() {
        checkThatFileMessageCanBeDeleted(true, .FailedToSend)
    }
    
    func testThatAnAssetClientMessageWithFileDataCan_Not_BeDeleted_Pending() {
        checkThatFileMessageCanBeDeleted(false, .Pending)
    }
    
    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Sent() {
        checkThatImageAssetMessageCanBeDeleted(true, .Sent)
    }
    
    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Delivered() {
        checkThatImageAssetMessageCanBeDeleted(true, .Delivered)
    }
    
    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Expired() {
        checkThatImageAssetMessageCanBeDeleted(true, .FailedToSend)
    }
    
    func testThatAnAssetClientMessageWithImageDataCan_Not_BeDeleted_Pending() {
        checkThatImageAssetMessageCanBeDeleted(false, .Pending)
    }

    // MARK: Helper
    
    func checkThatFileMessageCanBeDeleted(canBeDeleted: Bool, _ state: ZMDeliveryState) {
        syncMOC.performBlockAndWait {
            // given
            _ = self.createTestFile(self.testURL)
            defer { self.removeTestFile(self.testURL) }
            let fileMetadata = ZMFileMetadata(fileURL: self.testURL)
            
            let sut = ZMAssetClientMessage(fileMetadata: fileMetadata,
                nonce: NSUUID.createUUID(),
                managedObjectContext: self.syncMOC)
            sut.isEncrypted = true
            sut.visibleInConversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            sut.conversation?.remoteIdentifier = NSUUID()
            sut.sender = ZMUser.selfUserInContext(self.syncMOC)
            sut.sender?.remoteIdentifier = NSUUID()
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(sut.isEncrypted)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when
            self.updateMessageState(sut, state: state)
            XCTAssertEqual(sut.deliveryState.rawValue, state.rawValue)
            
            // then
            XCTAssertEqual(sut.canBeDeleted, canBeDeleted)
        }
    }
    
    func checkThatImageAssetMessageCanBeDeleted(canBeDeleted: Bool, _ state: ZMDeliveryState) {
        // given
        let sut = createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        
        sut.isEncrypted = true
        sut.visibleInConversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        sut.conversation?.remoteIdentifier = NSUUID()
        sut.sender = ZMUser.selfUserInContext(uiMOC)
        sut.sender?.remoteIdentifier = NSUUID()
        
        XCTAssertNil(sut.fileMessageData)
        XCTAssertTrue(sut.isEncrypted)
        XCTAssertNotNil(sut.imageAssetStorage)
        XCTAssertNotNil(sut.imageMessageData)
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // when
        updateMessageState(sut, state: state)
        XCTAssertEqual(sut.deliveryState, state)
        
        // then
        XCTAssertEqual(sut.canBeDeleted, canBeDeleted)
    }
    
    func updateMessageState(message: ZMOTRMessage, state: ZMDeliveryState) {
        if state == .Sent || state == .Delivered {
            message.delivered = true
        } else if state == .FailedToSend {
            message.expire()
        }
        if state == .Delivered {
            let genericMessage = ZMGenericMessage(confirmation: message.nonce.transportString(), type: .DELIVERED, nonce: NSUUID.createUUID().transportString())
            ZMMessageConfirmation.createOrUpdateMessageConfirmation(genericMessage, conversation: message.conversation!, sender: message.sender!)
            message.managedObjectContext?.saveOrRollback()
        }
    }
    
}
