//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

enum MimeType: String {
    case text = "text/plain"
}

class BaseZMAssetClientMessageTests: BaseZMClientMessageTests {
    var message: ZMAssetClientMessage!
    var currentTestURL: URL?

    override func tearDown() {
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 2))
        if let url = currentTestURL {
            removeTestFile(at: url)
        }
        currentTestURL = nil
        message = nil
        super.tearDown()
    }

    override func createFileMetadata(filename: String? = nil) -> ZMFileMetadata {
        let metadata = super.createFileMetadata(filename: filename)
        currentTestURL = metadata.fileURL
        return metadata
    }

    func appendFileMessage(
        to conversation: ZMConversation,
        fileMetaData: ZMFileMetadata? = nil
    ) -> ZMAssetClientMessage? {
        let nonce = UUID.create()
        let data = fileMetaData ?? createFileMetadata()

        return try? conversation.appendFile(with: data, nonce: nonce) as? ZMAssetClientMessage
    }

    func appendV2ImageMessage(to conversation: ZMConversation) throws {
        let imageData = verySmallJPEGData()
        let messageNonce = UUID.create()

        message = try conversation.appendImage(from: imageData, nonce: messageNonce) as? ZMAssetClientMessage

        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size: imageSize, length: UInt(imageData.count), mimeType: "image/jpeg")!

        let keys = ZMImageAssetEncryptionKeys(
            otrKey: Data.randomEncryptionKey(),
            macKey: Data.zmRandomSHA256Key(),
            mac: Data.zmRandomSHA256Key()
        )

        let mediumMessage = ImageAsset(
            mediumProperties: properties,
            processedProperties: properties,
            encryptionKeys: keys,
            format: .medium
        )
        let previewMessage = ImageAsset(
            mediumProperties: properties,
            processedProperties: properties,
            encryptionKeys: keys,
            format: .preview
        )

        try message.setUnderlyingMessage(GenericMessage(content: mediumMessage, nonce: messageNonce))
        try message.setUnderlyingMessage(GenericMessage(content: previewMessage, nonce: messageNonce))
    }

    func appendImageMessage(to conversation: ZMConversation, imageData: Data? = nil) -> ZMAssetClientMessage {
        let data = imageData ?? verySmallJPEGData()
        let nonce = UUID.create()
        let message = try! conversation.appendImage(from: data, nonce: nonce) as! ZMAssetClientMessage

        let uploaded = WireProtos.Asset(withUploadedOTRKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key())

        do {
            try message.setUnderlyingMessage(GenericMessage(content: uploaded, nonce: nonce))
        } catch {
            XCTFail()
        }

        return message
    }
}

final class ZMAssetClientMessageTests: BaseZMAssetClientMessageTests {
    func testThatItDeletesCopiesOfDownloadedFilesIntoTemporaryFolder() {
        // given
        let sut = appendFileMessage(to: conversation)!
        uiMOC.zm_fileAssetCache.storeMediumImage(data: .secureRandomData(length: 100), for: sut)
        guard let tempFolder = sut.temporaryDirectoryURL else { XCTFail(); return }

        XCTAssertNotNil(sut.temporaryURLToDecryptedFile())
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFolder.path))

        // when
        sut.deleteContent()

        // then
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempFolder.path))
    }
}

// MARK: - ZMAsset / ZMFileMessageData

extension ZMAssetClientMessageTests {
    func testThatItCreatesFileAssetMessageWithNotRelativePath() {
        // given
        let metadata = createFileMetadata(filename: "../../fileName")
        let sut = appendFileMessage(to: conversation, fileMetaData: metadata)

        // then
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut?.temporaryURLToDecryptedFile())

        guard let absoluteString = sut?.temporaryURLToDecryptedFile()?.absoluteString else {
            XCTFail("asset doesn't have a file URL")
            return
        }

