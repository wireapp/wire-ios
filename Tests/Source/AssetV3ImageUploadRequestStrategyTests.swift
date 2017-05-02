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
import WireDataModel


class AssetV3ImageUploadRequestStrategyTests: MessagingTestBase {

    fileprivate var mockApplicationStatus : MockApplicationStatus!
    fileprivate var sut : AssetV3ImageUploadRequestStrategy!
    fileprivate var conversation: ZMConversation!
    fileprivate var imageData = mediumJPEGData()
    
    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .eventProcessing
        sut = AssetV3ImageUploadRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: mockApplicationStatus)
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
            message = self.conversation.appendMessage(withImageData: self.imageData) as! ZMAssetClientMessage
            self.syncMOC.saveOrRollback()
        }

        XCTAssertEqual(message.version, 3)
        return message
    }
    
    func createFileMessageWithPreview(ephemeral: Bool = false) -> ZMAssetClientMessage {
        var message: ZMAssetClientMessage!
        syncMOC.performGroupedBlockAndWait {
            self.conversation.messageDestructionTimeout = ephemeral ? 10 : 0
            let url = Bundle(for: AssetV3ImageUploadRequestStrategyTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!
            message = self.conversation.appendMessage(with: ZMFileMetadata(fileURL: url, thumbnail: nil)) as! ZMAssetClientMessage
            self.syncMOC.zm_imageAssetCache.storeAssetData(message.nonce, format: .original, encrypted: false, data: self.imageData)
            self.syncMOC.saveOrRollback()
        }

        XCTAssertEqual(message.version, 3)
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
    }
    
    // MARK: – Request Generation
    
    func testThatItDoesNotGenerateARequestWhenTheImageIsNotProcessed() {
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItGeneratesARequestIfTheImageIsProcessed() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.createImageFileMessage()
            
            // THEN
            self.assertThatItCreatesARequest(for: message)
        }
    }
    
    func testThatItGeneratesARequestForAFilePreviewImageIfThePreviewIsProcessed() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.createFileMessageWithPreview()
            message.uploadState = .uploadingThumbnail
            
            // THEN
            self.assertThatItCreatesARequest(for: message, preview: true)
        }
    }
    
    func testThatItDoesNotGeneratesARequestForAFilePreviewImageIfThePreviewIsProcessed_WrongUploadState() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.createFileMessageWithPreview()
            
            // WHEN
            self.simulatePreprocessing(of: message, preview: true)
            self.prepareUpload(of: message)
            
            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    @discardableResult func assertThatItCreatesARequest(
        for message: ZMAssetClientMessage,
        line: UInt = #line,
        preview: Bool = false
        ) -> ZMTransportRequest? {
        
        // WHEN
        simulatePreprocessing(of: message, preview: preview)
        prepareUpload(of: message)
        
        // THEN
        guard let request = sut.nextRequest() else { XCTFail("No request created", line: line); return nil }
        XCTAssertEqual(request.path, "/assets/v3", line: line)
        XCTAssertEqual(request.method, .methodPOST, line: line)
        return request
    }
    
    func testThatItPreprocessesTheImageAndDeletesTheOriginalDataAfterwards() {
        
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createImageFileMessage()
        }
        // THEN
        self.assertThatItPreprocessesTheImageAndDeletesTheOriginalDataAfterwards(for: message)
    }
    
    func testThatItPreprocessesThePreviewImageForANonImageFileMessageAndDeletesTheOriginalDataAfterwards() {

        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createFileMessageWithPreview()
        }
        
        // THEN
        self.assertThatItPreprocessesTheImageAndDeletesTheOriginalDataAfterwards(for: message, preview: true)
    }
    
    func assertThatItPreprocessesTheImageAndDeletesTheOriginalDataAfterwards(for message: ZMAssetClientMessage, preview: Bool = false, line: UInt = #line) {
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssert(ZMAssetClientMessage.v3_imageProcessingFilter.evaluate(with: message), "Predicate does not match", line: line)
            XCTAssertNil(self.syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true), line: line)
            XCTAssertNil(self.syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: false), line: line)
            
            self.sut.contextChangeTrackers.forEach {
                $0.objectsDidChange(Set(arrayLiteral: message))
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            let original = self.syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .original, encrypted: false)
            let mediumEncrypted = self.syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true)
            let mediumPlain = self.syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: false)
            
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
    }
    
    // MARK: – Request Response Parsing
    
    func testThatItUpdatesTheMessageWithTheAssetIdAndTokenFromTheResponse() {
        assertThatItUpdatesTheAssetIdFromTheResponse()
    }
    
    func testThatItUpdatesTheMessageWithTheAssetIdFromTheResponse() {
        assertThatItUpdatesTheAssetIdFromTheResponse(includeToken: false)
    }
    
    func assertThatItUpdatesTheAssetIdFromTheResponse(includeToken: Bool = true, line: UInt = #line) {
        // GIVEN
        var message: ZMAssetClientMessage!
        let (assetKey, token) = (UUID.create().transportString(), UUID.create().transportString())
        
        self.syncMOC.performGroupedBlockAndWait {
            
            message = self.createImageFileMessage()
            self.simulatePreprocessing(of: message)
            self.prepareUpload(of: message)
            
        }
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail("No request created", line: line) }
            XCTAssertEqual(request.path, "/assets/v3", line: line)
            var payload = ["key": assetKey]
            if includeToken {
                payload["token"] = token
            }
            let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 201, transportSessionError: nil)
            request.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            
            guard let uploaded = message.genericAssetMessage?.assetData?.uploaded else { return XCTFail("No uploaded message", line: line) }
            self.assertThatRemoteDataHasAssetId(uploaded, assetId: assetKey, token: includeToken ? token : nil)
        }
    }
    
    func testThatItUpdatesANonImageMessageWithPreviewTheAssetIdAndTokenFromTheResponse() {
        assertThatItUpdatesThePreviewAssetIdFromTheResponse()
    }
    
    func testThatItUpdatesANonImageMessageWithPreviewTheAssetIdFromTheResponse() {
        assertThatItUpdatesThePreviewAssetIdFromTheResponse(includeToken: false)
    }
    
    func assertThatItUpdatesThePreviewAssetIdFromTheResponse(includeToken: Bool = true, line: UInt = #line) {
        // GIVEN
        var message: ZMAssetClientMessage!
        let (assetKey, token) = (UUID.create().transportString(), UUID.create().transportString())
        
        self.syncMOC.performGroupedBlockAndWait {
            
            message = self.createFileMessageWithPreview()
            message.uploadState = .uploadingThumbnail
            self.simulatePreprocessing(of: message, preview: true)
            self.prepareUpload(of: message)
        }
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            
            guard let request = self.sut.nextRequest() else { return XCTFail("No request created", line: line) }
            XCTAssertEqual(request.path, "/assets/v3", line: line)
            var payload = ["key": assetKey]
            if includeToken {
                payload["token"] = token
            }
            let response = ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 201, transportSessionError: nil)
            request.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            
            guard let remote = message.genericAssetMessage?.assetData?.preview.remote else { return XCTFail("No preview.remote message", line: line) }
            self.assertThatRemoteDataHasAssetId(remote, assetId: assetKey, token: includeToken ? token : nil)
        }
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
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            
            message = self.createFileMessageWithPreview()
            message.uploadState = .uploadingThumbnail
        }
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            
            let request = self.assertThatItCreatesARequest(for: message, preview: true)!
            let payload = ["key": UUID.create().transportString()]
            request.complete(with: ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 201, transportSessionError: nil))
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.transferState, .uploading)
            XCTAssertEqual(message.uploadState, .uploadingThumbnail)
            XCTAssertFalse(message.delivered)
        }
    }
    
    func testThatItFailsTheUploadIfItReceivesANonSuccessfullResponseWhenUploadingANonImageFileMessage() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createFileMessageWithPreview()
            message.uploadState = .uploadingThumbnail
        }
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.assertThatItCreatesARequest(for: message, preview: true)!
            request.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 400, transportSessionError: NSError.tryAgainLaterError() as Error))
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.transferState, .failedUpload)
            XCTAssertEqual(message.uploadState, .uploadingFailed)
            XCTAssertEqual(message.deliveryState, .failedToSend)
        }
    }
    
    // MARK: – Ephemeral
    
    func testThatItGeneratesARequest_Ephemeral() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.createImageFileMessage(ephemeral: true)
            
            // THEN
            self.assertThatItCreatesARequest(for: message)
        }
    }
    
    func testThatItPreprocessesV3ImageMessage_Ephemeral() {
        
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createImageFileMessage(ephemeral: true)
        }
        // THEN
        self.assertThatItPreprocessesTheImageAndDeletesTheOriginalDataAfterwards(for: message)
    }
    
}


