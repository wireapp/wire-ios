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

enum MimeType : String {
    case text = "text/plain"
}

class BaseZMAssetClientMessageTests : BaseZMClientMessageTests {
    
    var message: ZMAssetClientMessage!
    var currentTestURL : URL?
    
    override func setUp() {
        super.setUp()
        self.setUpCaches()
    }
    
    override func tearDown() {
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 2))
        if let url = currentTestURL {
            removeTestFile(url)
        }
        super.tearDown()
    }
    
    func appendImageMessage(toConversation conversation: ZMConversation) {
        let imageData = verySmallJPEGData()
        let messageNonce = UUID.create()
        message = conversation.appendOTRMessage(withImageData: imageData, nonce: messageNonce)
        
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.count), mimeType:"image/jpeg")
        
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(), macKey: Data.zmRandomSHA256Key(), mac: Data.zmRandomSHA256Key())
        
        let mediumMessage = ZMGenericMessage.genericMessage(mediumImageProperties: properties, processedImageProperties: properties, encryptionKeys: keys, nonce: messageNonce.transportString(), format: .medium)
        message.add(mediumMessage)
        
        let previewMessage = ZMGenericMessage.genericMessage(mediumImageProperties: properties, processedImageProperties: properties, encryptionKeys: keys, nonce: messageNonce.transportString(), format: .preview)
        message.add(previewMessage)
    }
    
    func appendImageMessage(_ format: ZMImageFormat, to conversation: ZMConversation) -> ZMAssetClientMessage {
        let otherFormat = format == ZMImageFormat.medium ? ZMImageFormat.preview : ZMImageFormat.medium
        let imageData = verySmallJPEGData()
        let messageNonce = UUID.create()
        let message = conversation.appendOTRMessage(withImageData: imageData, nonce: messageNonce)
        
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.count), mimeType:"image/jpeg")
        
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(), macKey: Data.zmRandomSHA256Key(), mac: Data.zmRandomSHA256Key())
        
        let imageMessage = ZMGenericMessage.genericMessage(mediumImageProperties: properties, processedImageProperties: properties, encryptionKeys: keys, nonce: messageNonce.transportString(), format: format, expiresAfter: NSNumber(value: message.deletionTimeout))
        let emptyImageMessage = ZMGenericMessage.genericMessage(mediumImageProperties: nil, processedImageProperties: nil, encryptionKeys: nil, nonce: messageNonce.transportString(), format: otherFormat, expiresAfter: NSNumber(value: message.deletionTimeout))
        message.add(imageMessage)
        message.add(emptyImageMessage)
        
        return message
    }
    
    
    func addFile(filename: String? = nil) -> ZMFileMetadata {
        if let fileName = filename {
            currentTestURL = testURLWithFilename(fileName)
        } else {
            currentTestURL = testURLWithFilename("file.dat")
        }
        _ = createTestFile(currentTestURL!)
        let fileMetadata = ZMFileMetadata(fileURL: currentTestURL!)
        return fileMetadata
    }
    
    func testURLWithFilename(_ filename: String) -> URL {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsURL = URL(fileURLWithPath: documents)
        return documentsURL.appendingPathComponent(filename)
    }
    
    func createTestFile(_ url: URL) -> Data {
        let data: Data! = "Some other data".data(using: String.Encoding.utf8)
        try! data.write(to: url, options: [])
        return data
    }
    
    func removeTestFile(_ url: URL) {
        do {
            let fm = FileManager.default
            if !fm.fileExists(atPath: url.path) {
                return
            }
            try fm.removeItem(at: url)
        } catch {
            XCTFail("Error removing file: \(error)")
        }
    }

}


class ZMAssetClientMessageTests : BaseZMAssetClientMessageTests {
    
    func testThatItStoresPlainImageMessageDataForPreview() {
        let message = ZMAssetClientMessage.insertNewObject(in: self.uiMOC);
        message.nonce = UUID.create()
        
        let imageData = self.verySmallJPEGData()
        XCTAssertNotNil(message.imageAssetStorage!.updateMessage(withImageData: imageData, for: ZMImageFormat.preview))
        
        let storedData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.preview, encrypted: message.isEncrypted)
        AssertOptionalNotNil(storedData) { storedData in
            XCTAssertEqual(storedData, imageData)
        }
    }
    
    func testThatItStoresPlainImageMessageDataForMedium() {
        let message = ZMAssetClientMessage.insertNewObject(in: self.uiMOC);
        message.nonce = UUID.create()
        
        let imageData = self.verySmallJPEGData()
        XCTAssertNotNil(message.imageAssetStorage!.updateMessage(withImageData: imageData, for: ZMImageFormat.medium))
        
        let storedData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.medium, encrypted: message.isEncrypted)
        AssertOptionalNotNil(storedData) { storedData in
            XCTAssertEqual(storedData, imageData)
        }
    }
    
    func testThatItDecryptsEncryptedImageMessageData() {
        //given
        let message = ZMAssetClientMessage.insertNewObject(in: self.uiMOC);
        message.nonce = UUID.create()
        message.isEncrypted = true
        let imageData = self.verySmallJPEGData()
        
        self.uiMOC.zm_imageAssetCache.storeAssetData(message.nonce, format: ZMImageFormat.medium, encrypted: false, data: imageData)
        
        let keys = self.uiMOC.zm_imageAssetCache.encryptFileAndComputeSHA256Digest(message.nonce, format: ZMImageFormat.medium)
        let encryptedImageData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.medium, encrypted: true)!
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: ZMImageFormat.medium, encrypted: false)
        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData), length: UInt(imageData.count), mimeType: "image/jpeg")
        message.add(ZMGenericMessage.genericMessage(mediumImageProperties: imageProperties, processedImageProperties: imageProperties, encryptionKeys: keys, nonce: message.nonce.transportString(), format: ZMImageFormat.medium))
        
        // when
        XCTAssertNotNil(message.imageAssetStorage!.updateMessage(withImageData: encryptedImageData, for: ZMImageFormat.medium))
        
        let decryptedImageData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.medium, encrypted: false)
        AssertOptionalNotNil(decryptedImageData) { decryptedImageData in
            XCTAssertEqual(decryptedImageData, imageData)
        }
    }
    
    func testThatItDeletesMessageIfImageMessageDataCanNotBeDecrypted() {
        //given
        let message = ZMAssetClientMessage.insertNewObject(in: self.uiMOC);
        message.nonce = UUID.create()
        message.isEncrypted = true
        let imageData = self.verySmallJPEGData()
        
        //store original image
        self.uiMOC.zm_imageAssetCache.storeAssetData(message.nonce, format: ZMImageFormat.medium, encrypted: false, data: imageData)
        
        //encrypt image
        let keys = self.uiMOC.zm_imageAssetCache.encryptFileAndComputeSHA256Digest(message.nonce, format: ZMImageFormat.medium)
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: ZMImageFormat.medium, encrypted: true)
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: ZMImageFormat.medium, encrypted: false)

        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData), length: UInt(imageData.count), mimeType: "image/jpeg")
        message.add(ZMGenericMessage.genericMessage(mediumImageProperties: imageProperties, processedImageProperties: imageProperties, encryptionKeys: keys, nonce: message.nonce.transportString(), format: ZMImageFormat.medium))
        
        // when
        //pass in some wrong data (i.e. plain data instead of encrypted)
        XCTAssertNil(message.imageAssetStorage!.updateMessage(withImageData: imageData, for: ZMImageFormat.medium))
        
        let decryptedImageData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.medium, encrypted: false)
        XCTAssertNil(decryptedImageData)
        XCTAssertTrue(message.isDeleted);
    }
    
    
    func testThatItMarksMediumNeededToBeDownloadedIfNoEncryptedNoDecryptedDataStored() {
        
        let message = ZMAssetClientMessage.insertNewObject(in: self.uiMOC);
        message.nonce = UUID.create()
        message.isEncrypted = true
        let imageData = self.verySmallJPEGData()
        
        self.uiMOC.zm_imageAssetCache.storeAssetData(message.nonce, format: ZMImageFormat.medium, encrypted: false, data: imageData)
        
        let keys = self.uiMOC.zm_imageAssetCache.encryptFileAndComputeSHA256Digest(message.nonce, format: ZMImageFormat.medium)
        let encryptedImageData = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: ZMImageFormat.medium, encrypted: true)!
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: ZMImageFormat.medium, encrypted: false)
        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData), length: UInt(imageData.count), mimeType: "image/jpeg")
        message.add(ZMGenericMessage.genericMessage(mediumImageProperties: imageProperties, processedImageProperties: imageProperties, encryptionKeys: keys, nonce: message.nonce.transportString(), format: ZMImageFormat.medium))
        
        // when
        XCTAssertNotNil(message.imageAssetStorage!.updateMessage(withImageData: encryptedImageData, for: ZMImageFormat.medium))
        XCTAssertTrue(message.hasDownloadedImage)
        
        // pretend that there are no encrypted no decrypted message data stored
        // i.e. cache folder is cleared but message is already processed
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: ZMImageFormat.medium, encrypted: false)
        
        XCTAssertNil(message.imageMessageData?.mediumData)
        XCTAssertFalse(message.hasDownloadedImage)
    }
    
}

