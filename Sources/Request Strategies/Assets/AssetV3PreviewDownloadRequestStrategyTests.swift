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
@testable import WireRequestStrategy


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
    
    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        conversation = nil

        super.tearDown()
    }
    
    fileprivate func createConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        return conversation
    }
    
    fileprivate func createMessage(in conversation: ZMConversation) -> (message: ZMAssetClientMessage, assetId: String, assetToken: String)? {
        
        let message = conversation.append(file: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
        let (otrKey, sha) = (Data.randomEncryptionKey(), Data.randomEncryptionKey())
        let (assetId, token) = (UUID.create().transportString(), UUID.create().transportString())
        let uploaded = ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: otrKey, sha256: sha), nonce: message.nonce!, expiresAfter: conversation.messageDestructionTimeoutValue)
        
        guard let uploadedWithId = uploaded.updatedUploaded(withAssetId: assetId, token: token) else {
            XCTFail("Failed to update asset")
            return nil
        }
        
        message.add(uploadedWithId)
        message.updateTransferState(.uploaded, synchronize: false)
        syncMOC.saveOrRollback()
        
        return (message, assetId, token)
    }
    
    func createPreview(with nonce: UUID, otr: Data = .randomEncryptionKey(), sha: Data = .randomEncryptionKey()) -> (genericMessage: ZMGenericMessage, meta: PreviewMeta) {
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
        return (ZMGenericMessage.message(content: assetBuilder!.build(), nonce: nonce), previewMeta)
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
            let (previewGenericMessage, _) = self.createPreview(with: message.nonce!)
            
            message.add(previewGenericMessage)
            XCTAssertFalse(message.hasDownloadedPreview)
            
            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItGeneratesARequestForAV3FileMessageWithPreviewThatHasNotBeenDownloadedYet() {
        // GIVEN
        var previewMeta: AssetV3PreviewDownloadRequestStrategyTests.PreviewMeta!
        self.syncMOC.performGroupedBlockAndWait {
            
            let (message, _, _) = self.createMessage(in: self.conversation)!
            let preview = self.createPreview(with: message.nonce!)
            previewMeta = preview.meta
            message.add(preview.genericMessage)
            XCTAssertFalse(message.hasDownloadedPreview)
            
            // WHEN
            message.fileMessageData?.requestImagePreviewDownload()
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
            let preview = self.createPreview(with: message.nonce!)
            previewMeta = preview.meta
            message.add(preview.genericMessage)
            
            // WHEN
            message.fileMessageData?.requestImagePreviewDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated") }
            XCTAssertEqual(request.path, "/assets/v3/\(previewMeta.assetId)")
            XCTAssertEqual(request.method, .methodGET)
            
            // WHEN
            message.fileMessageData?.requestImagePreviewDownload()
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
            previewGenericMessage = self.createPreview(with: message.nonce!).genericMessage
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, format: .medium, encrypted: false, data: .secureRandomData(length: 42))
            
            message.add(previewGenericMessage)
            message.fileMessageData?.requestImagePreviewDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(message.hasDownloadedFile)
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
            let (previewGenericMessage, _) = self.createPreview(with: message.nonce!, otr: key, sha: sha)
        
            message.add(previewGenericMessage)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            message.fileMessageData?.requestImagePreviewDownload()
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
            let data = self.syncMOC.zm_fileAssetCache.assetData(message, format: .medium, encrypted: false)
            XCTAssertEqual(data, plainTextData)
            XCTAssertEqual(message.fileMessageData!.previewData, plainTextData)
        }
    }
    
}