        XCTAssertFalse(absoluteString.contains("../"))
    }

    func testThatItCreatesFileAssetMessageInTheRightStateToBeUploaded() {
        // given
        let sut = appendFileMessage(to: conversation)!

        // then
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.delivered)
        XCTAssertEqual(sut.transferState, .uploading)
        XCTAssertEqual(sut.filename, currentTestURL!.lastPathComponent)
        XCTAssertNotNil(sut.fileMessageData)
        XCTAssertEqual(sut.version, 3)
    }

    func testThatTransferStateIsUpdated_WhenExpired() {
        // given
        let sut = appendFileMessage(to: conversation)!
        XCTAssertEqual(sut.transferState, .uploading)

        // when
        sut.expire()

        // then
        XCTAssertEqual(sut.transferState, .uploadingFailed)
    }

    func testThatTransferStateIsNotUpdated_WhenExpired_IfAlreadyUploaded() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.transferState = .uploaded

        // when
        sut.expire()

        // then
        XCTAssertEqual(sut.transferState, .uploaded)
    }

    func testThatItHasDownloadedFileWhenTheFileIsOnDisk() {
        // given
        let sut = appendFileMessage(to: conversation)!

        // then
        XCTAssertTrue(sut.hasDownloadedFile)
    }

    func testThatItHasNoDownloadedFileWhenTheFileIsNotOnDisk() {
        // given
        let sut = appendFileMessage(to: conversation)!
        uiMOC.zm_fileAssetCache.deleteOriginalFileData(for: sut)

        // then
        XCTAssertFalse(sut.hasDownloadedFile)
    }

    func testThatItHasDownloadedImageWhenTheProcessedThumbnailIsOnDisk() {
        // given
        let sut = appendFileMessage(to: conversation)!

        uiMOC.zm_fileAssetCache.storeMediumImage(data: .secureRandomData(length: 100), for: sut)
        defer { self.uiMOC.zm_fileAssetCache.deleteMediumImageData(for: sut) }

        // then
        XCTAssertTrue(sut.hasDownloadedPreview)
    }

    func testThatItHasDownloadedImageWhenTheOriginalThumbnailIsOnDisk() {
        // given
        let sut = appendFileMessage(to: conversation)!

        uiMOC.zm_fileAssetCache.storeOriginalImage(data: .secureRandomData(length: 100), for: sut)
        defer { self.uiMOC.zm_fileAssetCache.deleteMediumImageData(for: sut) }

        // then
        XCTAssertTrue(sut.hasDownloadedPreview)
    }

    func testThatItSetsTheGenericAssetMessageWhenCreatingMessage() {
        // given
        let mimeType = "text/plain"
        let filename = "document.txt"
        let url = testURLWithFilename(filename)
        let data = createTestFile(at: url)
        defer { removeTestFile(at: url) }
        let size = UInt64(data.count)
        let fileMetadata = ZMFileMetadata(fileURL: url)

        // when
        let sut = appendFileMessage(to: conversation, fileMetaData: fileMetadata)!

        XCTAssertNotNil(sut)

        // then
        let assetMessage = sut.underlyingMessage
        XCTAssertNotNil(assetMessage)
        XCTAssertEqual(assetMessage?.messageID, sut.nonce?.transportString())
        XCTAssertNotNil(assetMessage?.asset)
        XCTAssertTrue(assetMessage!.asset.hasOriginal)

        let original = assetMessage?.asset.original
        XCTAssertNotNil(original)
        XCTAssertEqual(original?.name, filename)
        XCTAssertEqual(original?.mimeType, mimeType)
        XCTAssertEqual(original?.size, size)
    }

    func testThatItMergesMultipleGenericAssetMessagesForFileMessages() throws {
        let nonce = UUID.create()
        let mimeType = "text/plain"
        let filename = "document.txt"
        let url = testURLWithFilename(filename)
        let data = createTestFile(at: url)
        defer { removeTestFile(at: url) }
        let fileMetadata = ZMFileMetadata(fileURL: url)

        // when
        let sut = appendFileMessage(to: conversation, fileMetaData: fileMetadata)!

        XCTAssertNotNil(sut)

        let otrKey = Data.randomEncryptionKey()
        let encryptedData = try data.zmEncryptPrefixingPlainTextIV(key: otrKey)
        let sha256 = encryptedData.zmSHA256Digest()
        let preview = WireProtos.Asset.Preview(
            size: UInt64(data.count),
            mimeType: mimeType,
            remoteData: WireProtos.Asset.RemoteData(withOTRKey: otrKey, sha256: sha256),
            imageMetadata: WireProtos.Asset.ImageMetaData(width: 10, height: 10)
        )

        let previewAsset = WireProtos.Asset(original: nil, preview: preview)
        let previewMessage = GenericMessage(content: previewAsset, nonce: nonce)

        // when
        XCTAssertNoThrow(try sut.setUnderlyingMessage(previewMessage))

        // then
        XCTAssertEqual(sut.underlyingMessage?.messageID, nonce.transportString())

        guard let asset = sut.underlyingMessage?.asset else { return XCTFail() }
        XCTAssertNotNil(asset)
        XCTAssertTrue(asset.hasOriginal)
        XCTAssertTrue(asset.hasPreview)
        XCTAssertEqual(asset.original.name, filename)
        XCTAssertEqual(sut.fileMessageData?.filename, filename)
        XCTAssertEqual(asset.original.mimeType, mimeType)
        XCTAssertEqual(asset.original.size, UInt64(data.count))
        XCTAssertEqual(asset.preview, preview)
    }

    func testThatItUpdatesTheMetaDataWhenOriginalAssetMessageGetMerged() {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        sut.sender = selfUser
        let mimeType = "text/plain"
        let name = "example.txt"
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)

        // when
        let assetOriginal = WireProtos.Asset.Original(withSize: 256, mimeType: mimeType, name: name)
        let asset = WireProtos.Asset(original: assetOriginal, preview: nil)
        let originalMessage = GenericMessage(content: asset, nonce: nonce)
        let updateEvent = createUpdateEvent(nonce, conversationID: UUID.create(), genericMessage: originalMessage)

        sut.update(with: updateEvent, initialUpdate: true)
        // then
        XCTAssertEqual(sut.fileMessageData?.size, 256)
        XCTAssertEqual(sut.fileMessageData?.mimeType, mimeType)
        XCTAssertEqual(sut.fileMessageData?.filename, name)
        XCTAssertEqual(sut.fileMessageData?.transferState, .uploading)
    }

    func testThatItUpdatesTheTransferStateWhenTheUploadedMessageIsMerged() {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)

        // when
        let asset = WireProtos.Asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key())
        var originalMessage = GenericMessage(content: asset, nonce: nonce)
        originalMessage.updateUploaded(assetId: "id", token: "token", domain: "domain")
        let updateEvent = createUpdateEvent(nonce, conversationID: UUID.create(), genericMessage: originalMessage)
        sut.update(with: updateEvent, initialUpdate: true)

        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, .uploaded)
    }

    func testThatItDoesntUpdateTheTransferStateWhenTheUploadedMessageIsMergedButDoesntContainAssetId() {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)

        // when
        let asset = WireProtos.Asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key())
        let originalMessage = GenericMessage(content: asset, nonce: nonce)
        let updateEvent = createUpdateEvent(nonce, conversationID: UUID.create(), genericMessage: originalMessage)

        sut.update(with: updateEvent, initialUpdate: true)

        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, .uploading)
    }

    func testThatItDeletesTheMessageWhenTheNotUploadedCanceledMessageIsMerged() {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)

        // when
        let asset = WireProtos.Asset(withNotUploaded: .cancelled)
        let originalMessage = GenericMessage(content: asset, nonce: nonce)
        let updateEvent = createUpdateEvent(nonce, conversationID: UUID.create(), genericMessage: originalMessage)
        sut.update(with: updateEvent, initialUpdate: true)

        // then
        XCTAssertTrue(sut.isZombieObject)
    }

    /// This is testing a race condition on the receiver side if the sender cancels but not fast enough, and he BE just
    /// got the entire payload
    func testThatItUpdatesTheTransferStateWhenTheCanceledMessageIsMergedAfterUploadingSuccessfully() {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)

        // when
        let asset = WireProtos.Asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key())
        var message = GenericMessage(content: asset, nonce: nonce)
        message.updateUploaded(assetId: "id", token: "token", domain: "domain")
        let updateEvent = createUpdateEvent(nonce, conversationID: UUID.create(), genericMessage: message)
        sut.update(with: updateEvent, initialUpdate: true)

        let canceledMessage = GenericMessage(content: WireProtos.Asset(withNotUploaded: .cancelled), nonce: nonce)
        let updateEventForCanceled = createUpdateEvent(
            nonce,
            conversationID: UUID.create(),
            genericMessage: canceledMessage
        )
        sut.update(with: updateEventForCanceled, initialUpdate: true)

        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, .uploaded)
    }

    func testThatItUpdatesTheTransferStateWhenTheNotUploadedFailedMessageIsMerged() {
        // given
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)

        // when
        let message = GenericMessage(content: WireProtos.Asset(withNotUploaded: .failed), nonce: nonce)
        let updateEvent = createUpdateEvent(nonce, conversationID: UUID.create(), genericMessage: message)
        sut.update(with: updateEvent, initialUpdate: true)

        // then
        XCTAssertEqual(sut.fileMessageData?.transferState, .uploadingFailed)
    }

    func testThatItReturnsAValidFileMessageData() {
        syncMOC.performAndWait {
            // given
            let sut = appendFileMessage(to: syncConversation)!

            // then
            XCTAssertNotNil(sut)
            XCTAssertNotNil(sut.fileMessageData)
        }
    }

    func testThatItReturnsTheEncryptedUploadedDataWhenItHasAUploadedGenericMessageInTheDataSet() {
        syncMOC.performAndWait {
            // given
            let sut = appendFileMessage(to: syncConversation)!

            // when
            let otrKey = Data.randomEncryptionKey()
            let sha256 = Data.zmRandomSHA256Key()

            let genericMessage = GenericMessage(
                content: WireProtos.Asset(withUploadedOTRKey: otrKey, sha256: sha256),
                nonce: sut.nonce!
            )

            do {
                try sut.setUnderlyingMessage(genericMessage)
            } catch {
                XCTFail()
            }

            // then
            XCTAssertNotNil(sut)
            guard let asset = sut.underlyingMessage?.asset else { return XCTFail() }
            XCTAssertTrue(asset.hasUploaded)
            let uploaded = asset.uploaded
            XCTAssertEqual(uploaded.otrKey, otrKey)
            XCTAssertEqual(uploaded.sha256, sha256)
        }
    }

    func testThatItCancelsUpload() {
        syncMOC.performAndWait {
            // given
            let sut = appendFileMessage(to: syncConversation)!

            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            XCTAssertEqual(sut.transferState, .uploading)

            // when
            sut.fileMessageData?.cancelTransfer()

            // then
            XCTAssertEqual(sut.transferState, .uploadingCancelled)
            XCTAssertEqual(sut.progress, 0.0)
        }
    }

    func testThatItCanCancelsUploadMultipleTimes() {
        // given
        syncMOC.performAndWait {
            let sut = appendFileMessage(to: syncConversation)!

            XCTAssertNotNil(sut.fileMessageData)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            XCTAssertEqual(sut.transferState, .uploading)

            // when / then
            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, .uploadingCancelled)

            sut.resend()
            XCTAssertEqual(sut.transferState, .uploading)
            XCTAssertEqual(sut.progress, 0.0)

            sut.fileMessageData?.cancelTransfer()
            XCTAssertEqual(sut.transferState, .uploadingCancelled)

            sut.resend()
            XCTAssertEqual(sut.transferState, .uploading)
            XCTAssertEqual(sut.progress, 0.0)
        }
    }

    func testThatItPostsANotificationWhenTheDownloadOfTheMessageIsCancelled() {
        syncMOC.performAndWait {
            // given
            let sut = ZMAssetClientMessage(nonce: .create(), managedObjectContext: syncMOC)
            sut.sender = ZMUser.selfUser(in: syncMOC)
            sut.visibleInConversation = syncConversation
            let original = GenericMessage(
                content: WireProtos.Asset(imageSize: CGSize(width: 10, height: 10), mimeType: "text/plain", size: 256),
                nonce: sut.nonce!
            )

            do {
                try sut.setUnderlyingMessage(original)
            } catch {
                XCTFail()
            }

            sut.transferState = .uploaded
            XCTAssertTrue(self.syncMOC.saveOrRollback())

            let expectation = self.customExpectation(description: "Notification fired")
            let token = NotificationInContext.addObserver(
                name: ZMAssetClientMessage.didCancelFileDownloadNotificationName,
                context: self.uiMOC.notificationContext,
                object: sut.objectID
            ) { _ in
                expectation.fulfill()
            }

            // when
            sut.fileMessageData?.cancelTransfer()

            // then
            withExtendedLifetime(token) {
                XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
            }
        }
    }

    // MARK: Resending

    func testThatDeliveredIsReset_WhenResending() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.delivered = true

        // when
        sut.resend()

        // then
        XCTAssertFalse(sut.delivered)
    }

    func testThatProgressIsReset_WhenResending() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.progress = 56

        // when
        sut.resend()

        // then
        XCTAssertEqual(sut.progress, 0)
    }

    func testThatTransferStateIsUpdated_WhenResending() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.transferState = .uploadingFailed

        // when
        sut.resend()

        // then
        XCTAssertEqual(sut.transferState, .uploading)
    }

    func testThatTransferStateIsNotUpdated_WhenResending_IfAlreadyUploaded() {
        // given
        let sut = appendFileMessage(to: conversation)!
        sut.transferState = .uploaded

        // when
        sut.resend()

        // then
        XCTAssertEqual(sut.transferState, .uploaded)
    }

    func testThatItReturnsNilAssetIdOnANewlyCreatedMessage() {
        syncMOC.performAndWait {
            // given
            let sut = appendFileMessage(to: syncConversation)!

            // then
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
        }
    }

    // MARK: Updating AssetId

    func testThatItReturnsAssetIdWhenSettingItDirectly() {
        syncMOC.performAndWait {
            // given
            let previewSize: UInt64 = 46
            let previewMimeType = "image/jpeg"
            let remoteData = WireProtos.Asset.RemoteData.with {
                $0.otrKey = Data.zmRandomSHA256Key()
                $0.sha256 = Data.zmRandomSHA256Key()
            }
            let imageMetadata = WireProtos.Asset.ImageMetaData.with {
                $0.width = 4235
                $0.height = 324
            }

            let uuid = "asset-id"
            let sut = appendFileMessage(to: syncConversation)!

            let asset = WireProtos.Asset(
                original: nil,
                preview: WireProtos.Asset.Preview(
                    size: previewSize,
                    mimeType: previewMimeType,
                    remoteData: remoteData,
                    imageMetadata: imageMetadata
                )
            )

            do {
                try sut.setUnderlyingMessage(GenericMessage(content: asset, nonce: sut.nonce!))
            } catch {
                XCTFail()
            }

            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)

            // when
            sut.fileMessageData!.thumbnailAssetID = uuid

            // then
            XCTAssertEqual(sut.fileMessageData?.thumbnailAssetID, uuid)
            // testing that other properties are kept
            XCTAssertEqual(sut.underlyingMessage?.asset.preview.remote.otrKey, remoteData.otrKey)
            XCTAssertEqual(sut.underlyingMessage?.asset.preview.remote.sha256, remoteData.sha256)
            XCTAssertEqual(sut.underlyingMessage?.asset.preview.image.width, imageMetadata.width)
            XCTAssertEqual(sut.underlyingMessage?.asset.original.name, sut.filename)
        }
    }

    func testThatItDoesNotSetAssetIdWhenUpdatingFromAnUploadedMessage() {
        syncMOC.performAndWait {
            // given
            let previewSize: UInt64 = 46
            let previewMimeType = "image/jpeg"
            let remoteData = WireProtos.Asset.RemoteData(withOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key())
            let imageMetadata = WireProtos.Asset.ImageMetaData(width: 4235, height: 324)
            let sut = appendFileMessage(to: syncConversation)!

            let assetWithUploaded = WireProtos.Asset(
                withUploadedOTRKey: .zmRandomSHA256Key(),
                sha256: .zmRandomSHA256Key()
            )
            let assetWithPreview = WireProtos.Asset(
                original: nil,
                preview: WireProtos.Asset.Preview(
                    size: previewSize,
                    mimeType: previewMimeType,
                    remoteData: remoteData,
                    imageMetadata: imageMetadata
                )
            )

            var asset = WireProtos.Asset()
            do {
                try asset.merge(serializedData: assetWithUploaded.serializedData())
                try asset.preview.merge(serializedData: assetWithPreview.preview.serializedData())
            } catch {
                XCTFail()
                return
            }

            let genericMessage = GenericMessage(content: asset, nonce: sut.nonce!)
            let updateEvent = createUpdateEvent(
                sut.nonce!,
                conversationID: UUID.create(),
                genericMessage: genericMessage
            )
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)

            // when
            sut.update(with: updateEvent, initialUpdate: true)

            // then
            XCTAssertNil(sut.fileMessageData?.thumbnailAssetID)
            // testing that other properties are kept
            XCTAssertEqual(sut.underlyingMessage?.asset.preview.remote.otrKey, remoteData.otrKey)
            XCTAssertEqual(sut.underlyingMessage?.asset.preview.remote.sha256, remoteData.sha256)
            XCTAssertEqual(sut.underlyingMessage?.asset.preview.image.width, imageMetadata.width)
            XCTAssertEqual(sut.underlyingMessage?.asset.original.name, sut.filename)
        }
    }

    func testThatItClearsGenericAssetMessageCacheWhenFaulting() {
        // given
        let previewSize: UInt64 = 46
        let previewMimeType = "image/jpeg"
        let remoteData = WireProtos.Asset.RemoteData(withOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key())
        let imageMetadata = WireProtos.Asset.ImageMetaData(width: 4235, height: 324)

        let uuid = UUID.create()
        let sut = appendFileMessage(to: conversation)!

        XCTAssertFalse(sut.underlyingMessage!.asset.hasPreview)
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        uiMOC.refresh(sut, mergeChanges: false) // Turn object into fault

        syncMOC.performAndWait {
            let sutInSyncContext = self.syncMOC.object(with: sut.objectID) as! ZMAssetClientMessage
            let preview = WireProtos.Asset.Preview(
                size: previewSize,
                mimeType: previewMimeType,
                remoteData: remoteData,
                imageMetadata: imageMetadata
            )
            let asset = WireProtos.Asset(original: nil, preview: preview)
            let genericMessage = GenericMessage(content: asset, nonce: sut.nonce!)
            let updateEvent = createUpdateEvent(uuid, conversationID: UUID.create(), genericMessage: genericMessage)
            XCTAssertNil(sutInSyncContext.fileMessageData?.thumbnailAssetID)

            sutInSyncContext.update(with: updateEvent, initialUpdate: true) // Append preview
            XCTAssertTrue(self.syncMOC.saveOrRollback())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        // properties changed in sync context are visible
        XCTAssertEqual(sut.underlyingMessage?.asset.preview.remote.otrKey, remoteData.otrKey)
        XCTAssertEqual(sut.underlyingMessage?.asset.preview.remote.sha256, remoteData.sha256)
        XCTAssertEqual(sut.underlyingMessage?.asset.preview.image.width, imageMetadata.width)
    }
}