// MARK: - ZMAsset / ZMFileMessageData

extension ZMAssetClientMessageTests {
    
    func testThatItCreatesFileAssetMessageInTheRightStateToBeUploaded()
    {
        // given
        let nonce = UUID.create()
        let fileMetadata = addFile()
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC,
            expiresAfter: 0)
        
        // then
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.delivered)
        XCTAssertEqual(sut.transferState, ZMFileTransferState.uploading)
        XCTAssertEqual(sut.filename, currentTestURL!.lastPathComponent)
        XCTAssertNotNil(sut.fileMessageData)
    }
    
    func testThatItHasDownloadedFileWhenTheFileIsOnDisk()
    {
        // given
        let nonce = UUID.create()
        let fileMetadata = addFile()
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC,
            expiresAfter: 0)
        
        // then
        XCTAssertTrue(sut.hasDownloadedFile)
        XCTAssertFalse(sut.hasDownloadedImage)
    }
    
    func testThatItHasNoDownloadedFileWhenTheFileIsNotOnDisk()
    {
        // given
        let nonce = UUID.create()
        let fileMetadata = addFile()
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC,
            expiresAfter: 0)
        
        self.uiMOC.zm_fileAssetCache.deleteAssetData(sut.nonce, fileName: sut.filename!, encrypted: false)
        
        // then
        XCTAssertFalse(sut.hasDownloadedFile)
        XCTAssertFalse(sut.hasDownloadedImage)
    }
    
    func testThatItHasDownloadedImageWhenTheProcessedThumbnailIsOnDisk()
    {
        // given
        let nonce = UUID.create()
        let mimeType = "video/mp4"
        let fileMetadata = addFile()

        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC,
            expiresAfter: 0)
        
        self.uiMOC.zm_imageAssetCache.storeAssetData(sut.nonce, format: .medium, encrypted: false, data: Data.secureRandomData(ofLength: 100))
        defer { self.uiMOC.zm_imageAssetCache.deleteAssetData(sut.nonce, format: .medium, encrypted: false) }
        
        // then
        XCTAssertTrue(sut.hasDownloadedImage)
    }
    
    func testThatItHasDownloadedImageWhenTheOriginalThumbnailIsOnDisk()
    {
        // given
        let nonce = UUID.create()
        let mimeType = "video/mp4"
        let fileMetadata = addFile()
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC,
            expiresAfter: 0)
        
        self.uiMOC.zm_imageAssetCache.storeAssetData(sut.nonce, format: .original, encrypted: false, data: Data.secureRandomData(ofLength: 100))
        defer { self.uiMOC.zm_imageAssetCache.deleteAssetData(sut.nonce, format: .medium, encrypted: false) }
        
        // then
        XCTAssertTrue(sut.hasDownloadedImage)
    }
    
    func testThatAnImageAssetHasNoFileMessageData()
    {
        // given
        let nonce = UUID.create()
        let data = createTestFile(testURLWithFilename("file.dat"))
        
        // when
        let sut = ZMAssetClientMessage(
            originalImageData: data,
            nonce: nonce,
            managedObjectContext: self.uiMOC,
            expiresAfter: 0
        )
        
        // then
        XCTAssertNil(sut.filename)
        XCTAssertNil(sut.fileMessageData)
    }
    
    func testThatItSetsTheGenericAssetMessageWhenCreatingMessage()
    {
        // given
        let nonce = UUID.create()
        let mimeType = "text/plain"
        let filename = "document.txt"
        let url = testURLWithFilename(filename)
        let data = createTestFile(url)
        defer { removeTestFile(url) }
        let size = UInt64(data.count)
        let fileMetadata = ZMFileMetadata(fileURL: url)
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC,
            expiresAfter: 0)
        
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
        let nonce = UUID.create()
        let mimeType = "text/plain"
        let filename = "document.txt"
        let url = testURLWithFilename(filename)
        let data = createTestFile(url)
        let fileMetadata = ZMFileMetadata(fileURL: url)
        
        // when
        let sut = ZMAssetClientMessage(
            fileMetadata: fileMetadata,
            nonce: nonce,
            managedObjectContext: uiMOC,
            expiresAfter: 0)

        XCTAssertNotNil(sut)
        
        let otrKey = Data.randomEncryptionKey()
        let encryptedData = data.zmEncryptPrefixingPlainTextIV(key: otrKey)
        let sha256 = encryptedData.zmSHA256Digest()
        let builder = ZMAssetImageMetaData.builder()!
        builder.setWidth(10)
        builder.setHeight(10)
        let preview = ZMAssetPreview.preview(
            withSize: UInt64(data.count),
            mimeType: mimeType,
            remoteData: ZMAssetRemoteData.remoteData(withOTRKey: otrKey, sha256: sha256),
            imageMetaData: builder.build()!)
        let previewAsset = ZMAsset.asset(preview: preview)
        let previewMessage = ZMGenericMessage.genericMessage(asset: previewAsset, messageID: nonce.transportString())

        
        // when
        sut.add(previewMessage)
        
        // then
        XCTAssertEqual(sut.genericAssetMessage?.messageId, nonce.transportString())
        
        guard let asset = sut.genericAssetMessage?.asset else { return XCTFail() }
        XCTAssertNotNil(asset)
        XCTAssertTrue(asset.hasOriginal())
        XCTAssertTrue(asset.hasPreview())
        XCTAssertEqual(asset.original.name, filename)
        XCTAssertEqual(sut.fileMessageData?.filename, filename)
        XCTAssertEqual(asset.original.mimeType, mimeType)
        XCTAssertEqual(asset.original.size, UInt64(data.count))
        XCTAssertEqual(asset.preview, preview)
    }
    
    func testThatItUpdatesTheMetaDataWhenOriginalAssetMessageGetMerged()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage.insertNewObject(in: uiMOC)
        sut.nonce = nonce
        let mimeType = "text/plain"
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.genericMessage(
            asset: .asset(withOriginal: .original(withSize: 256, mimeType: mimeType, name: name!)),
            messageID: nonce.transportString()
        )
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent())
        
        // then
        XCTAssertEqual(sut.fileMessageData?.size, 256)
        XCTAssertEqual(sut.fileMessageData?.mimeType, mimeType)
        XCTAssertEqual(sut.fileMessageData?.filename, name)
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.uploading)
    }
    
    func testThatItUpdatesTheTransferStateWhenTheUploadedMessageIsMerged()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage.insertNewObject(in: uiMOC)
        sut.nonce = nonce
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.genericMessage(withUploadedOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key(), messageID: nonce.transportString())
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent())
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.uploaded)
    }
    
    func testThatItUpdatesTheTransferStateWhenTheNotUploadedCanceledMessageIsMerged()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage.insertNewObject(in: uiMOC)
        sut.nonce = nonce
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.genericMessage(notUploaded: .CANCELLED, messageID: nonce.transportString())
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent())
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.cancelledUpload)
    }
    
    /// This is testing a race condition on the receiver side if the sender cancels but not fast enough, and he BE just got the entire payload
    func testThatItUpdatesTheTransferStateWhenTheCanceledMessageIsMergedAfterUploadingSuccessfully()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage.insertNewObject(in: uiMOC)
        sut.nonce = nonce
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let uploadedMessage = ZMGenericMessage.genericMessage(withUploadedOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key(), messageID: nonce.transportString())
        sut.update(with: uploadedMessage, updateEvent: ZMUpdateEvent())
        let canceledMessage = ZMGenericMessage.genericMessage(notUploaded: .CANCELLED, messageID: nonce.transportString())
        sut.update(with: canceledMessage, updateEvent: ZMUpdateEvent())
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.cancelledUpload)
    }
    
    func testThatItUpdatesTheTransferStateWhenTheNotUploadedFailedMessageIsMerged()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage.insertNewObject(in: uiMOC)
        sut.nonce = nonce
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.genericMessage(notUploaded: .FAILED, messageID: nonce.transportString())
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent())
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.failedUpload)
    }
    
    func testThatItUpdatesTheAssetIdWhenTheUploadedMessageIsMerged()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let assetId = UUID.create()
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage.insertNewObject(in: uiMOC)
        sut.nonce = nonce
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        let dataPayload = [
            "id": assetId.transportString()
        ]
        
        let payload = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload)
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload!, uuid: UUID.create())
        // when
        let originalMessage = ZMGenericMessage.genericMessage(withUploadedOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key(), messageID: nonce.transportString())
        sut.update(with: originalMessage, updateEvent: updateEvent)
        
        // then
        XCTAssertEqual(sut.assetId, assetId)
    }
    
    
    func testThatItReturnsAValidFileMessageData() {
        self.syncMOC.performAndWait {
            // given
            let nonce = UUID.create()
            let fileMetadata = self.addFile()
            
            // when
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            // then
            XCTAssertNotNil(sut)
            XCTAssertNotNil(sut.fileMessageData)
        }
    }
    
    func testThatItReturnsTheEncryptedUploadedDataWhenItHasAUploadedGenericMessageInTheDataSet() {
        self.syncMOC.performAndWait { 
            // given
            let nonce = UUID.create()
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            // when
            let otrKey = Data.randomEncryptionKey()
            let sha256 = Data.zmRandomSHA256Key()
            sut.add(.genericMessage(withUploadedOTRKey: otrKey, sha256: sha256, messageID: nonce.transportString()))
            
            // then
            XCTAssertNotNil(sut)
            guard let asset = sut.genericAssetMessage?.asset else { return XCTFail() }
            XCTAssertTrue(asset.hasUploaded())
            let uploaded = asset.uploaded!
            XCTAssertEqual(uploaded.otrKey, otrKey)
            XCTAssertEqual(uploaded.sha256, sha256)
        }
        
    }
    
    func testThatItAddsAnUploadedGenericMessageToTheDataSet() {
        self.syncMOC.performAndWait {
            // given
            let nonce = UUID.create()
            let fileMetadata = self.addFile()
            
            let selfClient = UserClient.insertNewObject(in: self.syncMOC)
            selfClient.remoteIdentifier = self.name
            selfClient.user = .selfUser(in: self.syncMOC)
            self.syncMOC.setPersistentStoreMetadata(selfClient.remoteIdentifier, forKey: "PersistedClientId")
            XCTAssertNotNil(ZMUser.selfUser(in: self.syncMOC).selfClient())
            
            let user2 = ZMUser.insertNewObject(in:self.syncMOC)
            user2.remoteIdentifier = UUID.create()
            let user2Client = UserClient.insertNewObject(in: self.syncMOC)
            user2Client.remoteIdentifier = UUID.create().transportString()
            
            let conversation = ZMConversation.insertNewObject(in:self.syncMOC)
            conversation.conversationType = .group
            conversation.addParticipant(user2)
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            sut.visibleInConversation = conversation
            
            // when
            sut.add(ZMGenericMessage.genericMessage(
                withUploadedOTRKey: .randomEncryptionKey(),
                sha256: .zmRandomSHA256Key(),
                messageID: nonce.transportString()
                )
            )
            
            // then
            XCTAssertNotNil(sut)
            let encryptedUpstreamMetaData = sut.encryptedMessagePayloadForDataType(.fullAsset)
            XCTAssertNotNil(encryptedUpstreamMetaData)
            self.syncMOC.setPersistentStoreMetadata(nil, forKey: "PersistedClientId")
        }
    }

    
    func testThatItSetsTheCorrectStateWhen_RequestFileDownload_IsBeingCalled() {
        // given
        let sut = ZMAssetClientMessage.insertNewObject(in: uiMOC)
        sut.nonce = .create()
        let original = ZMGenericMessage.genericMessage(asset: .asset(withOriginal: .original(withSize: 256, mimeType: "text/plain", name: name!)), messageID: sut.nonce.transportString())
        sut.add(original)
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut.fileMessageData)
        
        // when
        sut.fileMessageData?.requestFileDownload()
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.downloading)
    }
    
    func testThatItCancelsUpload() {
        self.syncMOC.performAndWait {
            
            // given
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            XCTAssertEqual(sut.transferState, ZMFileTransferState.uploading)
            
            // when
            sut.fileMessageData?.cancelTransfer()
            
            // then
            XCTAssertEqual(sut.transferState, ZMFileTransferState.cancelledUpload)
            XCTAssertEqual(sut.progress, 0.0)
        }
    }
    
    func testThatItCanCancelsUploadMultipleTimes() {
        // given
        self.syncMOC.performAndWait {
            
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            XCTAssertEqual(sut.transferState, ZMFileTransferState.uploading)
            
            // when / then
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.cancelledUpload)
            
            sut.resend()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.uploading)
            XCTAssertEqual(sut.progress, 0.0);
            
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.cancelledUpload)
            
            sut.resend()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.uploading)
            XCTAssertEqual(sut.progress, 0.0)
        }
        
    }
    
    func testThatItCancelsDownload() {
        self.syncMOC.performAndWait {
            
            // given
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            sut.transferState = .downloading
            sut.delivered = true
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when
            sut.fileMessageData?.cancelTransfer()
            
            // then
            XCTAssertEqual(sut.transferState, ZMFileTransferState.uploaded)
            XCTAssertEqual(sut.progress, 0.0)
        }
    }
    
    func testThatItAppendsA_NotUploadedCancelled_MessageWhenUploadFromThisDeviceIsCancelled() {
        self.syncMOC.performAndWait {
            
            // given
            let fileMetadata = self.addFile()

            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            sut.transferState = .uploading
            sut.delivered = false
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when
            sut.fileMessageData?.cancelTransfer()
            
            // then
            let messages = sut.dataSet.flatMap { ($0 as AnyObject).genericMessage! }
            let assets = messages.filter { $0.hasAsset() }.flatMap { $0.asset }
            XCTAssertEqual(assets.count, 2)
            let notUploaded = assets.filter { $0.hasNotUploaded() }.flatMap { $0.notUploaded }
            XCTAssertEqual(notUploaded.count, 1)
            XCTAssertEqual(notUploaded.first, ZMAssetNotUploaded.CANCELLED)
            
            XCTAssertEqual(sut.transferState, ZMFileTransferState.cancelledUpload)
            XCTAssertEqual(sut.progress, 0.0)
        }
    }
    
    func testThatItSetsTheTransferStateToDonwloadedWhen_RequestFileDownload_IsCalledButFileIsAlreadyOnDisk() {
        self.syncMOC.performAndWait {
            
            // given
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            sut.transferState = .uploaded
            sut.delivered = true
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when
            sut.fileMessageData?.requestFileDownload()
            
            // then
            XCTAssertEqual(sut.transferState, ZMFileTransferState.downloaded)
        }
    }
    
    func testThatItItReturnsTheGenericMessageDataAndInculdesTheNotUploadedWhenItIsPresent_Placeholder() {
        self.syncMOC.performAndWait {
            
            // given
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            sut.delivered = true
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when we cancel the transfer
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.cancelledUpload)
            
            // then the generic message data should include the not uploaded
            let assetMessage = sut.genericAssetMessage!
            let genericMessage = sut.genericMessage(for: .placeholder)!
            
            XCTAssertTrue(assetMessage.asset.hasNotUploaded())
            XCTAssertEqual(assetMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
            XCTAssertTrue(genericMessage.asset.hasNotUploaded())
            XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        }
    }
        
    func testThatItPostsANotificationWhenTheDownloadOfTheMessageIsCancelled() {
        self.syncMOC.performAndWait {
            
            // given
            let sut = ZMAssetClientMessage.insertNewObject(in: self.syncMOC)
            sut.nonce = .create()
            let original = ZMGenericMessage.genericMessage(asset: .asset(withOriginal: .original(withSize: 256, mimeType: "text/plain", name: self.name!)), messageID: sut.nonce.transportString())
            sut.add(original)
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())

            _ = self.expectation(forNotification: ZMAssetClientMessageDidCancelFileDownloadNotificationName, object:sut.objectID, handler: nil)
            
            sut.requestFileDownload()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.downloading)
            
            // when
            sut.fileMessageData?.cancelTransfer()
            
            // then
            XCTAssertEqual(sut.transferState, ZMFileTransferState.uploaded)
        }
    }
    
    func testThatItPreparesMessageForResend() {
        self.syncMOC.performAndWait {
            
            // given
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            self.syncConversation.mutableMessages.add(sut)
            sut.delivered = true
            sut.progress = 56
            sut.transferState = .failedUpload
            sut.uploadState = .uploadingFailed
            
            // when
            sut.resend()
            
            // then
            XCTAssertEqual(sut.uploadState, ZMAssetUploadState.uploadingPlaceholder)
            XCTAssertFalse(sut.delivered)
            XCTAssertEqual(sut.transferState, ZMFileTransferState.uploading)
            XCTAssertEqual(sut.progress, 0)
        }
    }
    
    func testThatItReturnsNilAssetIdOnANewlyCreatedMessage() {
        self.syncMOC.performAndWait {
            
            // given
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            // then
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
        }
    }
    
    func testThatItReturnsAssetIdWhenSettingItDirectly() {
        self.syncMOC.performAndWait {
            
            // given
            let previewSize : UInt64 = 46
            let previewMimeType = "image/jpg"
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
            let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            
            let uuid = UUID.create().transportString()
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            sut.add(ZMGenericMessage.genericMessage(asset: asset, messageID: "\(sut.nonce)"))
            
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
        self.syncMOC.performAndWait {
            
            // given
            let previewSize : UInt64 = 46
            let previewMimeType = "image/jpg"
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
            let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            
            let uuid = UUID.create().transportString()
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            let genericMessage = ZMGenericMessage.genericMessage(asset: asset, messageID: "\(sut.nonce)")
            let payload : [String : AnyObject] = [
                "type" : "conversation.otr-asset-add" as AnyObject,
                "data" : [
                    "id" : uuid
                ] as AnyObject
            ]
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID.create())
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            
            // when
            sut.update(with: genericMessage, updateEvent: updateEvent)
            
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
        self.syncMOC.performAndWait {
            
            // given
            let previewSize : UInt64 = 46
            let previewMimeType = "image/jpg"
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
            let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            
            let assetWithUploaded = ZMAsset.asset(withUploadedOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
            let assetWithPreview = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            let builder = ZMAssetBuilder()
            builder.merge(from: assetWithUploaded)
            builder.mergePreview(assetWithPreview.preview)
            let asset = builder.build()!
            
            let genericMessage = ZMGenericMessage.genericMessage(asset: asset, messageID: "\(sut.nonce)")
            let payload : [String : AnyObject] = [
                "type" : "conversation.otr-asset-add" as AnyObject,
                "data" : [
                    "id" : UUID.create().transportString()
                ] as AnyObject
            ]
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID.create())
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            
            
            // when
            sut.update(with: genericMessage, updateEvent: updateEvent)
            
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
        let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
        let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
        
        let uuid = UUID.create().transportString()
        let fileMetadata = self.addFile()
        
        let sut = ZMAssetClientMessage(fileMetadata: fileMetadata,
                                       nonce: UUID.create(),
                                       managedObjectContext: uiMOC,
                                       expiresAfter: 0)
        
        XCTAssertFalse(sut.genericAssetMessage!.asset.hasPreview())
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // when
        uiMOC.refresh(sut, mergeChanges: false) // Turn object into fault
        
        self.syncMOC.performAndWait {
            let sutInSyncContext = self.syncMOC.object(with: sut.objectID) as! ZMAssetClientMessage
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            let genericMessage = ZMGenericMessage.genericMessage(asset: asset, messageID: "\(sut.nonce)")
            let payload : [String : AnyObject] = [
                "type" : "conversation.otr-asset-add" as AnyObject,
                "data" : [
                    "id" : uuid
                ] as AnyObject
            ]
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID.create())
            XCTAssertNil(sutInSyncContext.fileMessageData?.thumbnailAssetID)
            
            sutInSyncContext.update(with: genericMessage, updateEvent: updateEvent) // Append preview
            XCTAssertTrue(self.syncMOC.saveOrRollback())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
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
        self.syncMOC.performAndWait {
            
            // given
            let thumbnail = self.verySmallJPEGData()
            let nonce = UUID()
            self.currentTestURL = self.testURLWithFilename("file.dat")
            _ = self.createTestFile(self.currentTestURL!)
            
            let fileMetadata = ZMFileMetadata(fileURL: self.currentTestURL!, thumbnail: thumbnail)
            
            // when
            let message = ZMAssetClientMessage(fileMetadata: fileMetadata,
                nonce: nonce,
                managedObjectContext: self.syncMOC,
                expiresAfter: 0)
            
            // then
            let storedThumbail = message.managedObjectContext?.zm_imageAssetCache.assetData(message.nonce, format: .original, encrypted: false)
            XCTAssertNotNil(storedThumbail)
            XCTAssertEqual(storedThumbail, thumbnail)
        }
    }
    func testThatItDoesNotStoresThumbnailDataIfEmpty() {
        self.syncMOC.performAndWait {
            
            // given
            let textFile = self.testURLWithFilename("robert.txt")
            
            let thumbnail = Data()
            let nonce = UUID()
            _ = self.createTestFile(textFile)
            defer { self.removeTestFile(textFile) }
            
            let fileMetadata = ZMFileMetadata(fileURL: textFile, thumbnail: thumbnail)
            
            // when
            let message = ZMAssetClientMessage(fileMetadata: fileMetadata,
                                               nonce: nonce,
                                               managedObjectContext: self.syncMOC,
                                               expiresAfter: 0)
            
            // then
            let storedThumbail = message.managedObjectContext?.zm_imageAssetCache.assetData(message.nonce, format: .original, encrypted: false)
            XCTAssertNil(storedThumbail)
        }
    }
}


// MARK: Helpers
extension ZMAssetClientMessageTests {
    
    func createOtherClientAndConversation() -> (UserClient, ZMConversation) {
        let otherUser = ZMUser.insertNewObject(in:self.syncMOC)
        otherUser.remoteIdentifier = .create()
        let otherClient = createClient(for: otherUser, createSessionWithSelfUser: true)
        let conversation = ZMConversation.insertNewObject(in:self.syncMOC)
        conversation.conversationType = .group
        conversation.addParticipant(otherUser)
        XCTAssertTrue(self.syncMOC.saveOrRollback())
        
        return (otherClient, conversation)
    }
}

// MARK: - Associated Task Identifier
extension ZMAssetClientMessageTests {
    
    func testThatItStoresTheAssociatedTaskIdentifier() {
        // given
        let sut = ZMAssetClientMessage.insertNewObject(in: self.uiMOC)
        
        // when
        let identifier = ZMTaskIdentifier(identifier: 42, sessionIdentifier: "foo")
        sut.associatedTaskIdentifier = identifier
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        self.uiMOC.refresh(sut, mergeChanges: false)
        
        // then
        XCTAssertEqual(sut.associatedTaskIdentifier, identifier)
    }
    
}

// MARK: - Message generation
extension ZMAssetClientMessageTests {
    
    func testThatItSetsGenericMediumAndPreviewDataWhenCreatingMessage()
    {
        // given
        let nonce = UUID.create()
        let image = self.verySmallJPEGData()
        
        // when
        let sut = ZMAssetClientMessage(originalImageData: image, nonce: nonce, managedObjectContext: self.uiMOC, expiresAfter: 0)
        let imageMessageStorage = sut.imageAssetStorage!
        
        // then
        XCTAssertNotNil(imageMessageStorage.mediumGenericMessage)
        XCTAssertNotNil(imageMessageStorage.previewGenericMessage)
        
    }
    
    func testThatItSavesTheOriginalFileWhenCreatingMessage()
    {
        // given
        let nonce = UUID.create()
        let image = self.verySmallJPEGData()
        
        // when
        _ = ZMAssetClientMessage(originalImageData: image, nonce: nonce, managedObjectContext: self.uiMOC, expiresAfter: 0)
        
        // then
        let fileData = self.uiMOC.zm_imageAssetCache.assetData(nonce, format: .original, encrypted: false)
        XCTAssertEqual(fileData, image)
    }

    func testThatItSetsTheOriginalImageSize()
    {
        // given
        let nonce = UUID.create()
        let image = self.verySmallJPEGData()
        let expectedSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: image)
        
        // when
        let sut = ZMAssetClientMessage(originalImageData: image, nonce: nonce, managedObjectContext: self.uiMOC, expiresAfter: 0)
        let imageMessageStorage = sut.imageAssetStorage!
        
        // then
        XCTAssertEqual(expectedSize, imageMessageStorage.originalImageSize())
    }
}



