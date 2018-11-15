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
@testable import WireDataModel

enum MimeType : String {
    case text = "text/plain"
}

class BaseZMAssetClientMessageTests : BaseZMClientMessageTests {
    
    var message: ZMAssetClientMessage!
    var currentTestURL : URL?
        
    override func tearDown() {
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 2))
        if let url = currentTestURL {
            removeTestFile(url)
        }
        currentTestURL = nil
        message = nil
        super.tearDown()
    }
    
    func appendFileMessage(to conversation: ZMConversation, fileMetaData: ZMFileMetadata? = nil) -> ZMAssetClientMessage? {
        let nonce = UUID.create()
        let data = fileMetaData ?? addFile()
        
        return conversation.append(file: data, nonce: nonce) as? ZMAssetClientMessage
    }
    
    func appendImageMessage(toConversation conversation: ZMConversation) {
        let imageData = verySmallJPEGData()
        let messageNonce = UUID.create()
        
        message = conversation.append(imageFromData: imageData, nonce: messageNonce) as? ZMAssetClientMessage
        
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.count), mimeType:"image/jpeg")!
        
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(), macKey: Data.zmRandomSHA256Key(), mac: Data.zmRandomSHA256Key())
        
        let mediumMessage = ZMImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: .medium)
        let previewMessage = ZMImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: .preview)
        
        message.add(ZMGenericMessage.message(content: mediumMessage, nonce: messageNonce))
        message.add(ZMGenericMessage.message(content: previewMessage, nonce: messageNonce))
    }
    
    func appendImageMessage(to conversation: ZMConversation, imageData: Data? = nil) -> ZMAssetClientMessage {
        let data = imageData ?? verySmallJPEGData()
        let nonce = UUID.create()
        let message = conversation.append(imageFromData: data, nonce: nonce) as! ZMAssetClientMessage

        let uploaded = ZMAsset.asset(withUploadedOTRKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key())
        message.add(ZMGenericMessage.message(content: uploaded, nonce: nonce))
        
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
        let message = ZMAssetClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        message.sender = selfUser
        message.visibleInConversation = conversation
        
        let imageData = self.verySmallJPEGData()
        XCTAssertNotNil(message.imageAssetStorage.updateMessage(imageData: imageData, for: ZMImageFormat.preview))
        
        let storedData = self.uiMOC.zm_fileAssetCache.assetData(message, format: ZMImageFormat.preview, encrypted: false)
        AssertOptionalNotNil(storedData) { storedData in
            XCTAssertEqual(storedData, imageData)
        }
    }
    
    func testThatItStoresPlainImageMessageDataForMedium() {
        let message = ZMAssetClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        message.sender = selfUser
        message.visibleInConversation = conversation
        
        let imageData = self.verySmallJPEGData()
        XCTAssertNotNil(message.imageAssetStorage.updateMessage(imageData: imageData, for: ZMImageFormat.medium))
        
        let storedData = self.uiMOC.zm_fileAssetCache.assetData(message, format: ZMImageFormat.medium, encrypted: false)
        AssertOptionalNotNil(storedData) { storedData in
            XCTAssertEqual(storedData, imageData)
        }
    }
    
    func testThatItDecryptsEncryptedImageMessageData() {
        //given
        let message = ZMAssetClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        message.sender = selfUser
        message.visibleInConversation = conversation
        let imageData = self.verySmallJPEGData()
        
        self.uiMOC.zm_fileAssetCache.storeAssetData(message, format: ZMImageFormat.medium, encrypted: false, data: imageData)
        
        let keys = self.uiMOC.zm_fileAssetCache.encryptImageAndComputeSHA256Digest(message, format: ZMImageFormat.medium)!
        let encryptedImageData = self.uiMOC.zm_fileAssetCache.assetData(message, format: ZMImageFormat.medium, encrypted: true)!
        self.uiMOC.zm_fileAssetCache.deleteAssetData(message, format: ZMImageFormat.medium, encrypted: false)
        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData), length: UInt(imageData.count), mimeType: "image/jpeg")!
        let mediumAsset = ZMImageAsset(mediumProperties: imageProperties, processedProperties: imageProperties, encryptionKeys: keys, format: .medium)
        message.add(ZMGenericMessage.message(content: mediumAsset, nonce: message.nonce!))
        
        // when
        XCTAssertNotNil(message.imageAssetStorage.updateMessage(imageData: encryptedImageData, for: ZMImageFormat.medium))
        
        let decryptedImageData = self.uiMOC.zm_fileAssetCache.assetData(message, format: ZMImageFormat.medium, encrypted: false)
        AssertOptionalNotNil(decryptedImageData) { decryptedImageData in
            XCTAssertEqual(decryptedImageData, imageData)
        }
    }
    
    func testThatItDeletesMessageIfImageMessageDataCanNotBeDecrypted() {
        //given
        let message = ZMAssetClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        message.sender = selfUser
        message.visibleInConversation = conversation
        let imageData = self.verySmallJPEGData()
        
        //store original image
        self.uiMOC.zm_fileAssetCache.storeAssetData(message, format: ZMImageFormat.medium, encrypted: false, data: imageData)
        
        //encrypt image
        let keys = self.uiMOC.zm_fileAssetCache.encryptImageAndComputeSHA256Digest(message, format: ZMImageFormat.medium)!
        self.uiMOC.zm_fileAssetCache.deleteAssetData(message, format: ZMImageFormat.medium, encrypted: true)
        self.uiMOC.zm_fileAssetCache.deleteAssetData(message, format: ZMImageFormat.medium, encrypted: false)

        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData), length: UInt(imageData.count), mimeType: "image/jpeg")!
        let mediumAsset = ZMImageAsset(mediumProperties: imageProperties, processedProperties: imageProperties, encryptionKeys: keys, format: .medium)
        message.add(ZMGenericMessage.message(content: mediumAsset, nonce: message.nonce!))
        
        // when
        //pass in some wrong data (i.e. plain data instead of encrypted)
        XCTAssertNil(message.imageAssetStorage.updateMessage(imageData: imageData, for: ZMImageFormat.medium))
        
        let decryptedImageData = self.uiMOC.zm_fileAssetCache.assetData(message, format: ZMImageFormat.medium, encrypted: false)
        XCTAssertNil(decryptedImageData)
        XCTAssertTrue(message.isDeleted);
    }
    
    func testThatItDeletesCopiesOfDownloadedFilesIntoTemporaryFolder() {
        // given
        let sut = appendFileMessage(to: conversation)!
        self.uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .medium, encrypted: false, data: Data.secureRandomData(ofLength: 100))
        guard let tempFolder = sut.temporaryDirectoryURL else { XCTFail(); return }
        
        XCTAssertNotNil(sut.fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFolder.path))
        
        //when
        sut.deleteContent()
        
        //then
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempFolder.path))
    }
    
    func testThatItMarksMediumNeededToBeDownloadedIfNoEncryptedNoDecryptedDataStored() {
        
        let message = ZMAssetClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        message.sender = selfUser
        message.visibleInConversation = conversation
        let imageData = self.verySmallJPEGData()
        
        self.uiMOC.zm_fileAssetCache.storeAssetData(message, format: ZMImageFormat.medium, encrypted: false, data: imageData)
        
        let keys = self.uiMOC.zm_fileAssetCache.encryptImageAndComputeSHA256Digest(message, format: ZMImageFormat.medium)!
        let encryptedImageData = self.uiMOC.zm_fileAssetCache.assetData(message, format: ZMImageFormat.medium, encrypted: true)!
        self.uiMOC.zm_fileAssetCache.deleteAssetData(message, format: ZMImageFormat.medium, encrypted: false)
        
        let imageProperties = ZMIImageProperties(size: ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData), length: UInt(imageData.count), mimeType: "image/jpeg")!
        let mediumAsset = ZMImageAsset(mediumProperties: imageProperties, processedProperties: imageProperties, encryptionKeys: keys, format: .medium)
        message.add(ZMGenericMessage.message(content: mediumAsset, nonce: message.nonce!))
        
        // when
        XCTAssertNotNil(message.imageAssetStorage.updateMessage(imageData: encryptedImageData, for: ZMImageFormat.medium))
        XCTAssertTrue(message.hasDownloadedImage)
        
        // pretend that there are no encrypted no decrypted message data stored
        // i.e. cache folder is cleared but message is already processed
        self.uiMOC.zm_fileAssetCache.deleteAssetData(message, format: ZMImageFormat.medium, encrypted: false)
        
        XCTAssertNil(message.imageMessageData?.imageData)
        XCTAssertFalse(message.hasDownloadedImage)
        XCTAssertEqual(message.version, 0)
    }
    
}