// MARK: Helpers

extension ZMAssetClientMessageTests {
    func createOtherClientAndConversation() -> (UserClient, ZMConversation) {
        let otherUser = ZMUser.insertNewObject(in: syncMOC)
        otherUser.remoteIdentifier = .create()
        let otherClient = createClient(for: otherUser, createSessionWithSelfUser: true)
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)
        XCTAssertTrue(syncMOC.saveOrRollback())

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
        XCTAssertTrue(uiMOC.saveOrRollback())
        uiMOC.refresh(sut, mergeChanges: false)

        // then
        XCTAssertEqual(sut.associatedTaskIdentifier, identifier)
    }
}

// MARK: - Message generation

extension ZMAssetClientMessageTests {
    func testThatItSavesTheOriginalFileWhenCreatingMessage() throws {
        // given
        let sut = appendImageMessage(to: conversation)

        // then
        XCTAssertNotNil(uiMOC.zm_fileAssetCache.originalImageData(for: sut))
    }

    func testThatItSetsTheOriginalImageSize() throws {
        // given
        let image = verySmallJPEGData()
        let expectedSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: image)

        // when
        let sut = appendImageMessage(to: conversation, imageData: image)

        // then
        XCTAssertEqual(expectedSize, sut.imageMessageData?.originalSize)
    }
}