// MARK: - Post event
extension ZMAssetClientMessageTests {
    
    func testThatItSetsConversationLastServerTimestampWhenPostingPreview() {
        // given
        self.syncMOC.performGroupedBlockAndWait {
            let message = self.appendImageMessage(.preview, to: self.syncConversation)
            let date  = Date()
            let payload : [AnyHashable: Any] = ["deleted" : [String:String](), "missing" : [String:String](), "redundant":[String:String](), "time" : date.transportString()]
            
            message.uploadState = .uploadingPlaceholder
            
            // when
            message.update(withPostPayload: payload, updatedKeys: Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey))
            
            // then
            XCTAssertEqual(message.serverTimestamp, message.conversation?.lastServerTimeStamp)
        }
    }
    
    func testThatItDoesNotSetConversationLastServerTimestampWhenPostingMedium() {
        // given
        let message = appendImageMessage(.medium, to: self.conversation)
        let date  = Date()
        let payload : [AnyHashable: Any] = ["deleted" : [String:String](), "missing" : [String:String](), "redundant":[String:String](), "time" : date.transportString()]
        message.uploadState = .uploadingFullAsset
        
        // when
        message.update(withPostPayload: payload, updatedKeys: Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey))
        
        // then
        XCTAssertNotEqual(message.serverTimestamp, message.conversation?.lastServerTimeStamp)
    }
    
}


