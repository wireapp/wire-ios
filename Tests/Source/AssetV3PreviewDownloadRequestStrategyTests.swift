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
import WireDataModel
import WireTesting
@testable import WireMessageStrategy


private let testDataURL = Bundle(for: AssetV3PreviewDownloadRequestStrategyTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!


class AssetV3PreviewDownloadRequestStrategyTests: MessagingTestBase {

    var mockApplicationStatus : MockApplicationStatus!
    var sut: AssetV3PreviewDownloadRequestStrategy!
    var conversation: ZMConversation!
    
    typealias PreviewMeta = (otr: Data, sha: Data, assetId: String, token: String)
    
    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .eventProcessing
        self.syncMOC.performGroupedBlockAndWait {
            self.sut = AssetV3PreviewDownloadRequestStrategy(withManagedObjectContext: self.syncMOC, applicationStatus: self.mockApplicationStatus)
            self.conversation = self.createConversation()
        }
    }
    
    fileprivate func createConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        return conversation
    }
    
    fileprivate func createMessage(in conversation: ZMConversation) -> (message: ZMAssetClientMessage, assetId: String, assetToken: String)? {
        
        let message = conversation.appendMessage(with: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
        let (otrKey, sha) = (Data.randomEncryptionKey(), Data.randomEncryptionKey())
        let (assetId, token) = (UUID.create().transportString(), UUID.create().transportString())
        
        // TODO: We should replace this manual update with inserting a v3 asset as soon as we have sending support
        let uploaded = ZMGenericMessage.genericMessage(
            withUploadedOTRKey: otrKey,
            sha256: sha,
            messageID: message.nonce.transportString(),
            expiresAfter: NSNumber(value: conversation.messageDestructionTimeout)
        )
        
        guard let uploadedWithId = uploaded.updatedUploaded(withAssetId: assetId, token: token) else {
            XCTFail("Failed to update asset")
            return nil
        }
        
        message.add(uploadedWithId)
        message.fileMessageData?.transferState = .downloading
        
        prepareDownload(of: message)
        return (message, assetId, token)
    }
    
    func prepareDownload(of message: ZMAssetClientMessage) {
        syncMOC.saveOrRollback()
        
        sut.contextChangeTrackers.forEach { tracker in
            tracker.objectsDidChange(Set(arrayLiteral: message))
        }
    }
    
    func createPreview(with nonce: String, otr: Data = .randomEncryptionKey(), sha: Data = .randomEncryptionKey()) -> (genericMessage: ZMGenericMessage, meta: PreviewMeta) {
        let (assetId, token) = (UUID.create().transportString(), UUID.create().transportString())
        let assetBuilder = ZMAsset.builder()
        let previewBuilder = ZMAssetPreview.builder()
        let remoteBuilder = ZMAssetRemoteData.builder()
        
        _ = remoteBuilder?.setOtrKey(otr)
        _ = remoteBuilder?.setSha256(sha)
        _ = remoteBuilder?.setAssetId(assetId)
        _ = remoteBuilder?.setAssetToken(token)
        _ = previewBuilder?.setSize(512)
        _ = previewBuilder?.setMimeType("image/jpg")
        _ = previewBuilder?.setRemote(remoteBuilder)
        _ = assetBuilder?.setPreview(previewBuilder)
        
        let previewMeta = (otr, sha, assetId, token)
        return (ZMGenericMessage.genericMessage(asset: assetBuilder!.build(), messageID: nonce), previewMeta)
    }
    
    func testThatItGeneratesNoRequestsIfTheStatusIsEmpty() {
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItGeneratesNoRequestsIfNotAuthenticated() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            self.mockApplicationStatus.mockSynchronizationState = .unauthenticated
            let _ = self.createMessage(in: self.conversation)
            
            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItGeneratesNoRequestForAV3FileMessageWithPreviewThatHasNotBeenDownloadedYet_WhenNotWhitelisted() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let (message, _, _) = self.createMessage(in: self.conversation)!
            let (previewGenericMessage, previewMeta) = self.createPreview(with: message.nonce.transportString())
            
            message.add(previewGenericMessage)
            self.prepareDownload(of: message)
            
            guard let asset = message.genericAssetMessage?.assetData else { return XCTFail() }
            XCTAssertTrue(asset.hasPreview())
            XCTAssertTrue(asset.preview.hasRemote())
            XCTAssertTrue(asset.preview.remote.hasAssetId())
            XCTAssertEqual(asset.preview.remote.assetId, previewMeta.assetId)
            XCTAssertFalse(message.hasDownloadedImage)
            XCTAssertEqual(message.version, 3)
            XCTAssertNotNil(message.fileMessageData)
            
            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItGeneratesARequestForAV3FileMessageWithPreviewThatHasNotBeenDownloadedYet() {
        // GIVEN
        var previewMeta: AssetV3PreviewDownloadRequestStrategyTests.PreviewMeta!
        self.syncMOC.performGroupedBlockAndWait {
            
            let (message, _, _) = self.createMessage(in: self.conversation)!
            let preview = self.createPreview(with: message.nonce.transportString())
            previewMeta = preview.meta
            message.add(preview.genericMessage)
            self.prepareDownload(of: message)
            
            guard let asset = message.genericAssetMessage?.assetData else { return XCTFail() }
            XCTAssertTrue(asset.hasPreview())
            XCTAssertTrue(asset.preview.hasRemote())
            XCTAssertTrue(asset.preview.remote.hasAssetId())
            XCTAssertEqual(asset.preview.remote.assetId, previewMeta.assetId)
            XCTAssertFalse(message.hasDownloadedImage)
            XCTAssertEqual(message.version, 3)
            XCTAssertNotNil(message.fileMessageData)
            
            // WHEN
            message.requestImageDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated") }
            
            // THEN
            XCTAssertEqual(request.path, "/assets/v3/\(previewMeta.assetId)")
            XCTAssertEqual(request.method, .methodGET)
        }
    }
    
    func testThatItDoesNotGenerateARequestForAV3FileMessageWithPreviewTwice() {
        // GIVEN
        var message: ZMAssetClientMessage!
        var previewMeta: AssetV3PreviewDownloadRequestStrategyTests.PreviewMeta!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(in: self.conversation)!.message
            let preview = self.createPreview(with: message.nonce.transportString())
            previewMeta = preview.meta
            
            message.add(preview.genericMessage)
            self.prepareDownload(of: message)
            
            // WHEN
            message.requestImageDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated") }
            XCTAssertEqual(request.path, "/assets/v3/\(previewMeta.assetId)")
            XCTAssertEqual(request.method, .methodGET)
            
            // WHEN
            message.requestImageDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItDoesNotGenerateAReuqestForAV3FileMessageWithPreviewThatAlreadyHasBeenDownloaded() {
        // GIVEN
        var message: ZMAssetClientMessage!
        var previewGenericMessage: ZMGenericMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(in: self.conversation)!.message
            previewGenericMessage = self.createPreview(with: message.nonce.transportString()).genericMessage
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.zm_imageAssetCache.storeAssetData(message.nonce, format: .medium, encrypted: false, data: .secureRandomData(length: 42))
            
            message.add(previewGenericMessage)
            self.prepareDownload(of: message)
            message.requestImageDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(message.hasDownloadedImage)
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItStoresAndDecryptsTheRawDataInTheImageCacheWhenItReceivesAResponse() {
        // GIVEN
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createMessage(in: self.conversation)!.message
            let (previewGenericMessage, _) = self.createPreview(with: message.nonce.transportString(), otr: key, sha: sha)
        
            message.add(previewGenericMessage)
            self.prepareDownload(of: message)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            message.requestImageDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated") }
            let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: nil, headers: nil)
            
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            let data = self.syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: false)
            XCTAssertEqual(data, plainTextData)
            XCTAssertEqual(message.fileMessageData!.previewData, plainTextData)
        }
    }
    
}