// MARK: - Post event

extension ZMAssetClientMessageTests {
    func testThatItDoesSetConversationLastServerTimestampWhenPostingAsset_MessageIsImage() {
        // given
        syncMOC.performGroupedAndWait {
            let message = self.appendImageMessage(to: self.syncConversation)
            let emptyDict = [String: String]()
            let payload: [AnyHashable: Any] = [
                "deleted": emptyDict,
                "missing": emptyDict,
                "redundant": emptyDict,
                "time": Date().transportString(),
            ]

            // when
            message.update(withPostPayload: payload, updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))

            // then
            XCTAssertEqual(message.serverTimestamp, message.conversation?.lastServerTimeStamp)
        }
    }

    func testThatItDoesSetExpectsReadConfirmationWhenPostingAsset_MessageIsImage_HasReceiptsEnabled() {
        // given
        syncMOC.performGroupedAndWait {
            self.syncConversation.hasReadReceiptsEnabled = true
            let message = self.appendImageMessage(to: self.syncConversation)
            let emptyDict = [String: String]()
            let payload: [AnyHashable: Any] = [
                "deleted": emptyDict,
                "missing": emptyDict,
                "redundant": emptyDict,
                "time": Date().transportString(),
            ]
//            message.transferState = .uploadingFullAsset

            // when
            message.update(withPostPayload: payload, updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))

            // then
            XCTAssertTrue(message.expectsReadConfirmation)
        }
    }

    func testThatItDoesNotSetExpectsReadConfirmationWhenPostingAsset_MessageIsImage_HasReceiptsDisabled() {
        // given
        syncMOC.performGroupedAndWait {
            self.syncConversation.hasReadReceiptsEnabled = false
            let message = self.appendImageMessage(to: self.syncConversation)
            let emptyDict = [String: String]()
            let payload: [AnyHashable: Any] = [
                "deleted": emptyDict,
                "missing": emptyDict,
                "redundant": emptyDict,
                "time": Date().transportString(),
            ]

            // when
            message.update(withPostPayload: payload, updatedKeys: Set([#keyPath(ZMAssetClientMessage.transferState)]))

            // then
            XCTAssertFalse(message.expectsReadConfirmation)
        }
    }
}

// MARK: - Assets V2

extension ZMAssetClientMessageTests {
    func sampleImageData() -> Data {
        verySmallJPEGData()
    }

    func sampleProcessedImageData(_ format: ZMImageFormat) -> Data {
        "\(format.stringValue) fake data".data(using: String.Encoding.utf8, allowLossyConversion: true)!
    }

    func sampleImageProperties(_ format: ZMImageFormat) -> ZMIImageProperties {
        let mult = format == .medium ? 100 : 1
        return ZMIImageProperties(
            size: CGSize(width: CGFloat(300 * mult), height: CGFloat(100 * mult)),
            length: UInt(100 * mult),
            mimeType: "image/jpeg"
        )!
    }

    func createV2AssetClientMessageWithSampleImageAndEncryptionKeys(
        _ storeOriginal: Bool,
        storeEncrypted: Bool,
        storeProcessed: Bool,
        imageData: Data? = nil
    ) throws -> ZMAssetClientMessage {
        let directory = uiMOC.zm_fileAssetCache!
        let nonce = UUID.create()
        let imageData = imageData ?? sampleImageData()
        var genericMessage: [ZMImageFormat: GenericMessage] = [:]
        let assetMessage = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        assetMessage.sender = selfUser
        assetMessage.visibleInConversation = conversation

        for format in [ZMImageFormat.medium, ZMImageFormat.preview] {
            let processedData = sampleProcessedImageData(format)
            let otrKey = Data.randomEncryptionKey()
            let encryptedData = try processedData.zmEncryptPrefixingPlainTextIV(key: otrKey)

            let sha256 = encryptedData.zmSHA256Digest()
            let encryptionKeys = ZMImageAssetEncryptionKeys(otrKey: otrKey, sha256: sha256)
            let imageAsset = ImageAsset(
                mediumProperties: storeProcessed ? sampleImageProperties(.medium) : nil,
                processedProperties: storeProcessed ? sampleImageProperties(format) : nil,
                encryptionKeys: storeEncrypted ? encryptionKeys : nil,
                format: format
            )

            genericMessage[format] = GenericMessage(content: imageAsset, nonce: nonce)

            switch format {
            case .medium:
                if storeProcessed {
                    directory.storeMediumImage(data: processedData, for: assetMessage)
                }

                if storeEncrypted {
                    directory.storeEncryptedMediumImage(data: encryptedData, for: assetMessage)
                }

            case .preview:
                if storeProcessed {
                    directory.storePreviewImage(data: processedData, for: assetMessage)
                }

                if storeEncrypted {
                    directory.storeEncryptedPreviewImage(data: encryptedData, for: assetMessage)
                }

            default:
                break
            }
        }

        if storeOriginal {
            directory.storeOriginalImage(data: imageData, for: assetMessage)
        }

        do {
            try assetMessage.setUnderlyingMessage(genericMessage[.preview]!)
            try assetMessage.setUnderlyingMessage(genericMessage[.medium]!)
        } catch {
            XCTFail()
        }

        assetMessage.assetId = nonce
        return assetMessage
    }

    func testThatImageDataCanBeFetchedAsynchrounously() throws {
        // given
        let message = try createV2AssetClientMessageWithSampleImageAndEncryptionKeys(
            false,
            storeEncrypted: false,
            storeProcessed: true
        )
        uiMOC.saveOrRollback()

        // expect
        let expectation = customExpectation(description: "Image arrived")

        // when
        message.imageMessageData?.fetchImageData(
            with: DispatchQueue.global(qos: .background),
            completionHandler: { imageData in
                XCTAssertNotNil(imageData)
                expectation.fulfill()
            }
        )
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItReturnsImageDataIdentifier() throws {
        // given
        let message1 = try createV2AssetClientMessageWithSampleImageAndEncryptionKeys(
            false,
            storeEncrypted: false,
            storeProcessed: false
        )
        let message2 = try createV2AssetClientMessageWithSampleImageAndEncryptionKeys(
            false,
            storeEncrypted: false,
            storeProcessed: false
        )

        // when
        let id1 = message1.imageMessageData?.imageDataIdentifier
        let id2 = message2.imageMessageData?.imageDataIdentifier

        // then
        XCTAssertNotNil(id1)
        XCTAssertNotNil(id2)
        XCTAssertNotEqual(id1, id2)

        XCTAssertEqual(id1, message1.imageMessageData?.imageDataIdentifier) // not random!
    }

    func testThatItHasDownloadedFileWhenTheImageIsOnDisk() throws {
        // given
        let message = try createV2AssetClientMessageWithSampleImageAndEncryptionKeys(
            false,
            storeEncrypted: false,
            storeProcessed: true
        )

        // then
        XCTAssertTrue(message.hasDownloadedFile)
    }

    func testThatItHasDownloadedFileWhenTheOriginalIsOnDisk() throws {
        // given
        let message = try createV2AssetClientMessageWithSampleImageAndEncryptionKeys(
            true,
            storeEncrypted: false,
            storeProcessed: false
        )

        // then
        XCTAssertTrue(message.hasDownloadedFile)
    }

    func testThatDoesNotHaveDownloadedFileWhenTheImageIsNotOnDisk() throws {
        // given
        let message = try createV2AssetClientMessageWithSampleImageAndEncryptionKeys(
            false,
            storeEncrypted: false,
            storeProcessed: true
        )

        // when
        uiMOC.zm_fileAssetCache.deleteMediumImageData(for: message)

        // then
        XCTAssertFalse(message.hasDownloadedFile)
    }

    func testThatRequestingFileDownloadFiresANotification() throws {
        // given
        let message = try createV2AssetClientMessageWithSampleImageAndEncryptionKeys(
            false,
            storeEncrypted: false,
            storeProcessed: true
        )
        message.managedObjectContext?.saveOrRollback()

        // expect
        let expectation = customExpectation(description: "Notified")
        let token = NotificationInContext.addObserver(
            name: ZMAssetClientMessage.imageDownloadNotificationName,
            context: uiMOC.notificationContext,
            object: message.objectID,
            queue: nil
        ) { _ in
            expectation.fulfill()
        }

        // when
        message.imageMessageData?.requestFileDownload()

        // then
        withExtendedLifetime(token) {
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
}

// MARK: - UpdateEvents

extension ZMAssetClientMessageTests {
    func testThatItCreatesOTRAssetMessagesFromAssetNotUploadedFailedUpdateEvent() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let nonce = UUID.create()
        let thumbnailId = "uuid"
        let asset = WireProtos.Asset(withNotUploaded: .failed)

        let genericMessage = GenericMessage(content: asset, nonce: nonce)

        let genericMessageData = try? genericMessage.serializedData()
        let dataPayload = [
            "info": genericMessageData!.base64String(),
            "id": thumbnailId,
        ] as [String: Any]

        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload)
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

        // when
        var sut: ZMAssetClientMessage!
        performPretendingUiMocIsSyncMoc {
            sut = ZMAssetClientMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.conversation?.remoteIdentifier, conversation.remoteIdentifier)
        XCTAssertEqual(sut.sender?.remoteIdentifier!.transportString(), payload["from"] as? String)
        XCTAssertEqual(sut.serverTimestamp?.transportString(), payload["time"] as? String)
        XCTAssertEqual(sut.nonce, nonce)
        XCTAssertNotNil(sut.fileMessageData)
    }

    func testThatItCreatesOTRAssetMessagesFromAssetOriginalUpdateEvent() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let nonce = UUID.create()
        let thumbnailId = "uuid"
        let imageMetadata = WireProtos.Asset.ImageMetaData(width: 4235, height: 324)
        let original = WireProtos.Asset.Original(
            withSize: 12321,
            mimeType: "image/jpeg",
            name: nil,
            imageMetaData: imageMetadata
        )
        let asset = WireProtos.Asset(original: original, preview: nil)

        let genericMessage = GenericMessage(content: asset, nonce: nonce)

        let genericMessageData = try? genericMessage.serializedData()
        let dataPayload = [
            "info": genericMessageData!.base64String(),
            "id": thumbnailId,
        ] as [String: Any]

        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRAsset, data: dataPayload)
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!

        // when
        var sut: ZMAssetClientMessage!
        performPretendingUiMocIsSyncMoc {
            sut = ZMAssetClientMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.conversation?.remoteIdentifier, conversation.remoteIdentifier)
        XCTAssertEqual(sut.sender?.remoteIdentifier!.transportString(), payload["from"] as? String)
        XCTAssertEqual(sut.serverTimestamp?.transportString(), payload["time"] as? String)
        XCTAssertEqual(sut.nonce, nonce)
        XCTAssertNotNil(sut.fileMessageData)
    }

    func testThatItDoesNotUpdateTheTimestampIfLater() {
        syncMOC.performGroupedAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            let nonce = UUID.create()
            let thumbnailId = UUID.create()
            let remoteData = WireProtos.Asset.RemoteData(
                withOTRKey: Data.zmRandomSHA256Key(),
                sha256: Data.zmRandomSHA256Key()
            )
            let imageMetadata = WireProtos.Asset.ImageMetaData(width: 4235, height: 324)
            let asset = WireProtos.Asset(
                original: nil,
                preview: WireProtos.Asset.Preview(
                    size: 256,
                    mimeType: "video/mp4",
                    remoteData: remoteData,
                    imageMetadata: imageMetadata
                )
            )
            let firstDate = Date(timeIntervalSince1970: 12334)
            let secondDate = firstDate.addingTimeInterval(234_444)

            let genericMessage = GenericMessage(content: asset, nonce: nonce)

            let genericMessageData = try? genericMessage.serializedData()
            let dataPayload = [
                "info": genericMessageData!.base64String(),
                "id": thumbnailId.transportString(),
            ]

            let payload1 = self.payloadForMessage(
                in: conversation,
                type: EventConversationAddOTRAsset,
                data: dataPayload,
                time: firstDate
            )
            let updateEvent1 = ZMUpdateEvent(fromEventStreamPayload: payload1, uuid: nil)!
            let payload2 = self.payloadForMessage(
                in: conversation,
                type: EventConversationAddOTRAsset,
                data: dataPayload,
                time: secondDate
            )
            let updateEvent2 = ZMUpdateEvent(fromEventStreamPayload: payload2, uuid: nil)!

            // when
            let sut = ZMAssetClientMessage.createOrUpdate(from: updateEvent1, in: self.syncMOC, prefetchResult: nil)
            sut?.update(with: updateEvent2, for: conversation)

            // then
            XCTAssertEqual(sut?.serverTimestamp, firstDate)
        }
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

    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Sent() throws {
        try checkThatImageAssetMessageCanBeDeleted(true, .sent)
    }

    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Delivered() throws {
        try checkThatImageAssetMessageCanBeDeleted(true, .delivered)
    }

    func testThatAnAssetClientMessageWithImageDataCanBeDeleted_Expired() throws {
        try checkThatImageAssetMessageCanBeDeleted(true, .failedToSend)
    }

    func testThatAnAssetClientMessageWithImageDataCan_Not_BeDeleted_Pending() throws {
        try checkThatImageAssetMessageCanBeDeleted(false, .pending)
    }
}

extension ZMAssetClientMessageTests {
    // MARK: Helper

    func checkThatFileMessageCanBeDeleted(_ canBeDeleted: Bool, _ state: ZMDeliveryState, line: UInt = #line) {
        syncMOC.performAndWait {
            // given
            let sut = appendFileMessage(to: syncConversation)!
            XCTAssertNotNil(sut.fileMessageData, line: line)
            XCTAssertTrue(self.syncMOC.saveOrRollback(), line: line)

            // when
            self.updateMessageState(sut, state: state)
            XCTAssertEqual(sut.deliveryState.rawValue, state.rawValue, line: line)

            // then
            XCTAssertEqual(sut.canBeDeleted, canBeDeleted, line: line)
        }
    }

    func checkThatImageAssetMessageCanBeDeleted(
        _ canBeDeleted: Bool,
        _ state: ZMDeliveryState,
        line: UInt = #line
    ) throws {
        // given
        let sut = appendImageMessage(to: conversation)
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
            _ = ZMMessageConfirmation(
                type: .delivered,
                message: message,
                sender: message.sender!,
                serverTimestamp: Date(),
                managedObjectContext: message.managedObjectContext!
            )
            message.managedObjectContext?.saveOrRollback()
        }
    }
}