// MARK: - Image owner
extension ZMAssetClientMessageTests {
    
    func sampleImageData() -> Data {
        return self.verySmallJPEGData()
    }
    
    func sampleProcessedImageData(_ format: ZMImageFormat) -> Data {
        return "\(StringFromImageFormat(format)) fake data".data(using: String.Encoding.utf8, allowLossyConversion: true)!
    }
    
    func sampleImageProperties(_ format: ZMImageFormat) -> ZMIImageProperties {
        let mult = format == .medium ? 100 : 1
        return ZMIImageProperties(size: CGSize(width: CGFloat(300*mult), height: CGFloat(100*mult)), length: UInt(100*mult), mimeType: "image/jpeg")!
    }

    func createAssetClientMessageWithSampleImageAndEncryptionKeys(_ storeOriginal: Bool, storeEncrypted: Bool, storeProcessed: Bool, imageData: Data? = nil) -> ZMAssetClientMessage {
        let directory = self.uiMOC.zm_imageAssetCache!
        let nonce = UUID.create()
        let imageData = imageData ?? sampleImageData()
        var genericMessage : [ZMImageFormat : ZMGenericMessage] = [:]
        
        for format in [ZMImageFormat.medium, ZMImageFormat.preview] {
            let processedData = sampleProcessedImageData(format)
            let otrKey = Data.randomEncryptionKey()
            let encryptedData = processedData.zmEncryptPrefixingPlainTextIV(key: otrKey)
            let sha256 = encryptedData.zmSHA256Digest()
            let encryptionKeys = ZMImageAssetEncryptionKeys(otrKey: otrKey, sha256: sha256)
            genericMessage[format] = ZMGenericMessage.genericMessage(
                mediumImageProperties: storeProcessed ? self.sampleImageProperties(.medium) : nil,
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
            directory.storeAssetData(nonce, format: .original, encrypted: false, data: imageData)
        }
        let assetMessage = ZMAssetClientMessage.insertNewObject(in: self.uiMOC)
        
        assetMessage.add(genericMessage[.preview]!)
        assetMessage.add(genericMessage[.medium]!)
        assetMessage.assetId = nonce
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
        XCTAssertEqual(data?.hashValue, expectedData.hashValue)
    }

    func testThatOriginalImageDataReturnsNilIfThereIsNoFile() {
        // given
        let sut = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertNil(sut.imageAssetStorage!.originalImageData())
    }

    func testThatIsPublicForFormatReturnsNoForAllFormats() {
        // given
        let formats = [ZMImageFormat.medium, ZMImageFormat.invalid, ZMImageFormat.original, ZMImageFormat.preview, ZMImageFormat.profile]
        
        // when
        let sut = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)

        // then
        for format in formats {
            XCTAssertFalse(sut.imageAssetStorage!.isPublic(for: format))
        }
    }