// MARK: - ZMAsset / ZMFileMessageData

extension ZMAssetClientMessageTests {
    
    func testThatItCreatesFileAssetMessageInTheRightStateToBeUploaded()
    {
        // given
        let sut = appendFileMessage(to: conversation)!
        
        // then
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.delivered)
        XCTAssertEqual(sut.transferState, ZMFileTransferState.uploading)
        XCTAssertEqual(sut.filename, currentTestURL!.lastPathComponent)
        XCTAssertNotNil(sut.fileMessageData)
        XCTAssertEqual(sut.version, 3)
    }
    
    func testThatFileAssetMessageCanBeExpired()
    {
        // given
        let sut = appendFileMessage(to: conversation)!
        
        // when
        sut.expire()
        
        // then
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.delivered)
        XCTAssertEqual(sut.transferState.rawValue, ZMFileTransferState.failedUpload.rawValue)
        XCTAssertEqual(sut.uploadState, AssetUploadState.done)
        XCTAssertTrue(sut.isExpired)
    }

    func testThatFileAssetMessageCanBeExpired_UploadingFullAsset() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.uploadState = .uploadingFullAsset

        // when
        sut.expire()

        // then
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.delivered)
        XCTAssertEqual(sut.transferState.rawValue, ZMFileTransferState.failedUpload.rawValue)
        XCTAssertEqual(sut.uploadState.rawValue, AssetUploadState.uploadingFailed.rawValue)
        XCTAssertTrue(sut.isExpired)
    }

    func testThatFileAssetMessageCanBeExpired_UploadingThumbnail() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.uploadState = .uploadingThumbnail

        // when
        sut.expire()

        // then
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.delivered)
        XCTAssertEqual(sut.transferState.rawValue, ZMFileTransferState.failedUpload.rawValue)
        XCTAssertEqual(sut.uploadState.rawValue, AssetUploadState.uploadingFailed.rawValue)
        XCTAssertTrue(sut.isExpired)
    }
    
    func testThatImageMessageCanBeExpired() {
        self.syncMOC.performGroupedBlockAndWait {
            
            //given
            let sut = self.appendImageMessage(to: self.syncConversation)
                
            //when
            sut.expire()
                
            //then
            XCTAssertNotNil(sut)
            XCTAssertFalse(sut.delivered)
            XCTAssertEqual(sut.transferState.rawValue, ZMFileTransferState.failedUpload.rawValue)
            XCTAssertEqual(sut.uploadState, .uploadingFailed)
            XCTAssertTrue(sut.isExpired)
        }
    }
    
    func testThatItHasDownloadedFileWhenTheFileIsOnDisk()
    {
        // given
        let sut = appendFileMessage(to: conversation)!
        
        // then
        XCTAssertTrue(sut.hasDownloadedFile)
        XCTAssertFalse(sut.hasDownloadedImage)
    }
    
    func testThatItHasNoDownloadedFileWhenTheFileIsNotOnDisk()
    {
        // given
        let sut = appendFileMessage(to: conversation)!
        self.uiMOC.zm_fileAssetCache.deleteAssetData(sut, encrypted: false)
        
        // then
        XCTAssertFalse(sut.hasDownloadedFile)
        XCTAssertFalse(sut.hasDownloadedImage)
    }
    
    func testThatItHasDownloadedImageWhenTheProcessedThumbnailIsOnDisk()
    {
        // given
        let sut = appendFileMessage(to: conversation)!
        
        self.uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .medium, encrypted: false, data: Data.secureRandomData(ofLength: 100))
        defer { self.uiMOC.zm_fileAssetCache.deleteAssetData(sut, format: .medium, encrypted: false) }
        
        // then
        XCTAssertTrue(sut.hasDownloadedImage)
    }
    
    func testThatItHasDownloadedImageWhenTheOriginalThumbnailIsOnDisk()
    {
        // given
        let sut = appendFileMessage(to: conversation)!
        
        self.uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .original, encrypted: false, data: Data.secureRandomData(ofLength: 100))
        defer { self.uiMOC.zm_fileAssetCache.deleteAssetData(sut, format: .medium, encrypted: false) }
        
        // then
        XCTAssertTrue(sut.hasDownloadedImage)
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
        let sut = appendFileMessage(to: conversation, fileMetaData: fileMetadata)!
        
        XCTAssertNotNil(sut)
        
        // then
        let assetMessage = sut.genericAssetMessage
        XCTAssertNotNil(assetMessage)
        XCTAssertEqual(assetMessage?.messageId, sut.nonce?.transportString())
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
        let sut = appendFileMessage(to: conversation, fileMetaData: fileMetadata)!

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
        let previewMessage = ZMGenericMessage.message(content: previewAsset, nonce: nonce)

        
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
        let sut = ZMAssetClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        sut.sender = selfUser
        let mimeType = "text/plain"
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withOriginal: .original(withSize: 256, mimeType: mimeType, name: name), preview: nil), nonce: nonce)
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
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
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key()), nonce: nonce)
        let uploadedMessage = originalMessage.updatedUploaded(withAssetId: "id", token: "token")
        sut.update(with: uploadedMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.uploaded)
    }
    
    func testThatItDoesntUpdateTheTransferStateWhenTheUploadedMessageIsMergedButDoesntContainAssetId()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key()), nonce: nonce)
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.uploading)
    }
    
    func testThatItDeletesTheMessageWhenTheNotUploadedCanceledMessageIsMerged()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withNotUploaded: .CANCELLED), nonce: nonce)
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
        // then
        XCTAssertTrue(sut.isZombieObject)
    }
    
    /// This is testing a race condition on the receiver side if the sender cancels but not fast enough, and he BE just got the entire payload
    func testThatItUpdatesTheTransferStateWhenTheCanceledMessageIsMergedAfterUploadingSuccessfully()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key()), nonce: nonce)
        let uploadedMessage = originalMessage.updatedUploaded(withAssetId: "id", token: "token")
        sut.update(with: uploadedMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        let canceledMessage = ZMGenericMessage.message(content: ZMAsset.asset(withNotUploaded: .CANCELLED), nonce: nonce)
        sut.update(with: canceledMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, ZMFileTransferState.uploaded)
    }
    
    func testThatItUpdatesTheTransferStateWhenTheNotUploadedFailedMessageIsMerged()
    {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withNotUploaded: .FAILED), nonce: nonce)
        sut.update(with: originalMessage, updateEvent: ZMUpdateEvent(), initialUpdate: true)
        
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
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        
        let dataPayload = [
            "id": assetId.transportString()
        ]
        
        let payload = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload)
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload!, uuid: UUID.create())
        // when
        let originalMessage = ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key()), nonce: nonce)
        sut.update(with: originalMessage, updateEvent: updateEvent, initialUpdate: true)
        
        // then
        XCTAssertEqual(sut.assetId, assetId)
    }
    
    
    func testThatItReturnsAValidFileMessageData() {
        self.syncMOC.performAndWait {
            // given
            let sut = appendFileMessage(to: syncConversation)!
            
            // then
            XCTAssertNotNil(sut)
            XCTAssertNotNil(sut.fileMessageData)
        }
    }
    
    func testThatItReturnsTheEncryptedUploadedDataWhenItHasAUploadedGenericMessageInTheDataSet() {
        self.syncMOC.performAndWait { 
            // given
            let sut = appendFileMessage(to: syncConversation)!
            
            // when
            let otrKey = Data.randomEncryptionKey()
            let sha256 = Data.zmRandomSHA256Key()
            sut.add(ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: otrKey, sha256: sha256), nonce: sut.nonce!))
            
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
            let selfClient = UserClient.insertNewObject(in: self.syncMOC)
            selfClient.remoteIdentifier = self.name
            selfClient.user = .selfUser(in: self.syncMOC)
            self.syncMOC.setPersistentStoreMetadata(selfClient.remoteIdentifier, key: "PersistedClientId")
            XCTAssertNotNil(ZMUser.selfUser(in: self.syncMOC).selfClient())
            
            let user2 = ZMUser.insertNewObject(in:self.syncMOC)
            user2.remoteIdentifier = UUID.create()
            let user2Client = UserClient.insertNewObject(in: self.syncMOC)
            user2Client.remoteIdentifier = UUID.create().transportString()
            
            let conversation = ZMConversation.insertNewObject(in:self.syncMOC)
            conversation.conversationType = .group
            conversation.internalAddParticipants(Set([user2]))
            
            let sut = appendFileMessage(to: syncConversation)!
            
            // when
            sut.add(ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key()), nonce: sut.nonce!))
            
            // then
            XCTAssertNotNil(sut)
            let encryptedUpstreamMetaData = sut.encryptedMessagePayloadForDataType(.fullAsset)
            XCTAssertNotNil(encryptedUpstreamMetaData)
            self.syncMOC.setPersistentStoreMetadata(nil as String?, key: "PersistedClientId")
        }
    }

    
    func testThatItSetsTheCorrectStateWhen_RequestFileDownload_IsBeingCalled() {
        // given
        let sut = ZMAssetClientMessage(nonce: .create(), managedObjectContext: uiMOC)
        sut.sender = selfUser
        let original = ZMGenericMessage.message(content: ZMAsset.asset(originalWithImageSize: CGSize(width: 10, height: 10), mimeType: "text/plain", size: 256), nonce: sut.nonce!)
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
            let sut = appendFileMessage(to: syncConversation)!
            
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
            let sut = appendFileMessage(to: syncConversation)!
            
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
            let sut = appendFileMessage(to: syncConversation)!
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
            let sut = appendFileMessage(to: syncConversation)!
            sut.transferState = .uploading
            sut.delivered = false
            
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when
            sut.fileMessageData?.cancelTransfer()
            
            // then
            let messages = sut.dataSet.compactMap { ($0 as AnyObject).genericMessage! }
            let assets = messages.filter { $0.hasAsset() }.compactMap { $0.asset }
            XCTAssertEqual(assets.count, 2)
            let notUploaded = assets.filter { $0.hasNotUploaded() }.compactMap { $0.notUploaded }
            XCTAssertEqual(notUploaded.count, 1)
            XCTAssertEqual(notUploaded.first, ZMAssetNotUploaded.CANCELLED)
            
            XCTAssertEqual(sut.transferState, ZMFileTransferState.cancelledUpload)
            XCTAssertEqual(sut.progress, 0.0)
        }
    }
    
    func testThatItItReturnsTheGenericMessageDataAndInculdesTheNotUploadedWhenItIsPresent_Placeholder() {
        self.syncMOC.performAndWait {
            
            // given
            let sut = appendFileMessage(to: syncConversation)!
            sut.delivered = true
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // when we cancel the transfer
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.cancelledUpload)
            
            // then the generic message data should include the not uploaded
            let assetMessage = sut.genericAssetMessage!
            let genericMessage = sut.genericMessage(dataType: .placeholder)!
            
            XCTAssertTrue(assetMessage.asset.hasNotUploaded())
            XCTAssertEqual(assetMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
            XCTAssertTrue(genericMessage.asset.hasNotUploaded())
            XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        }
    }
        
    func testThatItPostsANotificationWhenTheDownloadOfTheMessageIsCancelled() {
        self.syncMOC.performAndWait {
            
            // given
            let sut = ZMAssetClientMessage(nonce: .create(), managedObjectContext: syncMOC)
            sut.sender = ZMUser.selfUser(in: syncMOC)
            sut.visibleInConversation = syncConversation
            let original = ZMGenericMessage.message(content: ZMAsset.asset(originalWithImageSize: CGSize(width: 10, height: 10), mimeType: "text/plain", size: 256), nonce: sut.nonce!)
            sut.add(original)
            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())

            let expectation = self.expectation(description: "Notification fired")
            let token = NotificationInContext.addObserver(
                name: ZMAssetClientMessage.didCancelFileDownloadNotificationName,
                context: self.uiMOC.notificationContext,
                object: sut.objectID) { note in
                    expectation.fulfill()
            }
            
            sut.requestFileDownload()
            XCTAssertEqual(sut.transferState, ZMFileTransferState.downloading)
            
            // when
            sut.fileMessageData?.cancelTransfer()
            
            // then
            withExtendedLifetime(token) { () -> () in
                XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
                XCTAssertEqual(sut.transferState, ZMFileTransferState.uploaded)
            }
        }
    }
    
    func testThatItPreparesMessageForResend() {
        self.syncMOC.performAndWait {
            
            // given
            let sut = appendFileMessage(to: syncConversation)!
            sut.delivered = true
            sut.progress = 56
            sut.transferState = .failedUpload
            sut.uploadState = .uploadingFailed
            
            // when
            sut.resend()
            
            // then
            XCTAssertEqual(sut.uploadState, AssetUploadState.uploadingPlaceholder)
            XCTAssertFalse(sut.delivered)
            XCTAssertEqual(sut.transferState, ZMFileTransferState.uploading)
            XCTAssertEqual(sut.progress, 0)
        }
    }
    
    func testThatItPreparesImageMessageForResend() {
        self.syncMOC.performAndWait {
            
            // given
            let image = self.verySmallJPEGData()
            let nonce = UUID.create()
            syncConversation.messageDestructionTimeout = .local(.fiveMinutes)
            let sut = syncConversation.append(imageFromData: image, nonce: nonce) as! ZMAssetClientMessage
            sut.delivered = true
            sut.progress = 56
            sut.transferState = .failedUpload
            sut.uploadState = .uploadingFailed
            
            // when
            sut.resend()
            
            // then
            XCTAssertEqual(sut.uploadState, AssetUploadState.uploadingFullAsset)
            XCTAssertFalse(sut.delivered)
            XCTAssertEqual(sut.transferState, ZMFileTransferState.uploading)
            XCTAssertEqual(sut.progress, 0)
        }
    }
    
    func testThatItReturnsNilAssetIdOnANewlyCreatedMessage() {
        self.syncMOC.performAndWait {
            
            // given
            let sut = appendFileMessage(to: syncConversation)!
            
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
            
            let uuid = "asset-id"
            let sut = appendFileMessage(to: syncConversation)!
            
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            sut.add(ZMGenericMessage.message(content: asset, nonce: sut.nonce!))
            
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
            
            let uuid = "uuid"
            let sut = appendFileMessage(to: syncConversation)!
            
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            let genericMessage = ZMGenericMessage.message(content: asset, nonce: sut.nonce!)
            let payload : [String : AnyObject] = [
                "type" : "conversation.otr-asset-add" as AnyObject,
                "data" : [
                    "id" : uuid
                ] as AnyObject
            ]
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID.create())
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            
            // when
            sut.update(with: genericMessage, updateEvent: updateEvent, initialUpdate: true)
            
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
            let sut = appendFileMessage(to: syncConversation)!
            
            let assetWithUploaded = ZMAsset.asset(withUploadedOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
            let assetWithPreview = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            let builder = ZMAssetBuilder()
            builder.merge(from: assetWithUploaded)
            builder.mergePreview(assetWithPreview.preview)
            let asset = builder.build()!
            
            let genericMessage = ZMGenericMessage.message(content: asset, nonce: sut.nonce!)
            let payload : [String : AnyObject] = [
                "type" : "conversation.otr-asset-add" as AnyObject,
                "data" : [
                    "id" : UUID.create().uuidString
                ] as AnyObject
            ]
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID.create())
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            
            
            // when
            sut.update(with: genericMessage, updateEvent: updateEvent, initialUpdate: true)
            
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
        
        let uuid = UUID.create()
        let sut = appendFileMessage(to: conversation)!
        
        XCTAssertFalse(sut.genericAssetMessage!.asset.hasPreview())
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // when
        uiMOC.refresh(sut, mergeChanges: false) // Turn object into fault
        
        self.syncMOC.performAndWait {
            let sutInSyncContext = self.syncMOC.object(with: sut.objectID) as! ZMAssetClientMessage
            let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: previewSize, mimeType: previewMimeType, remoteData: remoteData, imageMetaData: imageMetaData))
            let genericMessage = ZMGenericMessage.message(content: asset, nonce: sut.nonce!)
            let payload : [String : AnyObject] = [
                "type" : "conversation.otr-asset-add" as AnyObject,
                "data" : [
                    "id" : uuid
                ] as AnyObject
            ]
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID.create())
            XCTAssertNil(sutInSyncContext.fileMessageData?.thumbnailAssetID)
            
            sutInSyncContext.update(with: genericMessage, updateEvent: updateEvent, initialUpdate: true) // Append preview
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
            self.currentTestURL = self.testURLWithFilename("file.dat")
            _ = self.createTestFile(self.currentTestURL!)
            
            let fileMetadata = ZMFileMetadata(fileURL: self.currentTestURL!, thumbnail: thumbnail)
            
            // when
            let sut = appendFileMessage(to: syncConversation, fileMetaData: fileMetadata)!
            
            // then
            let storedThumbail = syncMOC.zm_fileAssetCache.assetData(sut, format: .original, encrypted: false)
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
            let sut = appendFileMessage(to: syncConversation, fileMetaData: fileMetadata)!
            
            // then
            let storedThumbail = sut.managedObjectContext?.zm_fileAssetCache.assetData(sut, format: .original, encrypted: false)
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
        conversation.internalAddParticipants(Set(arrayLiteral: otherUser))
        XCTAssertTrue(self.syncMOC.saveOrRollback())
        
        return (otherClient, conversation)
    }
}