// MARK: - Asset V3

// MARK: Receiving

extension ZMAssetClientMessageTests {
    typealias PreviewMeta = (otr: Data, sha: Data, assetId: String?, token: String?, domain: String?)

    private func updateEventForOriginal(
        nonce: UUID,
        image: WireProtos.Asset.ImageMetaData? = nil,
        preview: WireProtos.Asset.Preview? = nil,
        mimeType: String = "image/jpeg",
        name: String? = nil
    ) -> ZMUpdateEvent {
        let original = WireProtos.Asset.Original(withSize: 128, mimeType: mimeType, name: name, imageMetaData: image)
        let asset = WireProtos.Asset(original: original, preview: preview)
        return createUpdateEvent(
            nonce,
            conversationID: UUID.create(),
            genericMessage: GenericMessage(content: asset, nonce: nonce)
        )
    }

    private func updateEventForUploaded(
        nonce: UUID,
        otr: Data = .randomEncryptionKey(),
        sha: Data = .zmRandomSHA256Key(),
        assetId: UUID? = UUID.create(),
        token: UUID? = UUID.create()
    ) -> ZMUpdateEvent {
        let remoteData = WireProtos.Asset.RemoteData(
            withOTRKey: otr,
            sha256: sha,
            assetId: assetId?.transportString(),
            assetToken: token?.transportString()
        )
        let asset = WireProtos.Asset.with {
            $0.uploaded = remoteData
        }
        return createUpdateEvent(
            nonce,
            conversationID: UUID.create(),
            genericMessage: GenericMessage(content: asset, nonce: nonce)
        )
    }

