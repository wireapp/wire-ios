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
import WireRequestStrategy
@testable import WireMessageStrategy
import XCTest
import WireMessageStrategy
import WireDataModel



fileprivate extension AssetClientMessageRequestStrategy {

    @discardableResult func assertCreatesValidRequestForAsset(in conversation: ZMConversation, line: UInt = #line) -> ZMTransportRequest! {
        guard let request = nextRequest() else {
            XCTFail("No request generated", line: line)
            return nil
        }

        XCTAssertEqual(request.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/otr/messages", line: line)
        XCTAssertEqual(request.method, .methodPOST, line: line)
        return request
    }

}

fileprivate extension ZMTransportRequest {

    func complete(withHttpStatus status: Int) {
        let payload = ["time": Date().transportString()] as ZMTransportData
        let response = ZMTransportResponse(payload: payload, httpStatus: status, transportSessionError: nil)
        complete(with: response)
    }

}


class AssetClientMessageRequestStrategyTests: MessagingTestBase {

    fileprivate var clientRegistrationStatus: MockClientRegistrationStatus!
    fileprivate var sut: AssetClientMessageRequestStrategy!
    fileprivate var imageData = mediumJPEGData()

    override func setUp() {
        super.setUp()
        clientRegistrationStatus = MockClientRegistrationStatus()
        self.syncMOC.performGroupedBlockAndWait {
            self.sut = AssetClientMessageRequestStrategy(clientRegistrationStatus: self.clientRegistrationStatus, managedObjectContext: self.syncMOC)
        }
    }

    // MARK: Helper
    @discardableResult func createMessage(
        isImage: Bool = true,
        uploaded: Bool = false,
        preview: Bool = false,
        assetId: Bool = false,
        previewAssetId: Bool = false,
        uploadState: ZMAssetUploadState = .uploadingFullAsset,
        transferState: ZMFileTransferState = .uploading,
        line: UInt = #line
        ) -> ZMAssetClientMessage {

        let message: ZMAssetClientMessage!
        if isImage {
            message = self.groupConversation.appendMessage(withImageData: imageData) as! ZMAssetClientMessage
        } else {
            let url = Bundle(for: AssetClientMessageRequestStrategyTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!
            message = self.groupConversation.appendMessage(with: ZMFileMetadata(fileURL: url, thumbnail: nil)) as! ZMAssetClientMessage
        }

        if isImage {
            let size = CGSize(width: 368, height: 520)
            let properties = ZMIImageProperties(size: size, length: 1024, mimeType: "image/jpg")
            message.imageAssetStorage?.setImageData(imageData, for: .medium, properties: properties)
            XCTAssertEqual(message.mimeType, "image/jpg", line: line)
            XCTAssertEqual(message.size, 1024, line: line)
            XCTAssertEqual(message.imageMessageData?.originalSize, size, line: line)
            XCTAssertTrue(message.genericAssetMessage!.assetData!.hasOriginal(), line: line)
        }

        if preview {
            let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
            let previewId: String? = previewAssetId ? UUID.create().transportString() : nil
            let previewAsset = ZMAssetPreview.preview(
                withSize: 128,
                mimeType: "image/jpg",
                remoteData: .remoteData(withOTRKey: otr, sha256: sha, assetId: previewId, assetToken: nil),
                imageMetaData: .imageMetaData(withWidth: 123, height: 420)
            )

            let previewMessage = ZMGenericMessage.genericMessage(
                asset: .asset(withOriginal: nil, preview: previewAsset),
                messageID: message.nonce.transportString(),
                expiresAfter: NSNumber(value: self.groupConversation.messageDestructionTimeout)
            )

            message.add(previewMessage)
            XCTAssertTrue(message.genericAssetMessage!.assetData!.hasPreview(), line: line)
            XCTAssertEqual(message.genericAssetMessage!.assetData!.preview.remote.hasAssetId(), previewAssetId, line: line)
            XCTAssertEqual(message.isEphemeral, self.groupConversation.messageDestructionTimeout != 0, line: line)
        }

        if uploaded {
            let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
            var uploaded = ZMGenericMessage.genericMessage(
                withUploadedOTRKey: otr,
                sha256: sha,
                messageID: message.nonce.transportString(),
                expiresAfter: NSNumber(value: self.groupConversation.messageDestructionTimeout)
            )
            if assetId {
                uploaded = uploaded.updatedUploaded(withAssetId: UUID.create().transportString(), token: nil)!
            }
            message.add(uploaded)
            XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded(), line: line)
            XCTAssertEqual(message.isEphemeral, self.groupConversation.messageDestructionTimeout != 0, line: line)
        }

        message.uploadState = uploadState
        message.transferState = transferState

        syncMOC.saveOrRollback()
        prepareUpload(of: message)

        XCTAssertEqual(message.transferState, transferState, line: line)
        XCTAssertEqual(message.version, 3, line: line)
        XCTAssertEqual(message.uploadState, uploadState, line: line)
        XCTAssertEqual(message.genericAssetMessage?.assetData?.original.hasImage(), isImage, line: line)

        return message
    }

    func prepareUpload(of message: ZMAssetClientMessage) {
        ZMChangeTrackerBootstrap.bootStrapChangeTrackers(sut.contextChangeTrackers, on: syncMOC)
    }

    // MARK: Request Generation

    func testThatItDoesNotCreateARequestIfThereIsNoMatchingMessage() {
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithoutUploaded() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.createMessage(uploaded: false)

            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithUploadedButWithoutAssetId() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.createMessage(uploaded: true)

            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithUploadedAndAssetIdInTheWrongTransferState() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let message = self.createMessage()
            message.transferState = .uploaded

            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithUploadedAndAssetIdInTheWrongUploadedState() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let message = self.createMessage(uploaded: true, assetId: true)
            message.uploadState = .done

            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItCreatesARequestForAnUploadedImageMessage() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.createMessage(uploaded: true, assetId: true)

            // THEN
            self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)
        }
    }

    func testThatItCreatesARequestForAnUploadedImageMessage_Ephemeral() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.groupConversation.messageDestructionTimeout = 15
            self.createMessage(uploaded: true, assetId: true)

            // WHEN
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated") }

            // THEN
            let expected = "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages?report_missing=\(self.otherUser.remoteIdentifier!.transportString())"
            XCTAssertEqual(request.path, expected)
            XCTAssertEqual(request.method, .methodPOST)
        }
    }

    func testThatItCreatesARequestForANonImageMessageWithOnlyAsset_Original() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.createMessage(isImage: false, uploadState: .uploadingPlaceholder)

            // THEN
            self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)
        }
    }

    func testThatItCreatesARequestForANonImageMessageWithAsset_PreviewAndPreviewAssetId() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingThumbnail)
            
            // THEN
            self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)
        }
    }

    func testThatItDoesNotCreateARequestForANonImageMessageWithAsset_PreviewAndWithoutPreviewAssetId() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.createMessage(isImage: false, preview: true, previewAssetId: false, uploadState: .uploadingThumbnail)

            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItCreatesARequestForANonImageMessageWithAsset_UploadedAndAssetId() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset)

            // THEN
            self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)
        }
    }

    func testThatItDoesNotCreateARequestForANonImageMessageWithAsset_UploadedAndWithoutAssetId() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.createMessage(isImage: false, uploaded: true, assetId: false, uploadState: .uploadingFullAsset)

            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItCreatesARequestToUploadNotUploaded_Failed() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset, transferState: .uploading)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            request.complete(withHttpStatus: 400)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.uploadState, .uploadingFailed)
            XCTAssertEqual(message.transferState, .failedUpload)
            XCTAssertTrue(message.genericAssetMessage!.assetData!.hasNotUploaded())
            self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)
        }
    }

    func testThatItCreatesARequestToUploadNotUploaded_Cancelled() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset, transferState: .uploading)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            message.fileMessageData?.cancelTransfer()
        }
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.uploadState, .uploadingFailed)
            XCTAssertEqual(message.transferState, .cancelledUpload)
            XCTAssertTrue(message.genericAssetMessage!.assetData!.hasNotUploaded())
            self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)
        }
    }

    func testThatItDoesNotCreateARequestToUploadNotUploaded_WrongStates() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(isImage: false, uploadState: .uploadingFullAsset, transferState: .uploading)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let notUploaded = ZMGenericMessage.genericMessage(notUploaded: .CANCELLED, messageID: message.nonce.transportString())
            message.add(notUploaded)
            XCTAssertTrue(message.genericAssetMessage!.assetData!.hasNotUploaded())
        }
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItDoesNotCreateARequestForANonImageMessageWithOnlyAsset_Original_WrongStates() {
        
        self.syncMOC.performGroupedBlockAndWait {

            self.createMessage(isImage: false, uploadState: .uploadingThumbnail, transferState: .uploading)
            XCTAssertNil(self.sut.nextRequest())
            
            self.createMessage(isImage: false, uploadState: .uploadingFullAsset, transferState: .uploading)
            XCTAssertNil(self.sut.nextRequest())
            
            self.createMessage(isImage: false, uploadState: .uploadingFailed, transferState: .uploading)
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItDoesNotCreateARequestForANonImageMessageWithAsset_PreviewAndPreviewAssetId_WrongStates() {
        self.syncMOC.performGroupedBlockAndWait {
            
            self.createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .done, transferState: .uploading)
            XCTAssertNil(self.sut.nextRequest())
            
            self.createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingFullAsset, transferState: .uploading)
            XCTAssertNil(self.sut.nextRequest())
            
            self.createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingFailed, transferState: .uploading)
            XCTAssertNil(self.sut.nextRequest())
            
            self.createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingFullAsset, transferState: .downloaded)
            XCTAssertNil(self.sut.nextRequest())
            
            self.createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingFailed, transferState: .uploaded)
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItDoesNotCreateARequestForANonImageMessageWithAsset_UploadedAndAssetId_WrongStates() {
        self.syncMOC.performGroupedBlockAndWait {
            
            self.createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .done, transferState: .uploading)
            XCTAssertNil(self.sut.nextRequest())
            
            self.createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFailed, transferState: .uploading)
            XCTAssertNil(self.sut.nextRequest())
            
            self.createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingThumbnail, transferState: .uploading)
            XCTAssertNil(self.sut.nextRequest())
            
            self.createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingThumbnail, transferState: .downloaded)
            XCTAssertNil(self.sut.nextRequest())
            
            self.createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingThumbnail, transferState: .uploaded)
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    // MARK: Response handling

    func testThatItMarksAnImageMessageAsSentWhenItReceivesASuccesfulResponse() {
        
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(uploaded: true, assetId: true)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            request.complete(withHttpStatus: 200)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssert(message.delivered)
            XCTAssertEqual(message.deliveryState, .sent)
            XCTAssertEqual(message.uploadState, .done)
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItMarksAnImageMessageAsSentWhenItReceivesASuccesfulResponse_Ephemeral() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            self.groupConversation.messageDestructionTimeout = 15
            message = self.createMessage(uploaded: true, assetId: true)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated") }
            request.complete(withHttpStatus: 200)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {

            XCTAssert(message.delivered)
            XCTAssertEqual(message.deliveryState, .sent)
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageWithoutThumbnailAfterUploadingTheOriginal() {
    
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(isImage: false, uploadState: .uploadingPlaceholder)
        }

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            request.complete(withHttpStatus: 200)
        }
        
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.uploadState, ZMAssetUploadState.uploadingFullAsset)
            XCTAssertEqual(message.transferState, .uploading)
            XCTAssertFalse(message.delivered)

            // No request should be generated until the full asset has been uploaded
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageWithThumbnailAfterUploadingTheOriginal() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(isImage: false, preview: true, uploadState: .uploadingPlaceholder)
            self.syncMOC.zm_imageAssetCache.storeAssetData(message.nonce, format: .original, encrypted: false, data: self.mediumJPEGData())
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            request.complete(withHttpStatus: 200)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.uploadState, .uploadingThumbnail)
            XCTAssertEqual(message.transferState, .uploading)
            XCTAssertFalse(message.delivered)

            // No request should be generated until the full asset has been uploaded
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterUploadingTheThumbnail() {
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            message = self.createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingThumbnail)

            // WHEN
            let request = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            request.complete(withHttpStatus: 200)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            
            XCTAssertEqual(message.uploadState, .uploadingFullAsset)
            XCTAssertEqual(message.transferState, .uploading)
            XCTAssertFalse(message.delivered)

            // No request should be generated until the full asset has been uploaded
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterUploadingTheFullAsset() {
        
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            request.complete(withHttpStatus: 200)
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.uploadState, .done)
            XCTAssertEqual(message.transferState, .downloaded)
            XCTAssertTrue(message.delivered)
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterUploadingTheFullAssetWithTheumbnail() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(isImage: false, uploaded: true, preview: true, assetId: true, previewAssetId: true, uploadState: .uploadingFullAsset)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            request.complete(withHttpStatus: 200)
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.uploadState, .done)
            XCTAssertEqual(message.transferState, .downloaded)
            XCTAssertTrue(message.delivered)
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterUploadingTheNotUploaded() {
        
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let uploadedRequest = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            uploadedRequest.complete(withHttpStatus: 400)
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.syncMOC.performGroupedBlockAndWait {
            let notUploadedRequest = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            notUploadedRequest.complete(withHttpStatus: 200)
        }
        
        // THEN
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.uploadState, .uploadingFailed)
            XCTAssertEqual(message.transferState, .failedUpload)
            XCTAssertFalse(message.delivered)
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterFailingToSendTheThumbnail() {
        
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingThumbnail)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let thumbnailRequest = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            thumbnailRequest.complete(withHttpStatus: 400)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.syncMOC.performGroupedBlockAndWait {
            let notUploadedRequest = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            notUploadedRequest.complete(withHttpStatus: 200)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.uploadState, .uploadingFailed)
            XCTAssertEqual(message.transferState, .failedUpload)
            XCTAssertFalse(message.delivered)
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterFailingToSendTheFullAsset() {
        
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let uploadedRequest = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            uploadedRequest.complete(withHttpStatus: 400)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.syncMOC.performGroupedBlockAndWait {
            let notUploadedRequest = self.sut.assertCreatesValidRequestForAsset(in: self.groupConversation)!
            notUploadedRequest.complete(withHttpStatus: 200)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.uploadState, .uploadingFailed)
            XCTAssertEqual(message.transferState, .failedUpload)
            XCTAssertFalse(message.delivered)
            XCTAssertNil(self.sut.nextRequest())
        }
    }

}