// MARK: - Associated Task Identifier
extension ZMAssetClientMessageTests {
    
    func testThatItStoresTheAssociatedTaskIdentifier() {
        // given
        let sut = ZMAssetClientMessage(nonce: .create(), managedObjectContext: uiMOC)
        
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
    
    func testThatItSavesTheOriginalFileWhenCreatingMessage()
    {
        // given
        let sut = appendImageMessage(to: conversation)
        
        // then
        XCTAssertNotNil(uiMOC.zm_fileAssetCache.assetData(sut, format: .original, encrypted: false))
    }

    func testThatItSetsTheOriginalImageSize()
    {
        // given
        let image = self.verySmallJPEGData()
        let expectedSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: image)
        
        // when
        let sut = appendImageMessage(to: conversation, imageData: image)
        let imageMessageStorage = sut.imageAssetStorage
        
        // then
        XCTAssertEqual(expectedSize, imageMessageStorage.originalImageSize())
    }
}


// MARK: - Post event
extension ZMAssetClientMessageTests {
    
    func testThatItDoesSetConversationLastServerTimestampWhenPostingFullAssetAndMessageIsImage() {
        // given
        syncMOC.performGroupedBlockAndWait {
            let message = self.appendImageMessage(to: self.syncConversation)
            let emptyDict = [String: String]()
            let payload: [AnyHashable: Any] = ["deleted": emptyDict, "missing": emptyDict, "redundant": emptyDict, "time": Date().transportString()]
            message.uploadState = .uploadingFullAsset

            // when
            message.update(withPostPayload: payload, updatedKeys: Set([#keyPath(ZMAssetClientMessage.uploadState)]))

            // then
            XCTAssertEqual(message.serverTimestamp, message.conversation?.lastServerTimeStamp)
        }
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
        let directory = self.uiMOC.zm_fileAssetCache
        let nonce = UUID.create()
        let imageData = imageData ?? sampleImageData()
        var genericMessage : [ZMImageFormat : ZMGenericMessage] = [:]
        let assetMessage = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        assetMessage.sender = selfUser
        assetMessage.visibleInConversation = conversation
        
        for format in [ZMImageFormat.medium, ZMImageFormat.preview] {
            let processedData = sampleProcessedImageData(format)
            let otrKey = Data.randomEncryptionKey()
            let encryptedData = processedData.zmEncryptPrefixingPlainTextIV(key: otrKey)
            let sha256 = encryptedData.zmSHA256Digest()
            let encryptionKeys = ZMImageAssetEncryptionKeys(otrKey: otrKey, sha256: sha256)
            let imageAsset = ZMImageAsset(mediumProperties: storeProcessed ? self.sampleImageProperties(.medium) : nil,
                                          processedProperties: storeProcessed ? self.sampleImageProperties(format) : nil,
                                          encryptionKeys: storeEncrypted ? encryptionKeys : nil,
                                          format: format)
            
            genericMessage[format] = ZMGenericMessage.message(content: imageAsset, nonce: nonce)
            
            if (storeProcessed) {
                directory.storeAssetData(assetMessage, format: format, encrypted: false, data: processedData)
            }
            if (storeEncrypted) {
                directory.storeAssetData(assetMessage, format: format, encrypted: true, data: encryptedData)
            }
        }
        
        if (storeOriginal) {
            directory.storeAssetData(assetMessage, format: .original, encrypted: false, data: imageData)
        }
        
        
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
        let data = sut.imageAssetStorage.originalImageData()
        
        // then
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.hashValue, expectedData.hashValue)
    }

    func testThatOriginalImageDataReturnsNilIfThereIsNoFile() {
        // given
        let sut = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertNil(sut.imageAssetStorage.originalImageData())
    }

    func testThatIsPublicForFormatReturnsNoForAllFormats() {
        // given
        let formats = [ZMImageFormat.medium, ZMImageFormat.invalid, ZMImageFormat.original, ZMImageFormat.preview, ZMImageFormat.profile]
        
        // when
        let sut = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)

        // then
        for format in formats {
            XCTAssertFalse(sut.imageAssetStorage.isPublic(for: format))
        }
    }

    func testThatEncryptedDataForFormatReturnsValuesFromEncryptedFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: true, storeProcessed: true)
        