    func previewGenericMessage(
        with nonce: UUID,
        assetId: String? = UUID.create().transportString(),
        token: String? = UUID.create().transportString(),
        domain: String? = UUID.create().transportString(),
        otr: Data = .randomEncryptionKey(),
        sha: Data = .randomEncryptionKey()
    ) -> (GenericMessage, PreviewMeta) {
        let remoteData = WireProtos.Asset.RemoteData(withOTRKey: otr, sha256: sha, assetId: assetId, assetToken: token)
        let preview = WireProtos.Asset.Preview(
            size: 512,
            mimeType: "image/jpeg",
            remoteData: remoteData,
            imageMetadata: WireProtos.Asset.ImageMetaData(width: 123, height: 4578)
        )
        let asset = WireProtos.Asset.with { $0.preview = preview }
        let message = GenericMessage(content: asset, nonce: nonce)

        let previewMeta = (otr, sha, assetId, token, domain)

        XCTAssertEqual(message.asset.preview.remote.assetID, assetId)
        return (message, previewMeta)
    }

    func createMessageWithNonce() -> (ZMAssetClientMessage, UUID) {
        let nonce = UUID.create()
        let sut = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        sut.sender = selfUser
        sut.visibleInConversation = conversation
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertNotNil(sut)
        return (sut, nonce)
    }