    func testThatEncryptedDataForFormatReturnsValuesFromEncryptedFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: true, storeProcessed: true)
        
        for format in [ZMImageFormat.preview, ZMImageFormat.medium] {
            // when
            let data = message.imageAssetStorage!.imageData(for: format, encrypted: true)
            
            // then
            let dataOnFile = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: format, encrypted: true)
            XCTAssertEqual(dataOnFile, data)
        }
    }
    
    func testThatImageDataForFormatReturnsValuesFromProcessedFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: true, storeProcessed: true)
        
        for format in [ZMImageFormat.preview, ZMImageFormat.medium] {
            // when
            let data = message.imageAssetStorage!.imageData(for: format, encrypted: false)
            
            // then
            let dataOnFile = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format:format, encrypted: false)
            XCTAssertEqual(dataOnFile, data)
        }
    }
    
    func testThatImageDataForFormatReturnsNilWhenThereIsNoFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        for format in [ZMImageFormat.preview, ZMImageFormat.medium] {
            
            // when
            let plainData = message.imageAssetStorage!.imageData(for: format, encrypted: false)
            let encryptedData = message.imageAssetStorage!.imageData(for: format, encrypted: true)
            
            // then
            XCTAssertNil(plainData)
            XCTAssertNil(encryptedData)
            
        }
    }

    func testThatItReturnsTheOriginalImageSize() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        
        for _ in [ZMImageFormat.preview, ZMImageFormat.medium] {
            
            // when
            let originalSize = message.imageAssetStorage!.originalImageSize()
            
            // then
            XCTAssertEqual(originalSize, self.sampleImageProperties(.medium).size)
            
        }
    }
    
    func testThatItReturnsZeroOriginalImageSizeIfItWasNotSet() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        for _ in [ZMImageFormat.preview, ZMImageFormat.medium] {
            
            // when
            let originalSize = message.imageAssetStorage!.originalImageSize()
            
            // then
            XCTAssertEqual(originalSize, CGSize(width: 0, height: 0))
            
        }
    }
    
    func testThatItReturnsTheRightRequiredImageFormats() {
        
        // given
        let expected = NSOrderedSet(array: [ZMImageFormat.medium, ZMImageFormat.preview].map { $0.rawValue})
        
        // when
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertEqual(message.imageAssetStorage!.requiredImageFormats(), expected);

    }
    
    func testThatItReturnsTheRightValueForInlineForFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)

        // then
        XCTAssertFalse(message.imageAssetStorage!.isInline(for:.medium));
        XCTAssertTrue(message.imageAssetStorage!.isInline(for: .preview));
        XCTAssertFalse(message.imageAssetStorage!.isInline(for: .original));
        XCTAssertFalse(message.imageAssetStorage!.isInline(for: .profile));
        XCTAssertFalse(message.imageAssetStorage!.isInline(for:.invalid));
    }

    func testThatItReturnsTheRightValueForUsingNativePushForFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertTrue(message.imageAssetStorage!.isUsingNativePush(for: .medium));
        XCTAssertFalse(message.imageAssetStorage!.isUsingNativePush(for: .preview));
        XCTAssertFalse(message.imageAssetStorage!.isUsingNativePush(for: .original));
        XCTAssertFalse(message.imageAssetStorage!.isUsingNativePush(for: .profile));
        XCTAssertFalse(message.imageAssetStorage!.isUsingNativePush(for: .invalid));
    }
    
    func testThatItClearsOnlyTheOriginalImageFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: true, storeProcessed: true)
        
        // when
        message.imageAssetStorage!.processingDidFinish()
        
        // then
        let directory = self.uiMOC.zm_imageAssetCache!
        XCTAssertNil(directory.assetData(message.nonce, format: .original, encrypted: false))
        XCTAssertNil(message.imageAssetStorage!.originalImageData())
        XCTAssertNotNil(directory.assetData(message.nonce, format: .medium, encrypted: false))
        XCTAssertNotNil(directory.assetData(message.nonce, format: .preview, encrypted: false))
        XCTAssertNotNil(directory.assetData(message.nonce, format: .medium, encrypted: true))
        XCTAssertNotNil(directory.assetData(message.nonce, format: .preview, encrypted: true))
    }

    func testThatItSetsTheCorrectImageDataPropertiesWhenSettingTheData() {
        
        for format in [ZMImageFormat.medium, ZMImageFormat.preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
            let testData = "foobar".data(using: String.Encoding.utf8, allowLossyConversion: false)
            let testProperties = ZMIImageProperties(size: CGSize(width: 33, height: 55), length: UInt(10), mimeType: "image/tiff")
            
            // when
            message.imageAssetStorage!.setImageData(testData, for: format, properties: testProperties)
            
            // then
            XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: format)!.image.width, 33)
            XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: format)!.image.height, 55)
            XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: format)!.image.size, 10)
            XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: format)!.image.mimeType, "image/tiff")
        }
    }
    
    func testThatItStoresTheRightEncryptionKeysNoMatterInWhichOrderTheDataIsSet() {
        
        // given
        let dataPreview = "FOOOOOO".data(using: String.Encoding.utf8)
        let dataMedium = "xxxxxxxxx".data(using: String.Encoding.utf8)
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        message.isEncrypted = true
        let testProperties = ZMIImageProperties(size: CGSize(width: 33, height: 55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.imageAssetStorage!.setImageData(dataPreview, for: .preview, properties: testProperties) // simulate various order of setting
        message.imageAssetStorage!.setImageData(dataMedium, for: .medium, properties: testProperties)
        message.imageAssetStorage!.setImageData(dataPreview, for: .preview, properties: testProperties)
        message.imageAssetStorage!.setImageData(dataMedium, for: .medium, properties: testProperties)

        // then
        let dataOnDiskForPreview = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: .preview, encrypted: true)!
        let dataOnDiskForMedium = self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true)!
        
        XCTAssertEqual(dataOnDiskForPreview.zmSHA256Digest(), message.imageAssetStorage!.previewGenericMessage!.image.sha256)
        XCTAssertEqual(dataOnDiskForMedium.zmSHA256Digest(), message.imageAssetStorage!.mediumGenericMessage!.image.sha256)
    }
    
    func testThatItSetsTheMediumSizeOnThePreviewOriginalSize_SetPreviewFirst() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        let testData = "foobar".data(using: String.Encoding.utf8, allowLossyConversion: false)
        let testMediumProperties = ZMIImageProperties(size: CGSize(width: 111, height: 100), length: UInt(1000), mimeType: "image/tiff")
        let testPreviewProperties = ZMIImageProperties(size: CGSize(width: 80, height: 55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.imageAssetStorage!.setImageData(testData, for:  .preview, properties: testPreviewProperties)
        message.imageAssetStorage!.setImageData(testData, for:  .medium, properties: testMediumProperties)
        
        // then
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.width, 80)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.height, 55)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.size, 10)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.mimeType, "image/tiff")
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.width, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.height, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.size, 1000)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.mimeType, "image/tiff")
    }
    
    func testThatItSetsTheMediumSizeOnThePreviewOriginalSize_SetMediumFirst() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        let testData = "foobar".data(using: String.Encoding.utf8, allowLossyConversion: false)
        let testMediumProperties = ZMIImageProperties(size: CGSize(width: 111, height: 100), length: UInt(1000), mimeType: "image/tiff")
        let testPreviewProperties = ZMIImageProperties(size: CGSize(width: 80, height: 55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.imageAssetStorage!.setImageData(testData, for:  .medium, properties: testMediumProperties)
        message.imageAssetStorage!.setImageData(testData, for:  .preview, properties: testPreviewProperties)
        
        // then
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.width, 80)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.height, 55)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.size, 10)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .preview)!.image.mimeType, "image/tiff")
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.width, 111)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.height, 100)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.size, 1000)
        XCTAssertEqual(message.imageAssetStorage!.genericMessage(for: .medium)!.image.mimeType, "image/tiff")
    }
    
    func testThatItSavesTheImageDataToFileInPlainTextAndEncryptedWhenSettingTheDataOnAnEncryptedMessage() {
        
        for format in [ZMImageFormat.medium, ZMImageFormat.preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
            message.isEncrypted = true
            let testProperties = ZMIImageProperties(size: CGSize(width: 33, height: 55), length: UInt(10), mimeType: "image/tiff")
            let data = sampleProcessedImageData(format)
            
            // when
            message.imageAssetStorage!.setImageData(data, for: format, properties: testProperties)
            
            // then
            XCTAssertEqual(self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: format, encrypted: false), data)
            XCTAssertEqual(message.imageAssetStorage!.imageData(for: format, encrypted: false), data)
            AssertOptionalNotNil(self.uiMOC.zm_imageAssetCache.assetData(message.nonce, format: format, encrypted: true)) {
                let decrypted = $0.zmDecryptPrefixedPlainTextIV(key: message.imageAssetStorage!.genericMessage(for: format)!.image.otrKey)
                let sha = $0.zmSHA256Digest()
                XCTAssertEqual(decrypted, data)
                XCTAssertEqual(sha, message.imageAssetStorage!.genericMessage(for: format)!.image.sha256)
            }
        }
    }

    func testThatItReturnsNilEncryptedDataIfTheImageIsNotEncrypted() {

        for format in [ZMImageFormat.medium, ZMImageFormat.preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
            
            // then
            XCTAssertNil(message.imageAssetStorage!.imageData(for: format, encrypted: true))
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
        let properties = ZMIImageProperties(size: CGSize(width: 300, height: 300), length: 234, mimeType: "image/jpg")
        
        // when
        message.imageAssetStorage!.setImageData(self.verySmallJPEGData(), for: .medium, properties: properties)
        
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
        self.uiMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: .medium, encrypted: false)
        
        // then
        XCTAssertFalse(message.hasDownloadedImage)
    }
    
    func testThatRequestingImageDownloadFiresANotification() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        message.managedObjectContext?.saveOrRollback()
        
        // expect
        let _ = self.expectation(forNotification: ZMAssetClientMessage.ImageDownloadNotificationName, object: message.objectID, handler: nil)
        
        // when
        message.requestImageDownload()

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
}


