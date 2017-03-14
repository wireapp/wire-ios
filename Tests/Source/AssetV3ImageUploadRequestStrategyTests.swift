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
@testable import WireMessageStrategy
import WireRequestStrategy
import XCTest
import ZMCDataModel


class AssetV3ImageUploadRequestStrategyTests: MessagingTestBase {

    fileprivate var registrationStatus: MockClientRegistrationStatus!
    fileprivate var mockCancellationProvider: MockTaskCancellationProvider!
    fileprivate var sut : AssetV3ImageUploadRequestStrategy!
    fileprivate var conversation: ZMConversation!
    fileprivate var imageData = mediumJPEGData()

    override func setUp() {
        super.setUp()
        registrationStatus = MockClientRegistrationStatus()
        mockCancellationProvider = MockTaskCancellationProvider()
        sut = AssetV3ImageUploadRequestStrategy(clientRegistrationStatus: registrationStatus, taskCancellationProvider: mockCancellationProvider, managedObjectContext: syncMOC)
        self.syncMOC.performGroupedBlockAndWait {
            self.conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation.remoteIdentifier = UUID.create()
        }
    }

    // MARK: - Helpers

    func createImageFileMessage(ephemeral: Bool = false) -> ZMAssetClientMessage {
        var message: ZMAssetClientMessage!
        syncMOC.performGroupedBlockAndWait {
            self.conversation.messageDestructionTimeout = ephemeral ? 10 : 0
            message = self.conversation.appendMessage(withImageData: self.imageData, version3: true) as! ZMAssetClientMessage
            self.syncMOC.saveOrRollback()
        }
        return message
    }

    func createFileMessageWithPreview(ephemeral: Bool = false) -> ZMAssetClientMessage {
        var message: ZMAssetClientMessage!
        syncMOC.performGroupedBlockAndWait {
            self.conversation.messageDestructionTimeout = ephemeral ? 10 : 0
            let url = Bundle(for: AssetV3ImageUploadRequestStrategyTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!
            message = self.conversation.appendMessage(with: ZMFileMetadata(fileURL: url, thumbnail: nil), version3: true) as! ZMAssetClientMessage
            self.syncMOC.zm_imageAssetCache.storeAssetData(message.nonce, format: .original, encrypted: false, data: self.imageData)
            self.syncMOC.saveOrRollback()
        }
        return message
    }

    func createPreprocessedV2ImageMessage() -> ZMAssetClientMessage {
        var message: ZMAssetClientMessage!
        syncMOC.performGroupedBlockAndWait {
            message = self.conversation.appendOTRMessage(withImageData: self.verySmallJPEGData(), nonce: .create(), version3: false)
            let properties = ZMIImageProperties(size: message.imageAssetStorage!.originalImageSize(), length: 1000, mimeType: "image/jpg")
            message.imageAssetStorage?.setImageData(message.imageAssetStorage?.originalImageData(), for: .medium, properties: properties)
            message.imageAssetStorage?.setImageData(message.imageAssetStorage?.originalImageData(), for: .preview, properties: properties)
            self.syncMOC.saveOrRollback()
        }
        return message
    }

    func simulatePreprocessing(of message: ZMAssetClientMessage, preview: Bool = false) {
        let size = CGSize(width: 368, height: 520)
        let properties = ZMIImageProperties(size: size, length: 1024, mimeType: "image/jpg")
        message.imageAssetStorage?.setImageData(imageData, for: .medium, properties: properties)
        if !preview {
            XCTAssertEqual(message.mimeType, "image/jpg")
            XCTAssertEqual(message.size, 1024)
            XCTAssertEqual(message.imageMessageData?.originalSize, size)
        }
    }

    func prepareUpload(of message: ZMAssetClientMessage) {
        ZMChangeTrackerBootstrap.bootStrapChangeTrackers(sut.contextChangeTrackers, on: syncMOC)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: – Request Generation

    func testThatItDoesNotGenerateARequestWhenTheImageIsNotProcessed() {
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItDoesNotGenerateARequestIfTheImageIsProcessedButTheMessageIsNotV3() {
        // given
        let message = createPreprocessedV2ImageMessage()

        // then
        prepareUpload(of: message)
        XCTAssertNil(sut.nextRequest())

        // when
        message.uploadState = .uploadingFullAsset

        // then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItGeneratesARequestIfTheImageIsProcessed() {
        // given
        let message = self.createImageFileMessage()
        
        // then
        self.assertThatItCreatesARequest(for: message)
    }

    func testThatItGeneratesARequestForAFilePreviewImageIfThePreviewIsProcessed() {
        // given
        let message = createFileMessageWithPreview()
        message.uploadState = .uploadingThumbnail

        // then
        assertThatItCreatesARequest(for: message, preview: true)
    }

    func testThatItDoesNotGeneratesARequestForAFilePreviewImageIfThePreviewIsProcessed_WrongUploadState() {
        // given
        let message = createFileMessageWithPreview()

        // when
        simulatePreprocessing(of: message, preview: true)
        prepareUpload(of: message)

        // then
        XCTAssertNil(sut.nextRequest())
    }

    @discardableResult func assertThatItCreatesARequest(
        for message: ZMAssetClientMessage,
        line: UInt = #line,
        preview: Bool = false
        ) -> ZMTransportRequest? {

        // when
        simulatePreprocessing(of: message, preview: preview)
        prepareUpload(of: message)

        // then
        guard let request = sut.nextRequest() else { XCTFail("No request created", line: line); return nil }
        XCTAssertEqual(request.path, "/assets/v3", line: line)
        XCTAssertEqual(request.method, .methodPOST, line: line)
        return request
    }

    func testThatItPreprocessesTheImageAndDeletesTheOriginalDataAfterwards() {
        // given
        let message = createImageFileMessage()

        // then
        assertThatItPreprocessesTheImageAndDeletesTheOriginalDataAfterwards(for: message)
    }

    func testThatItPreprocessesThePreviewImageForANonImageFileMessageAndDeletesTheOriginalDataAfterwards() {
        // given
        let message = createFileMessageWithPreview()

        // then
        assertThatItPreprocessesTheImageAndDeletesTheOriginalDataAfterwards(for: message, preview: true)
    }

    func assertThatItPreprocessesTheImageAndDeletesTheOriginalDataAfterwards(for message: ZMAssetClientMessage, preview: Bool = false, line: UInt = #line) {
        // when 
        XCTAssert(ZMAssetClientMessage.v3_imageProcessingFilter.evaluate(with: message), "Predicate does not match", line: line)
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true), line: line)
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: false), line: line)

