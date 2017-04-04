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
import XCTest
import WireDataModel

class ImageDownloadRequestStrategyTests: MessagingTestBase {
    
    fileprivate var clientRegistrationStatus : MockClientRegistrationStatus!
    fileprivate var sut : ImageDownloadRequestStrategy!
    
    override func setUp() {
        super.setUp()
        
        self.clientRegistrationStatus = MockClientRegistrationStatus()
        self.sut = ImageDownloadRequestStrategy(clientRegistrationStatus: clientRegistrationStatus , managedObjectContext: self.syncMOC)        
    }
    
    func createImageMessage(withAssetId assetId: UUID?) -> ZMAssetClientMessage {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        let message = conversation.appendOTRMessage(withImageData: verySmallJPEGData(), nonce: UUID.create())
        
        let imageData = message.imageAssetStorage?.originalImageData()
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size: imageSize, length: UInt(imageData!.count), mimeType: "image/jpeg")
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(), macKey: Data.zmRandomSHA256Key(), mac: Data.zmRandomSHA256Key())
        
        message.add(ZMGenericMessage.genericMessage(
            mediumImageProperties: properties,
            processedImageProperties: properties,
            encryptionKeys: keys,
            nonce: message.nonce.transportString(),
            format: .medium,
            expiresAfter:nil))
        
        message.add(ZMGenericMessage.genericMessage(
            mediumImageProperties: properties,
            processedImageProperties: properties,
            encryptionKeys: keys,
            nonce: message.nonce.transportString(),
            format: .preview,
            expiresAfter:nil))
    
        message.resetLocallyModifiedKeys(Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey))
        message.assetId = assetId
        syncMOC.saveOrRollback()
        
        return message
    }
    
    func createFileMessage() -> ZMAssetClientMessage {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        
        let nonce = UUID.create()
        let fileURL = Bundle(for: ImageDownloadRequestStrategyTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!
        let metadata = ZMFileMetadata(fileURL: fileURL)
        let message = conversation.appendOTRMessage(with: metadata, nonce: nonce)
        
        syncMOC.saveOrRollback()
        
        return message
    }
    
    func requestToDownloadAsset(withMessage message: ZMAssetClientMessage) -> ZMTransportRequest {
        // remove image data or it won't be downloaded
        self.syncMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: .original, encrypted: false)
        
        message.requestImageDownload()
        
        return sut.nextRequest()!
    }
    
    func testRequestToDownloadAsset_whenAssetIdIsAvailable() {
        // GIVEN
        var assetId: UUID?
        var conversationId : UUID?
        
        self.syncMOC.performGroupedBlock {
            assetId = UUID.create()
            let message = self.createImageMessage(withAssetId: assetId!)
            conversationId = message.conversation!.remoteIdentifier
            
            // remove image data or it won't be downloaded
            self.syncMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: .original, encrypted: false)
            message.requestImageDownload()
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        guard let request = self.sut.nextRequest() else { XCTFail(); return }
        
        // THEN
        XCTAssertNotNil(request)
        XCTAssertEqual(request.path, "/conversations/\(conversationId!.transportString())/otr/assets/\(assetId!.transportString())")
    }
    
    func testRequestToDownloadAssetIsNotCreated_whenAssetIdIsNotAvailable() {
        // GIVEN
        self.syncMOC.performGroupedBlock {
            let message = self.createImageMessage(withAssetId: nil)
            
            // remove image data or it won't be downloaded
            self.syncMOC.zm_imageAssetCache.deleteAssetData(message.nonce, format: .original, encrypted: false)
            message.requestImageDownload()
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        let request = self.sut.nextRequest()
        
        // THEN
        XCTAssertNil(request)
    }
    
    func testRequestToDownloadFileAssetIsNotCreated() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let message = self.createFileMessage()
            message.transferState = .uploaded
            message.delivered = true
            message.assetId = UUID.create()
            
            // WHEN
            let request = self.sut.nextRequest()
            
            // THEN
            XCTAssertNil(request)
        }
        
         XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testMessageImageDataIsUpdated_whenParsingAssetDownloadResponse() {
        self.syncMOC.performGroupedBlock {
            // GIVEN
            let imageData = self.verySmallJPEGData()
            let message = self.createImageMessage(withAssetId: UUID.create())
            message.isEncrypted = false
            let response = ZMTransportResponse(imageData: imageData, httpStatus: 200, transportSessionError: nil, headers: nil)
            
            // WHEN
            self.sut.update(message, with: response, downstreamSync: nil)
            let storedData = message.imageAssetStorage?.imageData(for: .medium, encrypted: false)
            
            // THEN
            XCTAssertEqual(storedData, imageData)
            
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testMessageIsDeleted_whenDownloadRequestFail() {
        self.syncMOC.performGroupedBlock { 
            // GIVEN
            let message = self.createImageMessage(withAssetId: UUID.create())
            
            // WHEN
            self.sut.delete(message, downstreamSync: nil)
            
            // THEN
            XCTAssertTrue(message.isDeleted)
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
}