    func testThatItReportsDownloadedFileWhenThereIsAFileOnDisk_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let assetId = UUID.create()
        let assetData = Data.secureRandomData(length: 512)

        sut.update(with: updateEventForOriginal(nonce: nonce, name: "document.pdf"), initialUpdate: true)
        sut.update(with: updateEventForUploaded(nonce: nonce, assetId: assetId), initialUpdate: false)
        uiMOC.zm_fileAssetCache.storeOriginalFile(data: assetData, for: sut)

        // then
        XCTAssertTrue(sut.hasDownloadedFile)
        XCTAssertEqual(sut.version, 3)
    }

    func testThatItReportsDownloadedFileWhenThereIsAnImageFileInTheCache_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let assetId = UUID.create()
        let assetData = Data.secureRandomData(length: 512)
        let image = WireProtos.Asset.ImageMetaData(width: 123, height: 4569)
        sut.update(with: updateEventForOriginal(nonce: nonce, image: image, preview: nil), initialUpdate: false)
        sut.update(with: updateEventForUploaded(nonce: nonce, assetId: assetId), initialUpdate: false)
        uiMOC.zm_fileAssetCache.storeMediumImage(data: assetData, for: sut)

        // then
        XCTAssertTrue(sut.hasDownloadedFile)
        XCTAssertEqual(sut.version, 3)
    }

    func testThatItReportsIsImageWhenItHasImageMetaData() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        let image = WireProtos.Asset.ImageMetaData(width: 123, height: 4569)
        let original = updateEventForOriginal(nonce: nonce, image: image, preview: nil)
        let uploaded = updateEventForUploaded(nonce: nonce)

        // when
        sut.update(with: original, initialUpdate: false)
        sut.update(with: uploaded, initialUpdate: false)

        // then
        XCTAssertTrue(sut.underlyingMessage!.v3_isImage)
        XCTAssertEqual(sut.imageMessageData?.originalSize, CGSize(width: 123, height: 4569))
        XCTAssertEqual(sut.version, 3)
    }

    func testThatItReturnsAValidImageDataIdentifierEqualToTheCacheKeyOfTheAsset() {
        // given
        let (sut, nonce) = createMessageWithNonce()
        let assetId = UUID.create()

        let image = WireProtos.Asset.ImageMetaData(width: 123, height: 4569)
        let original = updateEventForOriginal(nonce: nonce, image: image, preview: nil)
        let uploaded = updateEventForUploaded(nonce: nonce, assetId: assetId)

        // when
        sut.update(with: original, initialUpdate: false)
        sut.update(with: uploaded, initialUpdate: false)

        // then
        XCTAssertEqual(FileAssetCache.cacheKeyForAsset(sut, format: .medium), sut.imageMessageData?.imageDataIdentifier)
    }

    func testThatItReturnsTheThumbnailIdWhenItHasAPreviewRemoteData_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let (preview, previewMeta) = previewGenericMessage(with: nonce)
        let updateEvent = createUpdateEvent(nonce, conversationID: UUID.create(), genericMessage: preview)
        sut.update(with: updateEvent, initialUpdate: false)

        // then
        XCTAssertEqual(sut.fileMessageData?.thumbnailAssetID, previewMeta.assetId)
    }

    func testThatItReturnsTheThumbnailDataWhenItHasItOnDisk_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        // when
        let previewData = Data.secureRandomData(length: 512)
        let (preview, _) = previewGenericMessage(with: nonce)
        let updateEvent = createUpdateEvent(nonce, conversationID: UUID.create(), genericMessage: preview)
        sut.update(with: updateEvent, initialUpdate: false)
        uiMOC.zm_fileAssetCache.storeMediumImage(data: previewData, for: sut)

        // then
        XCTAssertFalse(sut.hasDownloadedFile)
        XCTAssertTrue(sut.hasDownloadedPreview)
        XCTAssertEqual(sut.version, 3)

        let expectation = customExpectation(description: "preview data was retreived")
        sut.fileMessageData?.fetchImagePreviewData(
            queue: .global(qos: .background),
            completionHandler: { previewDataResult in
                XCTAssertEqual(previewDataResult, previewData)
                expectation.fulfill()
            }
        )
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatIsHasDownloadedFileAndReturnsItWhenTheImageIsOnDisk_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()

        let data = verySmallJPEGData()
        let image = WireProtos.Asset.ImageMetaData(width: 123, height: 4569)
        let original = updateEventForOriginal(nonce: nonce, image: image, preview: nil)
        let uploaded = updateEventForUploaded(nonce: nonce)

        // when
        sut.update(with: original, initialUpdate: false)
        sut.update(with: uploaded, initialUpdate: false)

        uiMOC.zm_fileAssetCache.storeMediumImage(data: data, for: sut)

        // then
        XCTAssertTrue(sut.underlyingMessage!.v3_isImage)
        XCTAssertTrue(sut.hasDownloadedFile)
        XCTAssertEqual(sut.imageMessageData?.imageData, data)
        XCTAssertEqual(sut.version, 3)
    }

    func testThatRequestingImagePreviewDownloadFiresANotification_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()
        let (preview, _) = previewGenericMessage(with: nonce)
        let updateEvent = createUpdateEvent(nonce, conversationID: UUID.create(), genericMessage: preview)
        sut.update(with: updateEvent, initialUpdate: false)
        uiMOC.saveOrRollback()

        // expect
        let expectation = customExpectation(description: "Notified")
        let token = NotificationInContext.addObserver(
            name: ZMAssetClientMessage.imageDownloadNotificationName,
            context: uiMOC.notificationContext,
            object: sut.objectID,
            queue: nil
        ) { _ in
            expectation.fulfill()
        }

        // when
        sut.fileMessageData?.requestImagePreviewDownload()

        // then
        withExtendedLifetime(token) {
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    func testThatRequestingFileDownloadFiresANotification_V3() {
        // given
        let (sut, nonce) = createMessageWithNonce()
        let image = WireProtos.Asset.ImageMetaData(width: 123, height: 4569)
        let original = updateEventForOriginal(nonce: nonce, image: image, preview: nil)
        let uploaded = updateEventForUploaded(nonce: nonce)

        sut.update(with: original, initialUpdate: false)
        sut.update(with: uploaded, initialUpdate: false)
        uiMOC.saveOrRollback()

        // expect
        let expectation = customExpectation(description: "Notified")
        let token = NotificationInContext.addObserver(
            name: ZMAssetClientMessage.assetDownloadNotificationName,
            context: uiMOC.notificationContext,
            object: sut.objectID,
            queue: nil
        ) { _ in
            expectation.fulfill()
        }

        // when
        sut.imageMessageData?.requestFileDownload()

        // then
        withExtendedLifetime(token) {
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
}

// MARK: - isGIF

extension ZMAssetClientMessageTests {
    func testThatItDetectsGIF_MIME() {
        // GIVEN
        let gifMIME = "image/gif"
        // WHEN
        let isGif = UTIHelper.conformsToGifType(mime: gifMIME)
        // THEN
        XCTAssertEqual(isGif, true)
    }

    func testThatItRejectsNonGIF_MIME() {
        // GIVEN

        for item in ["text/plain", "application/pdf", "image/jpeg", "video/mp4"] {
            // WHEN
            let isGif = UTIHelper.conformsToGifType(mime: item)

            // THEN
            XCTAssertEqual(isGif, false)
        }
    }
}