        sut.contextChangeTrackers.forEach {
            $0.objectsDidChange(Set(arrayLiteral: message))
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), line: line)

        // then
        let original = syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .original, encrypted: false)
        let mediumEncrypted = syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true)
        let mediumPlain = syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: false)

        XCTAssertNil(original, line: line)
        XCTAssertNotNil(mediumEncrypted, line: line)
        XCTAssertNotNil(mediumPlain, line: line)
        guard let assetData = message.genericAssetMessage?.assetData else { return XCTFail("No assetData", line: line) }

        if preview {
            XCTAssertTrue(assetData.hasPreview(), line: line)
            XCTAssertTrue(assetData.preview.hasRemote(), line: line)
            XCTAssertTrue(assetData.preview.remote.hasOtrKey(), line: line)
            XCTAssertTrue(assetData.preview.remote.hasSha256(), line: line)
        } else {
            XCTAssertTrue(assetData.hasUploaded(), line: line)
            XCTAssertTrue(assetData.uploaded.hasOtrKey(), line: line)
            XCTAssertTrue(assetData.uploaded.hasSha256(), line: line)
        }
    }

    // MARK: – Request Response Parsing

    func testThatItUpdatesTheMessageWithTheAssetIdAndTokenFromTheResponse() {
        assertThatItUpdatesTheAssetIdFromTheResponse()
    }

    func testThatItUpdatesTheMessageWithTheAssetIdFromTheResponse() {
        assertThatItUpdatesTheAssetIdFromTheResponse(includeToken: false)
    }

    func assertThatItUpdatesTheAssetIdFromTheResponse(includeToken: Bool = true, line: UInt = #line) {
        // given
        let message = createImageFileMessage()
        let (assetKey, token) = (UUID.create().transportString(), UUID.create().transportString())
        simulatePreprocessing(of: message)
        prepareUpload(of: message)
        guard let request = sut.nextRequest() else { return XCTFail("No request created", line: line) }
        XCTAssertEqual(request.path, "/assets/v3", line: line)

        // when
        var payload = ["key": assetKey]
        if includeToken {
            payload["token"] = token
        }
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 201, transportSessionError: nil)
        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let uploaded = message.genericAssetMessage?.assetData?.uploaded else { return XCTFail("No uploaded message", line: line) }
        assertThatRemoteDataHasAssetId(uploaded, assetId: assetKey, token: includeToken ? token : nil)
    }

    func testThatItUpdatesANonImageMessageWithPreviewTheAssetIdAndTokenFromTheResponse() {
        assertThatItUpdatesThePreviewAssetIdFromTheResponse()
    }

    func testThatItUpdatesANonImageMessageWithPreviewTheAssetIdFromTheResponse() {
        assertThatItUpdatesThePreviewAssetIdFromTheResponse(includeToken: false)
    }

    func assertThatItUpdatesThePreviewAssetIdFromTheResponse(includeToken: Bool = true, line: UInt = #line) {
        // given
        let message = createFileMessageWithPreview()
        message.uploadState = .uploadingThumbnail
        let (assetKey, token) = (UUID.create().transportString(), UUID.create().transportString())
        simulatePreprocessing(of: message, preview: true)
        prepareUpload(of: message)
        guard let request = sut.nextRequest() else { return XCTFail("No request created", line: line) }
        XCTAssertEqual(request.path, "/assets/v3", line: line)

        // when
        var payload = ["key": assetKey]
        if includeToken {
            payload["token"] = token
        }
        let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 201, transportSessionError: nil)
        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let remote = message.genericAssetMessage?.assetData?.preview.remote else { return XCTFail("No preview.remote message", line: line) }
        assertThatRemoteDataHasAssetId(remote, assetId: assetKey, token: includeToken ? token : nil)
    }

    func assertThatRemoteDataHasAssetId(_ remote: ZMAssetRemoteData, assetId: String, token: String? = nil, line: UInt = #line) {
        XCTAssertTrue(remote.hasOtrKey(), "No OTR key", line: line)
        XCTAssertTrue(remote.hasSha256(), "No sha", line: line)
        XCTAssertTrue(remote.hasAssetId(), "No assetId", line: line)
        XCTAssertEqual(remote.hasAssetToken(), token != nil, "Token existence not matching", line: line)
        XCTAssertEqual(remote.assetId, assetId, "Wrong asset ID", line: line)
        if let token = token {
            XCTAssertEqual(remote.assetToken, token, "Wrong asset token", line: line)
        }
    }

    func testThatItUpdatesTheStateOfANonImageFileMessageWhenItReceivesASuccesfulResponse() {
        // given
        let message = createFileMessageWithPreview()
        message.uploadState = .uploadingThumbnail

        // when
        let request = assertThatItCreatesARequest(for: message, preview: true)!
        let payload = ["key": UUID.create().transportString()]
        request.complete(with: ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 201, transportSessionError: nil))
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.transferState, .uploading)
        XCTAssertEqual(message.uploadState, .uploadingThumbnail)
        XCTAssertFalse(message.delivered)
    }

    func testThatItFailsTheUploadIfItReceivesANonSuccessfullResponseWhenUploadingANonImageFileMessage() {
        // given
        let message = createFileMessageWithPreview()
        message.uploadState = .uploadingThumbnail

        // when
        let request = assertThatItCreatesARequest(for: message, preview: true)!
        request.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 400, transportSessionError: NSError.tryAgainLaterError() as Error))
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.transferState, .failedUpload)
        XCTAssertEqual(message.uploadState, .uploadingFailed)
        XCTAssertEqual(message.deliveryState, .failedToSend)
    }

    // MARK: – Ephemeral

    func testThatItGeneratesARequest_Ephemeral() {
        // given
        let message = createImageFileMessage(ephemeral: true)

        // then
        assertThatItCreatesARequest(for: message)
    }

    func testThatItPreprocessesV3ImageMessage_Ephemeral() {
        // given
        let message = createImageFileMessage(ephemeral: true)

        // then
        assertThatItPreprocessesTheImageAndDeletesTheOriginalDataAfterwards(for: message)
    }

}