// MARK: - UpdateEvents
extension ZMAssetClientMessageTests {
    
    func testThatItCreatesOTRAssetMessagesFromMediumUpdateEvent() {
        let previewAssetId = UUID.create()
        let mediumAssetId = UUID.create()
        
        for format in [ZMImageFormat.medium, ZMImageFormat.preview] {

            // given
            let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
            conversation.remoteIdentifier = UUID.create()
            let nonce = UUID.create()
            let imageData = self.verySmallJPEGData()
            let assetId = format == .medium ? mediumAssetId : previewAssetId
            let genericMessage = ZMGenericMessage.genericMessage(imageData: imageData, format: format, nonce: nonce.transportString())
            let dataPayload = [
                "info" : genericMessage.data().base64String(),
                "id" : assetId.transportString()
            ]
            
            let payload = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload)!
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)
            
            // when
            var sut : ZMAssetClientMessage? = nil
            self.performPretendingUiMocIsSyncMoc { () -> Void in
                sut = ZMAssetClientMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil).message as? ZMAssetClientMessage
            }
            
            // then
            XCTAssertNotNil(sut)
            XCTAssertEqual(sut!.conversation, conversation)
            XCTAssertEqual(sut!.sender?.remoteIdentifier!.transportString(), payload["from"] as? String)
            XCTAssertEqual(sut!.serverTimestamp?.transportString(), payload["time"] as? String)
            
            XCTAssertTrue(sut!.isEncrypted)
            XCTAssertFalse(sut!.isPlainText)
            XCTAssertEqual(sut!.nonce, nonce)
            XCTAssertEqual(sut!.imageAssetStorage!.genericMessage(for: format)?.data(), genericMessage.data())
            XCTAssertEqual(sut!.assetId, format == .medium ? mediumAssetId : nil)
        }
    }

    func testThatItCreatesOTRAssetMessagesFromFileThumbnailUpdateEvent() {

        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let nonce = UUID.create()
        let thumbnailId = UUID.create()
        let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
        let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
        let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: 256, mimeType: "video/mp4", remoteData: remoteData, imageMetaData: imageMetaData))
        
        let genericMessage = ZMGenericMessage.genericMessage(asset: asset, messageID: nonce.transportString())
        
        let dataPayload = [
            "info" : genericMessage.data().base64String(),
            "id" : thumbnailId.transportString()
        ] as [String : Any]
        
        let payload = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload)!
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)
        
        // when
        var sut: ZMAssetClientMessage!
        performPretendingUiMocIsSyncMoc {
            sut = ZMAssetClientMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil).message as! ZMAssetClientMessage
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
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
            let conversation = ZMConversation.insertNewObject(in:self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            let nonce = UUID.create()
            let thumbnailId = UUID.create()
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
            let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: 256, mimeType: "video/mp4", remoteData: remoteData, imageMetaData: imageMetaData))
            let firstDate = Date(timeIntervalSince1970: 12334)
            let secondDate = firstDate.addingTimeInterval(234444)
            
            let genericMessage = ZMGenericMessage.genericMessage(asset: asset, messageID: nonce.transportString())
            
            let dataPayload = [
                "info" : genericMessage.data().base64String(),
                "id" : thumbnailId.transportString()
            ]
            
            let payload1 = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload, time: firstDate)!
            let updateEvent1 = ZMUpdateEvent(fromEventStreamPayload: payload1, uuid: nil)
            let payload2 = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload, time: secondDate)!
            let updateEvent2 = ZMUpdateEvent(fromEventStreamPayload: payload2, uuid: nil)
            
            
            // when
            let sut = ZMAssetClientMessage.messageUpdateResult(from: updateEvent1, in: self.syncMOC, prefetchResult: nil).message as! ZMAssetClientMessage
            sut.update(with: updateEvent2, for: conversation, isUpdatingExistingMessage: true)
            
            // then
            XCTAssertEqual(sut.serverTimestamp, firstDate)

        }
    }
    
    func testThatItUpdatesTheTimestampIfEarlier() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in:self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            let nonce = UUID.create()
            let thumbnailId = UUID.create()
            let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
            let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: 256, mimeType: "video/mp4", remoteData: remoteData, imageMetaData: imageMetaData))
            let firstDate = Date(timeIntervalSince1970: 12334)
            let secondDate = firstDate.addingTimeInterval(234444)
            
            let genericMessage = ZMGenericMessage.genericMessage(asset: asset, messageID: nonce.transportString())
            
            let dataPayload = [
                "info" : genericMessage.data().base64String(),
                "id" : thumbnailId.transportString()
            ]
            
            let payload1 = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload, time: secondDate)
            let updateEvent1 = ZMUpdateEvent(fromEventStreamPayload: payload1!, uuid: nil)
            let payload2 = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload, time: firstDate)
            let updateEvent2 = ZMUpdateEvent(fromEventStreamPayload: payload2!, uuid: nil)
            
            
            // when
            let sut = ZMAssetClientMessage.messageUpdateResult(from: updateEvent1, in: self.syncMOC, prefetchResult: nil).message as! ZMAssetClientMessage
            sut.update(with: updateEvent2, for: conversation, isUpdatingExistingMessage: true)
            
            // then
            XCTAssertEqual(sut.serverTimestamp, firstDate)
        }
    }
}

