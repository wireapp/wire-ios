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


class AssetClientMessageRequestStrategyTests: MessagingTest {

    fileprivate var clientRegistrationStatus: MockClientRegistrationStatus!
    fileprivate var sut: AssetClientMessageRequestStrategy!
    fileprivate var conversation: ZMConversation!
    fileprivate var otherUser: ZMUser!
    fileprivate var imageData = mediumJPEGData()

    override func setUp() {
        super.setUp()
        clientRegistrationStatus = MockClientRegistrationStatus()
        sut = AssetClientMessageRequestStrategy(clientRegistrationStatus: clientRegistrationStatus, managedObjectContext: syncMOC)
        createConversation()
        createSelfClient()
    }

    // MARK: Helper

    func createConversation() {
        conversation = .insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .oneOnOne
        conversation.connection = .insertNewObject(in: syncMOC)
        otherUser = .insertNewObject(in: syncMOC)
        conversation.connection?.to = otherUser
        otherUser.remoteIdentifier = .create()
    }

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
            message = conversation.appendMessage(withImageData: imageData, version3: true) as! ZMAssetClientMessage
        } else {
            let url = Bundle(for: AssetClientMessageRequestStrategyTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!
            message = conversation.appendMessage(with: ZMFileMetadata(fileURL: url, thumbnail: nil), version3: true) as! ZMAssetClientMessage
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
                expiresAfter: NSNumber(value: conversation.messageDestructionTimeout)
            )

            message.add(previewMessage)
            XCTAssertTrue(message.genericAssetMessage!.assetData!.hasPreview(), line: line)
            XCTAssertEqual(message.genericAssetMessage!.assetData!.preview.remote.hasAssetId(), previewAssetId, line: line)
            XCTAssertEqual(message.isEphemeral, conversation.messageDestructionTimeout != 0, line: line)
        }

        if uploaded {
            let (otr, sha) = (Data.randomEncryptionKey(), Data.zmRandomSHA256Key())
            var uploaded = ZMGenericMessage.genericMessage(
                withUploadedOTRKey: otr,
                sha256: sha,
                messageID: message.nonce.transportString(),
                expiresAfter: NSNumber(value: self.conversation.messageDestructionTimeout)
            )
            if assetId {
                uploaded = uploaded.updatedUploaded(withAssetId: UUID.create().transportString(), token: nil)!
            }
            message.add(uploaded)
            XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded(), line: line)
            XCTAssertEqual(message.isEphemeral, conversation.messageDestructionTimeout != 0, line: line)
        }

        message.uploadState = uploadState
        message.transferState = transferState

        syncMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), line: line)
        prepareUpload(of: message)

        XCTAssertEqual(message.transferState, transferState, line: line)
        XCTAssertEqual(message.version, 3, line: line)
        XCTAssertEqual(message.uploadState, uploadState, line: line)
        XCTAssertEqual(message.genericAssetMessage?.assetData?.original.hasImage(), isImage, line: line)

        return message
    }

    func prepareUpload(of message: ZMAssetClientMessage) {
        ZMChangeTrackerBootstrap.bootStrapChangeTrackers(sut.contextChangeTrackers, on: syncMOC)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: Request Generation

    func testThatItDoesNotCreateARequestIfThereIsNoMatchingMessage() {
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithoutUploaded() {
        // given
        createMessage(uploaded: false)

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithUploadedButWithoutAssetId() {
        // given
        createMessage(uploaded: true)

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithUploadedAndAssetIdInTheWrongTransferState() {
        // given
        let message = createMessage()
        message.transferState = .uploaded

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForAnImageMessageWithUploadedAndAssetIdInTheWrongUploadedState() {
        // given
        let message = createMessage(uploaded: true, assetId: true)
        message.uploadState = .done

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItCreatesARequestForAnUploadedImageMessage() {
        // given
        createMessage(uploaded: true, assetId: true)

        // then
        sut.assertCreatesValidRequestForAsset(in: conversation)
    }

    func testThatItCreatesARequestForAnUploadedImageMessage_Ephemeral() {
        // given
        conversation.messageDestructionTimeout = 15
        createMessage(uploaded: true, assetId: true)

        // when
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }

        // then
        let expected = "/conversations/\(conversation.remoteIdentifier!.transportString())/otr/messages?report_missing=\(otherUser.remoteIdentifier!.transportString())"
        XCTAssertEqual(request.path, expected)
        XCTAssertEqual(request.method, .methodPOST)
    }

    func testThatItCreatesARequestForANonImageMessageWithOnlyAsset_Original() {
        // given
        createMessage(isImage: false, uploadState: .uploadingPlaceholder)

        // then
        sut.assertCreatesValidRequestForAsset(in: conversation)
    }

    func testThatItCreatesARequestForANonImageMessageWithAsset_PreviewAndPreviewAssetId() {
        // given
        createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingThumbnail)

        // then
        sut.assertCreatesValidRequestForAsset(in: conversation)
    }

    func testThatItDoesNotCreateARequestForANonImageMessageWithAsset_PreviewAndWithoutPreviewAssetId() {
        // given
        createMessage(isImage: false, preview: true, previewAssetId: false, uploadState: .uploadingThumbnail)

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItCreatesARequestForANonImageMessageWithAsset_UploadedAndAssetId() {
        // given
        createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset)

        // then
        sut.assertCreatesValidRequestForAsset(in: conversation)
    }

    func testThatItDoesNotCreateARequestForANonImageMessageWithAsset_UploadedAndWithoutAssetId() {
        // given
        createMessage(isImage: false, uploaded: true, assetId: false, uploadState: .uploadingFullAsset)

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItCreatesARequestToUploadNotUploaded_Failed() {
        // given
        let message = createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset, transferState: .uploading)
        let request = sut.assertCreatesValidRequestForAsset(in: conversation)!

        // when
        request.complete(withHttpStatus: 400)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.uploadState, .uploadingFailed)
        XCTAssertEqual(message.transferState, .failedUpload)
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasNotUploaded())
        sut.assertCreatesValidRequestForAsset(in: conversation)
    }

    func testThatItCreatesARequestToUploadNotUploaded_Cancelled() {
        // given
        let message = createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset, transferState: .uploading)

        // when
        message.fileMessageData?.cancelTransfer()
        XCTAssertEqual(message.uploadState, .uploadingFailed)
        XCTAssertEqual(message.transferState, .cancelledUpload)
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasNotUploaded())

        // then
        sut.assertCreatesValidRequestForAsset(in: conversation)
    }

    func testThatItDoesNotCreateARequestToUploadNotUploaded_WrongStates() {
        // given
        let message = createMessage(isImage: false, uploadState: .uploadingFullAsset, transferState: .uploading)
        let notUploaded = ZMGenericMessage.genericMessage(notUploaded: .CANCELLED, messageID: message.nonce.transportString())
        message.add(notUploaded)

        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasNotUploaded())

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForANonImageMessageWithOnlyAsset_Original_WrongStates() {
        createMessage(isImage: false, uploadState: .uploadingThumbnail, transferState: .uploading)
        XCTAssertNil(sut.nextRequest())

        createMessage(isImage: false, uploadState: .uploadingFullAsset, transferState: .uploading)
        XCTAssertNil(sut.nextRequest())

        createMessage(isImage: false, uploadState: .uploadingFailed, transferState: .uploading)
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForANonImageMessageWithAsset_PreviewAndPreviewAssetId_WrongStates() {
        createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .done, transferState: .uploading)
        XCTAssertNil(sut.nextRequest())

        createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingFullAsset, transferState: .uploading)
        XCTAssertNil(sut.nextRequest())

        createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingFailed, transferState: .uploading)
        XCTAssertNil(sut.nextRequest())

        createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingFullAsset, transferState: .downloaded)
        XCTAssertNil(sut.nextRequest())

        createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingFailed, transferState: .uploaded)
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotCreateARequestForANonImageMessageWithAsset_UploadedAndAssetId_WrongStates() {
        createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .done, transferState: .uploading)
        XCTAssertNil(sut.nextRequest())

        createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFailed, transferState: .uploading)
        XCTAssertNil(sut.nextRequest())

        createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingThumbnail, transferState: .uploading)
        XCTAssertNil(sut.nextRequest())

        createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingThumbnail, transferState: .downloaded)
        XCTAssertNil(sut.nextRequest())

        createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingThumbnail, transferState: .uploaded)
        XCTAssertNil(sut.nextRequest())
    }

    // MARK: Response handling

    func testThatItMarksAnImageMessageAsSentWhenItReceivesASuccesfulResponse() {
        // given
        let message = createMessage(uploaded: true, assetId: true)
        let request = sut.assertCreatesValidRequestForAsset(in: conversation)!

        // when
        request.complete(withHttpStatus: 200)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssert(message.delivered)
        XCTAssertEqual(message.deliveryState, .sent)
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItMarksAnImageMessageAsSentWhenItReceivesASuccesfulResponse_Ephemeral() {
        // given
        conversation.messageDestructionTimeout = 15
        let message = createMessage(uploaded: true, assetId: true)
        guard let request = sut.nextRequest() else { return XCTFail("No request generated") }

        // when
        request.complete(withHttpStatus: 200)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssert(message.delivered)
        XCTAssertEqual(message.deliveryState, .sent)
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageWithoutThumbnailAfterUploadingTheOriginal() {
        // given
        let message = createMessage(isImage: false, uploadState: .uploadingPlaceholder)

        // when
        let request = sut.assertCreatesValidRequestForAsset(in: conversation)!
        request.complete(withHttpStatus: 200)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.uploadState, ZMAssetUploadState.uploadingFullAsset)
        XCTAssertEqual(message.transferState, .uploading)
        XCTAssertFalse(message.delivered)

        // No request should be generated until the full asset has been uploaded
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageWithThumbnailAfterUploadingTheOriginal() {
        // given
        let message = createMessage(isImage: false, preview: true, uploadState: .uploadingPlaceholder)
        syncMOC.zm_imageAssetCache.storeAssetData(message.nonce, format: .original, encrypted: false, data: mediumJPEGData())

        // when
        let request = sut.assertCreatesValidRequestForAsset(in: conversation)!
        request.complete(withHttpStatus: 200)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.uploadState, .uploadingThumbnail)
        XCTAssertEqual(message.transferState, .uploading)
        XCTAssertFalse(message.delivered)

        // No request should be generated until the full asset has been uploaded
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterUploadingTheThumbnail() {
        // given
        let message = createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingThumbnail)

        // when
        let request = sut.assertCreatesValidRequestForAsset(in: conversation)!
        request.complete(withHttpStatus: 200)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.uploadState, .uploadingFullAsset)
        XCTAssertEqual(message.transferState, .uploading)
        XCTAssertFalse(message.delivered)

        // No request should be generated until the full asset has been uploaded
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterUploadingTheFullAsset() {
        // given
        let message = createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset)

        // when
        let request = sut.assertCreatesValidRequestForAsset(in: conversation)!
        request.complete(withHttpStatus: 200)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.uploadState, .done)
        XCTAssertEqual(message.transferState, .downloaded)
        XCTAssertTrue(message.delivered)
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterUploadingTheFullAssetWithTheumbnail() {
        // given
        let message = createMessage(isImage: false, uploaded: true, preview: true, assetId: true, previewAssetId: true, uploadState: .uploadingFullAsset)

        // when
        let request = sut.assertCreatesValidRequestForAsset(in: conversation)!
        request.complete(withHttpStatus: 200)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.uploadState, .done)
        XCTAssertEqual(message.transferState, .downloaded)
        XCTAssertTrue(message.delivered)
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterUploadingTheNotUploaded() {
        // given
        let message = createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset)

        // when
        let uploadedRequest = sut.assertCreatesValidRequestForAsset(in: conversation)!
        uploadedRequest.complete(withHttpStatus: 400)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let notUploadedRequest = sut.assertCreatesValidRequestForAsset(in: conversation)!
        notUploadedRequest.complete(withHttpStatus: 200)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.uploadState, .uploadingFailed)
        XCTAssertEqual(message.transferState, .failedUpload)
        XCTAssertFalse(message.delivered)
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterFailingToSendTheThumbnail() {
        // given
        let message = createMessage(isImage: false, preview: true, previewAssetId: true, uploadState: .uploadingThumbnail)

        // when
        let thumbnailRequest = sut.assertCreatesValidRequestForAsset(in: conversation)!
        thumbnailRequest.complete(withHttpStatus: 400)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let notUploadedRequest = sut.assertCreatesValidRequestForAsset(in: conversation)!
        notUploadedRequest.complete(withHttpStatus: 200)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.uploadState, .uploadingFailed)
        XCTAssertEqual(message.transferState, .failedUpload)
        XCTAssertFalse(message.delivered)
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageAfterFailingToSendTheFullAsset() {
        // given
        let message = createMessage(isImage: false, uploaded: true, assetId: true, uploadState: .uploadingFullAsset)

        // when
        let uploadedRequest = sut.assertCreatesValidRequestForAsset(in: conversation)!
        uploadedRequest.complete(withHttpStatus: 400)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let notUploadedRequest = sut.assertCreatesValidRequestForAsset(in: conversation)!
        notUploadedRequest.complete(withHttpStatus: 200)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.uploadState, .uploadingFailed)
        XCTAssertEqual(message.transferState, .failedUpload)
        XCTAssertFalse(message.delivered)
        XCTAssertNil(sut.nextRequest())
    }

}