        for format in [ZMImageFormat.preview, ZMImageFormat.medium] {
            // when
            let data = message.imageAssetStorage.imageData(for: format, encrypted: true)
            
            // then
            let dataOnFile = self.uiMOC.zm_fileAssetCache.assetData(message, format: format, encrypted: true)
            XCTAssertEqual(dataOnFile, data)
        }
    }
    
    func testThatImageDataForFormatReturnsValuesFromProcessedFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: true, storeProcessed: true)
        
        for format in [ZMImageFormat.preview, ZMImageFormat.medium] {
            // when
            let data = message.imageAssetStorage.imageData(for: format, encrypted: false)
            
            // then
            let dataOnFile = self.uiMOC.zm_fileAssetCache.assetData(message, format: format, encrypted: false)
            XCTAssertEqual(dataOnFile, data)
        }
    }
    
    func testThatImageDataForFormatReturnsNilWhenThereIsNoFile() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        for format in [ZMImageFormat.preview, ZMImageFormat.medium] {
            
            // when
            let plainData = message.imageAssetStorage.imageData(for: format, encrypted: false)
            let encryptedData = message.imageAssetStorage.imageData(for: format, encrypted: true)
            
            // then
            XCTAssertNil(plainData)
            XCTAssertNil(encryptedData)
            
        }
    }
    
    func testThatImageDataCanBeFetchedAsynchrounously() {
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        uiMOC.saveOrRollback()
        
        // expect
        let expectation = self.expectation(description: "Image arrived")
        
        // when
        message.imageMessageData?.fetchImageData(with: DispatchQueue.global(qos: .background), completionHandler: { (imageData) in
            XCTAssertNotNil(imageData)
            expectation.fulfill()
        })
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
    
    func testThatItReturnsTheOriginalImageSize() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        
        for _ in [ZMImageFormat.preview, ZMImageFormat.medium] {
            
            // when
            let originalSize = message.imageAssetStorage.originalImageSize()
            
            // then
            XCTAssertEqual(originalSize, self.sampleImageProperties(.medium).size)
            
        }
    }
    
    func testThatItReturnsZeroOriginalImageSizeIfItWasNotSet() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        for _ in [ZMImageFormat.preview, ZMImageFormat.medium] {
            
            // when
            let originalSize = message.imageAssetStorage.originalImageSize()
            
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
        XCTAssertEqual(message.imageAssetStorage.requiredImageFormats(), expected);

    }
    
    func testThatItReturnsTheRightValueForInlineForFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)

        // then
        XCTAssertFalse(message.imageAssetStorage.isInline(for:.medium));
        XCTAssertTrue(message.imageAssetStorage.isInline(for: .preview));
        XCTAssertFalse(message.imageAssetStorage.isInline(for: .original));
        XCTAssertFalse(message.imageAssetStorage.isInline(for: .profile));
        XCTAssertFalse(message.imageAssetStorage.isInline(for:.invalid));
    }

    func testThatItReturnsTheRightValueForUsingNativePushForFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
        
        // then
        XCTAssertTrue(message.imageAssetStorage.isUsingNativePush(for: .medium));
        XCTAssertFalse(message.imageAssetStorage.isUsingNativePush(for: .preview));
        XCTAssertFalse(message.imageAssetStorage.isUsingNativePush(for: .original));
        XCTAssertFalse(message.imageAssetStorage.isUsingNativePush(for: .profile));
        XCTAssertFalse(message.imageAssetStorage.isUsingNativePush(for: .invalid));
    }
    
    func testThatItClearsOnlyTheOriginalImageFormat() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: true, storeProcessed: true)
        
        // when
        message.imageAssetStorage.processingDidFinish()
        
        // then
        let directory = self.uiMOC.zm_fileAssetCache
        XCTAssertNil(directory.assetData(message, format: .original, encrypted: false))
        XCTAssertNil(message.imageAssetStorage.originalImageData())
        XCTAssertNotNil(directory.assetData(message, format: .medium, encrypted: false))
        XCTAssertNotNil(directory.assetData(message, format: .preview, encrypted: false))
        XCTAssertNotNil(directory.assetData(message, format: .medium, encrypted: true))
        XCTAssertNotNil(directory.assetData(message, format: .preview, encrypted: true))
    }

    func testThatItSetsTheCorrectImageDataPropertiesWhenSettingTheData() {
        
        for format in [ZMImageFormat.medium, ZMImageFormat.preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
            let testData = "foobar".data(using: String.Encoding.utf8, allowLossyConversion: false)!
            let testProperties = ZMIImageProperties(size: CGSize(width: 33, height: 55), length: UInt(10), mimeType: "image/tiff")
            
            // when
            message.imageAssetStorage.setImageData(testData, for: format, properties: testProperties)
            
            // then
            XCTAssertEqual(message.imageAssetStorage.genericMessage(for: format)!.image.width, 33)
            XCTAssertEqual(message.imageAssetStorage.genericMessage(for: format)!.image.height, 55)
            XCTAssertEqual(message.imageAssetStorage.genericMessage(for: format)!.image.size, 10)
            XCTAssertEqual(message.imageAssetStorage.genericMessage(for: format)!.image.mimeType, "image/tiff")
        }
    }
    
    func testThatItStoresTheRightEncryptionKeysNoMatterInWhichOrderTheDataIsSet() {
        
        // given
        let dataPreview = "FOOOOOO".data(using: String.Encoding.utf8)!
        let dataMedium = "xxxxxxxxx".data(using: String.Encoding.utf8)!
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        let testProperties = ZMIImageProperties(size: CGSize(width: 33, height: 55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.imageAssetStorage.setImageData(dataPreview, for: .preview, properties: testProperties) // simulate various order of setting
        message.imageAssetStorage.setImageData(dataMedium, for: .medium, properties: testProperties)
        message.imageAssetStorage.setImageData(dataPreview, for: .preview, properties: testProperties)
        message.imageAssetStorage.setImageData(dataMedium, for: .medium, properties: testProperties)

        // then
        let dataOnDiskForPreview = self.uiMOC.zm_fileAssetCache.assetData(message, format: .preview, encrypted: true)!
        let dataOnDiskForMedium = self.uiMOC.zm_fileAssetCache.assetData(message, format: .medium, encrypted: true)!
        
        XCTAssertEqual(dataOnDiskForPreview.zmSHA256Digest(), message.imageAssetStorage.previewGenericMessage!.image.sha256)
        XCTAssertEqual(dataOnDiskForMedium.zmSHA256Digest(), message.imageAssetStorage.mediumGenericMessage!.image.sha256)
    }
    
    func testThatItSetsTheMediumSizeOnThePreviewOriginalSize_SetPreviewFirst() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        let testData = "foobar".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let testMediumProperties = ZMIImageProperties(size: CGSize(width: 111, height: 100), length: UInt(1000), mimeType: "image/tiff")
        let testPreviewProperties = ZMIImageProperties(size: CGSize(width: 80, height: 55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.imageAssetStorage.setImageData(testData, for:  .preview, properties: testPreviewProperties)
        message.imageAssetStorage.setImageData(testData, for:  .medium, properties: testMediumProperties)
        
        // then
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.width, 80)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.height, 55)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.size, 10)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.mimeType, "image/tiff")
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.width, 111)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.height, 100)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.size, 1000)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.mimeType, "image/tiff")
    }
    
    func testThatItSetsTheMediumSizeOnThePreviewOriginalSize_SetMediumFirst() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
        let testData = "foobar".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let testMediumProperties = ZMIImageProperties(size: CGSize(width: 111, height: 100), length: UInt(1000), mimeType: "image/tiff")
        let testPreviewProperties = ZMIImageProperties(size: CGSize(width: 80, height: 55), length: UInt(10), mimeType: "image/tiff")
        
        // when
        message.imageAssetStorage.setImageData(testData, for:  .medium, properties: testMediumProperties)
        message.imageAssetStorage.setImageData(testData, for:  .preview, properties: testPreviewProperties)
        
        // then
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.width, 80)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.height, 55)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.size, 10)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .preview)!.image.mimeType, "image/tiff")
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.originalWidth, 111)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.originalHeight, 100)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.width, 111)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.height, 100)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.size, 1000)
        XCTAssertEqual(message.imageAssetStorage.genericMessage(for: .medium)!.image.mimeType, "image/tiff")
    }
    
    func testThatItSavesTheImageDataToFileInPlainTextAndEncryptedWhenSettingTheDataOnAnEncryptedMessage() {
        
        for format in [ZMImageFormat.medium, ZMImageFormat.preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(true, storeEncrypted: false, storeProcessed: false)
            let testProperties = ZMIImageProperties(size: CGSize(width: 33, height: 55), length: UInt(10), mimeType: "image/tiff")
            let data = sampleProcessedImageData(format)
            
            // when
            message.imageAssetStorage.setImageData(data, for: format, properties: testProperties)
            
            // then
            XCTAssertEqual(self.uiMOC.zm_fileAssetCache.assetData(message, format: format, encrypted: false), data)
            XCTAssertEqual(message.imageAssetStorage.imageData(for: format, encrypted: false), data)
            AssertOptionalNotNil(self.uiMOC.zm_fileAssetCache.assetData(message, format: format, encrypted: true)) {
                let decrypted = $0.zmDecryptPrefixedPlainTextIV(key: message.imageAssetStorage.genericMessage(for: format)!.image.otrKey)
                let sha = $0.zmSHA256Digest()
                XCTAssertEqual(decrypted, data)
                XCTAssertEqual(sha, message.imageAssetStorage.genericMessage(for: format)!.image.sha256)
            }
        }
    }

    func testThatItReturnsNilEncryptedDataIfTheImageIsNotEncrypted() {

        for format in [ZMImageFormat.medium, ZMImageFormat.preview] {
            
            // given
            let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: false)
            
            // then
            XCTAssertNil(message.imageAssetStorage.imageData(for: format, encrypted: true))
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
        self.uiMOC.zm_fileAssetCache.deleteAssetData(message, format: .medium, encrypted: false)
        
        // then
        XCTAssertFalse(message.hasDownloadedImage)
    }
    
    func testThatRequestingImageDownloadFiresANotification() {
        
        // given
        let message = self.createAssetClientMessageWithSampleImageAndEncryptionKeys(false, storeEncrypted: false, storeProcessed: true)
        message.managedObjectContext?.saveOrRollback()
        
        // expect
        let expectation = self.expectation(description: "Notified")
        let token = NotificationInContext.addObserver(name: ZMAssetClientMessage.imageDownloadNotificationName,
                                                      context: self.uiMOC.notificationContext,
                                                      object: message.objectID,
                                                      queue: nil)
        { _ in
            expectation.fulfill()
        }
        
        // when
        message.imageMessageData?.requestImageDownload()

        // then
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
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
            let genericMessage = ZMGenericMessage.message(content: ZMImageAsset(data: imageData, format: format)!, nonce: nonce)
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
            XCTAssertEqual(sut!.nonce, nonce)
            XCTAssertEqual(sut!.imageAssetStorage.genericMessage(for: format)?.data(), genericMessage.data())
            XCTAssertEqual(sut!.assetId, format == .medium ? mediumAssetId : nil)
        }
    }

    func testThatItCreatesOTRAssetMessagesFromFileThumbnailUpdateEvent() {

        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let nonce = UUID.create()
        let thumbnailId = "uuid"
        let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data.zmRandomSHA256Key(), sha256: Data.zmRandomSHA256Key())
        let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 4235, height: 324)
        let asset = ZMAsset.asset(withOriginal: nil, preview: ZMAssetPreview.preview(withSize: 256, mimeType: "video/mp4", remoteData: remoteData, imageMetaData: imageMetaData))
        
        let genericMessage = ZMGenericMessage.message(content: asset, nonce: nonce)
        
        let dataPayload = [
            "info" : genericMessage.data().base64String(),
            "id" : thumbnailId
        ] as [String : Any]
        
        let payload = self.payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload)!
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)
        
        // when
        var sut: ZMAssetClientMessage!
        performPretendingUiMocIsSyncMoc {
            sut = ZMAssetClientMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil).message as? ZMAssetClientMessage
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.conversation?.remoteIdentifier, conversation.remoteIdentifier)
        XCTAssertEqual(sut.sender?.remoteIdentifier!.transportString(), payload["from"] as? String)
        XCTAssertEqual(sut.serverTimestamp?.transportString(), payload["time"] as? String)
        XCTAssertEqual(sut.fileMessageData?.thumbnailAssetID, thumbnailId)
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
            
            let genericMessage = ZMGenericMessage.message(content: asset, nonce: nonce)
            
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
            sut.update(with: updateEvent2!, for: conversation)
            
            // then
            XCTAssertEqual(sut.serverTimestamp, firstDate)

        }
    }

    func testThatItUpdatesTheServerTimestampAfterPreviewWasUploaded() {
        
        // given
        let referenceDate = Date(timeIntervalSince1970: 123456)
        let updatedDate = Date(timeIntervalSince1970:127476)
        
        let message = ZMAssetClientMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
        message.serverTimestamp = referenceDate
        message.uploadState = .uploadingPlaceholder
        
        let updatedKeys = Set([#keyPath(ZMAssetClientMessage.uploadState)])
        
        // when
        message.update(withPostPayload: ["time": updatedDate.transportString()] , updatedKeys: updatedKeys)
        
        // then
        XCTAssertEqual(message.serverTimestamp, updatedDate)
    }
    
    func testThatItDoesNotUpdateTheServerTimestampAfterMediumWasUploaded() {

        // given
        let referenceDate = Date(timeIntervalSince1970: 123456)
        let updatedDate = Date(timeIntervalSince1970:127476)
        
        let message = ZMAssetClientMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
        message.serverTimestamp = referenceDate
        message.uploadState = .uploadingFullAsset
        
        let updatedKeys = Set([#keyPath(ZMAssetClientMessage.uploadState)])
        
        // when
        message.update(withPostPayload: ["time": updatedDate.transportString()] , updatedKeys: updatedKeys)
        // then
        XCTAssertEqual(message.serverTimestamp, referenceDate)
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
            let sut = appendFileMessage(to: conversation)!
            XCTAssertNotNil(sut.fileMessageData, line: line)
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
        
        XCTAssertNil(sut.fileMessageData, line: line)
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
            let genericMessage = ZMGenericMessage.message(content: ZMConfirmation.confirm(messageId: message.nonce!), nonce: UUID.create())
            _ = ZMMessageConfirmation.createOrUpdateMessageConfirmation(genericMessage, conversation: message.conversation!, sender: message.sender!)
            message.managedObjectContext?.saveOrRollback()
        }
    }
    
}


// MARK: - Asset V3

// MARK: Receiving


extension ZMAssetClientMessageTests {

    typealias PreviewMeta = (otr: Data, sha: Data, assetId: String?, token: String?)

    private func originalGenericMessage(nonce: UUID, image: ZMAssetImageMetaData? = nil, preview: ZMAssetPreview? = nil, mimeType: String = "image/jpg", name: String? = nil) -> ZMGenericMessage {
        let asset = ZMAsset.asset(withOriginal: .original(withSize: 128, mimeType: mimeType, name: name, imageMetaData: image), preview: preview)
        return ZMGenericMessage.message(content: asset, nonce: nonce)
    }

    private func uploadedGenericMessage(nonce: UUID, otr: Data = .randomEncryptionKey(), sha: Data = .zmRandomSHA256Key(), assetId: UUID? = UUID.create(), token: UUID? = UUID.create()) -> ZMGenericMessage {

        let assetBuilder = ZMAsset.builder()!
        let remoteBuilder = ZMAssetRemoteData.builder()!

        _ = remoteBuilder.setOtrKey(otr)
        _ = remoteBuilder.setSha256(sha)
        if let assetId = assetId {
            _ = remoteBuilder.setAssetId(assetId.transportString())
        }
        if let token = token {
            _ = remoteBuilder.setAssetToken(token.transportString())
        }

        assetBuilder.setUploaded(remoteBuilder)
        return ZMGenericMessage.message(content: assetBuilder.build(), nonce: nonce)
    }

    func previewGenericMessage(with nonce: UUID, assetId: String? = UUID.create().transportString(), token: String? = UUID.create().transportString(), otr: Data = .randomEncryptionKey(), sha: Data = .randomEncryptionKey()) -> (ZMGenericMessage, PreviewMeta) {
        let assetBuilder = ZMAsset.builder()
        let previewBuilder = ZMAssetPreview.builder()
        let remoteBuilder = ZMAssetRemoteData.builder()

        _ = remoteBuilder?.setOtrKey(otr)
        _ = remoteBuilder?.setSha256(sha)
        if let assetId = assetId {
            _ = remoteBuilder?.setAssetId(assetId)
        }
        if let token = token {
            _ = remoteBuilder?.setAssetToken(token)
        }
        _ = previewBuilder?.setSize(512)
        _ = previewBuilder?.setMimeType("image/jpg")
        _ = previewBuilder?.setRemote(remoteBuilder)
        _ = assetBuilder?.setPreview(previewBuilder)

        let previewMeta = (otr, sha, assetId, token)
        return (ZMGenericMessage.message(content: assetBuilder!.build(), nonce: nonce), previewMeta)
    }

    func createMessageWithNonce() -> (ZMAssetClientMessage, UUID) {
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: self.uiMOC)
        sut.sender = selfUser
        sut.visibleInConversation = conversation
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        return (sut, nonce)
    }

    func testThatItSetsVersion3WhenAMessageIsUpdatedWithAnAssetUploadedWithAssetId_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let uploaded = uploadedGenericMessage(nonce: nonce)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: true)

        // then
        XCTAssertEqual(sut.version, 3)
    }

    func testThatItSetsVersion3WhenAMessageIsUpdatedWithAnAssetPreviewWithAssetId_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let (preview, _) = previewGenericMessage(with: nonce)
        sut.update(with: preview, updateEvent: ZMUpdateEvent(), initialUpdate: true)

        // then
        XCTAssertEqual(sut.version, 3)
    }

    func testThatItDoesNotSetVersion3WhenAMessageIsUpdatedWithAnAssetUploadedWithoutAssetId_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let uploaded = uploadedGenericMessage(nonce: nonce, assetId: nil, token: nil)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: true)

        // then
        XCTAssertEqual(sut.version, 0)
    }

    func testThatItDoesNotSetVersion3WhenAMessageIsUpdatedWithAnAssetPreviewWithoutAssetId_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let (preview, _) = previewGenericMessage(with: nonce, assetId: nil, token: nil)
        sut.update(with: preview, updateEvent: ZMUpdateEvent(), initialUpdate: true)

        // then
        XCTAssertEqual(sut.version, 0)
    }

    func testThatItReportsDownloadedFileWhenThereIsAFileOnDisk_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let assetId = UUID.create()
        let assetData = Data.secureRandomData(length: 512)

        sut.update(with: originalGenericMessage(nonce: nonce, name: "document.pdf"), updateEvent: ZMUpdateEvent(), initialUpdate: true)
        sut.update(with: uploadedGenericMessage(nonce: nonce, assetId: assetId), updateEvent: ZMUpdateEvent(), initialUpdate: false)
        uiMOC.zm_fileAssetCache.storeAssetData(sut, encrypted: false, data: assetData)


        // then
        XCTAssertTrue(sut.hasDownloadedFile)
        XCTAssertFalse(sut.hasDownloadedImage)
        XCTAssertEqual(sut.version, 3)
    }

    func testThatItReportsDownloadedImageWhenThereIsAnImageFileInTheCache_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let assetId = UUID.create()
        let assetData = Data.secureRandomData(length: 512)
        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        sut.update(with: originalGenericMessage(nonce: nonce, image: image, preview: nil), updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploadedGenericMessage(nonce: nonce, assetId: assetId), updateEvent: ZMUpdateEvent(), initialUpdate: false)
        uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .medium, encrypted: false, data: assetData)

        // then
        XCTAssertFalse(sut.hasDownloadedFile)
        XCTAssertTrue(sut.hasDownloadedImage)
        XCTAssertEqual(sut.version, 3)
    }

    func testThatItReportsIsImageWhenItHasImageMetaData() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        let original = originalGenericMessage(nonce: nonce, image: image, preview: nil)
        let uploaded = uploadedGenericMessage(nonce: nonce)

        // when
        sut.update(with: original, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: false)

        // then
        XCTAssertTrue(sut.genericAssetMessage!.v3_isImage)
        XCTAssertFalse(sut.hasDownloadedFile)
        XCTAssertFalse(sut.hasDownloadedImage)
        XCTAssertEqual(sut.imageMessageData?.originalSize, CGSize(width: 123, height: 4569))
        XCTAssertEqual(sut.version, 3)
    }

    func testThatItReturnsAValidImageDataIdentifierEqualToTheCacheKeyOfTheAsset() {
        // given
        let (sut, nonce) = createMessageWithNonce()
        let assetId = UUID.create()

        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        let original = originalGenericMessage(nonce: nonce, image: image, preview: nil)
        let uploaded = uploadedGenericMessage(nonce: nonce, assetId: assetId)

        // when
        sut.update(with: original, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: false)

        // then
        XCTAssertEqual(FileAssetCache.cacheKeyForAsset(sut, format: .medium), sut.imageMessageData?.imageDataIdentifier)
    }

    func testThatItReturnsTheThumbnailIdWhenItHasAPreviewRemoteData_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let (preview, previewMeta) = previewGenericMessage(with: nonce)
        sut.update(with: preview, updateEvent: ZMUpdateEvent(), initialUpdate: false)

        // then
        XCTAssertEqual(sut.fileMessageData?.thumbnailAssetID, previewMeta.assetId)
    }

    func testThatItReturnsTheThumbnailDataWhenItHasItOnDisk_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let previewData = Data.secureRandomData(length: 512)
        let (preview, _) = previewGenericMessage(with: nonce)
        sut.update(with: preview, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .medium, encrypted: false, data: previewData)

        // then
        XCTAssertFalse(sut.hasDownloadedFile)
        XCTAssertTrue(sut.hasDownloadedImage)
        XCTAssertEqual(sut.version, 3)
        
        let expectation = self.expectation(description: "preview data was retreived")
        sut.fileMessageData?.fetchImagePreviewData(queue: .global(qos: .background), completionHandler: { (previewDataResult) in
            XCTAssertEqual(previewDataResult, previewData)
            expectation.fulfill()
        })
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatIsHasDownloadedImageAndReturnsItWhenTheImageIsOnDisk_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        let data = verySmallJPEGData()
        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        let original = originalGenericMessage(nonce: nonce, image: image, preview: nil)
        let uploaded = uploadedGenericMessage(nonce: nonce)

        // when
        sut.update(with: original, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: false)

        uiMOC.zm_fileAssetCache.storeAssetData(sut, format: .medium, encrypted: false, data: data)

        // then
        XCTAssertTrue(sut.genericAssetMessage!.v3_isImage)
        XCTAssertFalse(sut.hasDownloadedFile)
        XCTAssertTrue(sut.hasDownloadedImage)
        XCTAssertEqual(sut.imageMessageData?.imageData, data)
        XCTAssertEqual(sut.version, 3)
    }

    func testThatRequestingImageDownloadFiresANotification_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()
        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        let original = originalGenericMessage(nonce: nonce, image: image, preview: nil)
        let uploaded = uploadedGenericMessage(nonce: nonce)

        // when
        sut.update(with: original, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        XCTAssertEqual(sut.transferState, .uploaded)

        // when
        sut.imageMessageData?.requestImageDownload()

        // then
        XCTAssertEqual(sut.transferState, .downloading)
    }
    
    func testThatRequestingUploadingImageDownloadHasNoEffect() {
        // given
        let (sut, nonce) = createMessageWithNonce()
        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        let original = originalGenericMessage(nonce: nonce, image: image, preview: nil)
        let uploaded = uploadedGenericMessage(nonce: nonce)
        
        // when
        sut.update(with: original, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.transferState = .uploading
        XCTAssertEqual(sut.transferState, .uploading)
        
        // when
        sut.imageMessageData?.requestImageDownload()
        
        // then
        XCTAssertEqual(sut.transferState, .uploading)
    }
    
    func testThatRequestingFileDoesNotResetTheTransferStateForUnavailableAssets_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()
        let image = ZMAssetImageMetaData.imageMetaData(withWidth: 123, height: 4569)
        let original = originalGenericMessage(nonce: nonce, image: image, preview: nil)
        let uploaded = uploadedGenericMessage(nonce: nonce)
        
        // when
        sut.update(with: original, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.update(with: uploaded, updateEvent: ZMUpdateEvent(), initialUpdate: false)
        sut.transferState = .unavailable
        
        // when
        sut.imageMessageData?.requestImageDownload()
        
        // then
        XCTAssertEqual(sut.transferState, .unavailable)
    }

}

// MARK: - isGIF
extension ZMAssetClientMessageTests {
    func testThatItDetectsGIF_MIME() {
        // GIVEN
        let gifMIME = "image/gif"
        // WHEN
        let isGif = gifMIME.isGIF
        // THEN
        XCTAssertTrue(isGif)
    }
    
    func testThatItRejectsNonGIF_MIME() {
        // GIVEN
        
        ["text/plain", "application/pdf", "image/jpeg", "video/mp4"].forEach {
        
            // WHEN
            let isGif = $0.isGIF
            // THEN
            XCTAssertFalse(isGif)
        }
    }
}

// MARK: - PassKit
extension ZMAssetClientMessageTests {
    func testThatItDetectsPass_MIME() {
        // GIVEN
        let passMIME = "application/vnd.apple.pkpass"

        // WHEN & THEN
        XCTAssertTrue(passMIME.isPassMimeType)
    }
}