// MARK: - GIF Data

extension ZMAssetClientMessageTests {
    
    func testThatIsNotAnAnimatedGifWhenItHasNoMediumData() {
        
        // given
        let data = sampleProcessedImageData(.preview)
        let message = ZMAssetClientMessage(originalImageData: data, nonce: .create(), managedObjectContext: uiMOC, expiresAfter: 0)
        message.isEncrypted = true
        let testProperties = ZMIImageProperties(size: CGSize(width: 33, height: 55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.imageAssetStorage!.setImageData(data, for: .preview, properties: testProperties)
        
        // then
        XCTAssertFalse(message.imageMessageData!.isAnimatedGIF);
    }
}

// MARK: - Message Deletion

extension ZMAssetClientMessageTests {
    
    func testThatAnAssetClientMessageWithFileDataCanBeDeleted_Sent() {
        checkThatFileMessageCanBeDeleted(true, .sent)
    }
    
    func testThatAnAssetClientMessageWithFileDataCanBeDeleted_Delivered() {
        checkThatFileMessageCanBeDeleted(true, .delivered)
    }
    
    func testThatAnAssetClientMessageWithFileDataCanBeDeleted_Expired() {
        checkThatFileMessageCanBeDeleted(true, .failedToSend)
    }
    
    func testThatAnAssetClientMessageWithFileDataCan_Not_BeDeleted_Pending() {
        checkThatFileMessageCanBeDeleted(false, .pending)
    }
    
    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Sent() {
        checkThatImageAssetMessageCanBeDeleted(true, .sent)
    }
    
    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Delivered() {
        checkThatImageAssetMessageCanBeDeleted(true, .delivered)
    }
    
    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Expired() {
        checkThatImageAssetMessageCanBeDeleted(true, .failedToSend)
    }
    
    func testThatAnAssetClientMessageWithImageDataCan_Not_BeDeleted_Pending() {
        checkThatImageAssetMessageCanBeDeleted(false, .pending)
    }
}

extension ZMAssetClientMessageTests {

    // MARK: Helper
    func checkThatFileMessageCanBeDeleted(_ canBeDeleted: Bool, _ state: ZMDeliveryState, line: UInt = #line) {
        syncMOC.performAndWait {
            // given
            let fileMetadata = self.addFile()
            
            let sut = ZMAssetClientMessage(
                fileMetadata: fileMetadata,
                nonce: UUID.create(),
                managedObjectContext: self.syncMOC,
                expiresAfter: 0
            )
            sut.isEncrypted = true
            sut.visibleInConversation = ZMConversation.insertNewObject(in:self.syncMOC)
            sut.conversation?.remoteIdentifier = UUID()
            sut.sender = ZMUser.selfUser(in: self.syncMOC)
            sut.sender?.remoteIdentifier = UUID()
            
            XCTAssertNotNil(sut.fileMessageData, line: line)
            XCTAssertTrue(sut.isEncrypted, line: line)
            XCTAssertTrue(self.syncMOC.saveOrRollback(), line: line)
            
            // when
            self.updateMessageState(sut, state: state)
            XCTAssertEqual(sut.deliveryState.rawValue, state.rawValue, line: line)
            
            // then
            XCTAssertEqual(sut.canBeDeleted, canBeDeleted, line: line)
        }
    }
    
    func checkThatImageAssetMessageCanBeDeleted(_ canBeDeleted: Bool, _ state: ZMDeliveryState, line: UInt = #line) {
        // given
        let sut = createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        
        sut.isEncrypted = true
        sut.visibleInConversation = ZMConversation.insertNewObject(in:uiMOC)
        sut.conversation?.remoteIdentifier = UUID()
        sut.sender = ZMUser.selfUser(in: uiMOC)
        sut.sender?.remoteIdentifier = UUID()
        
        XCTAssertNil(sut.fileMessageData, line: line)
        XCTAssertTrue(sut.isEncrypted, line: line)
        XCTAssertNotNil(sut.imageAssetStorage, line: line)
        XCTAssertNotNil(sut.imageMessageData, line: line)
        XCTAssertTrue(uiMOC.saveOrRollback(), line: line)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), line: line)
        
        // when
        updateMessageState(sut, state: state)
        XCTAssertEqual(sut.deliveryState, state, line: line)
        
        // then
        XCTAssertEqual(sut.canBeDeleted, canBeDeleted, line: line)
    }
    
    func updateMessageState(_ message: ZMOTRMessage, state: ZMDeliveryState) {
        if state == .sent || state == .delivered {
            message.delivered = true
        } else if state == .failedToSend {
            message.expire()
        }
        if state == .delivered {
            let genericMessage = ZMGenericMessage(confirmation: message.nonce.transportString(), type: .DELIVERED, nonce: UUID.create().transportString())
            _ = ZMMessageConfirmation.createOrUpdateMessageConfirmation(genericMessage, conversation: message.conversation!, sender: message.sender!)
            message.managedObjectContext?.saveOrRollback()
        }
    }
    
}
