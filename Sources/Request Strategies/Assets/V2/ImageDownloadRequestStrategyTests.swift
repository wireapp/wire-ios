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
@testable import WireRequestStrategy
import XCTest
import WireDataModel

class ImageDownloadRequestStrategyTests: MessagingTestBase {
    
    fileprivate var applicationStatus: MockApplicationStatus!
    
    fileprivate var sut: ImageDownloadRequestStrategy!
    
    override func setUp() {
        super.setUp()
        applicationStatus = MockApplicationStatus()
        sut = ImageDownloadRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: applicationStatus)
    }
    
    override func tearDown() {
        super.tearDown()
        applicationStatus = nil
        sut = nil
    }
    
    func createImageMessage(withAssetId assetId: UUID?) -> ZMAssetClientMessage {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        let message = conversation.append(imageFromData: verySmallJPEGData(), nonce: UUID.create()) as! ZMAssetClientMessage
        message.version = 0;
        let imageData = message.imageAssetStorage.originalImageData()
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size: imageSize, length: UInt(imageData!.count), mimeType: "image/jpeg")
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(), macKey: Data.zmRandomSHA256Key(), mac: Data.zmRandomSHA256Key())
        
        message.add(ZMGenericMessage.message(content: ZMImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: .medium), nonce: message.nonce!))
        message.add(ZMGenericMessage.message(content: ZMImageAsset(mediumProperties: properties, processedProperties: properties, encryptionKeys: keys, format: .preview), nonce: message.nonce!))
        
        message.resetLocallyModifiedKeys(["uploadedState"])
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
        let message = conversation.append(file: metadata, nonce: nonce) as! ZMAssetClientMessage
        
        syncMOC.saveOrRollback()
        
        return message
    }
    
    func requestToDownloadAsset(withMessage message: ZMAssetClientMessage) -> ZMTransportRequest {
        // remove image data or it won't be downloaded
        syncMOC.zm_fileAssetCache.deleteAssetData(message, format: .original, encrypted: false)
        message.imageMessageData?.requestImageDownload()
        return sut.nextRequest()!
    }
    
    func testRequestToDownloadAssetIsNotCreated_whenAssetIdIsNotAvailable() {
        // GIVEN
        self.syncMOC.performGroupedBlock {
            let message = self.createImageMessage(withAssetId: nil)
            
            // remove image data or it won't be downloaded
            self.syncMOC.zm_fileAssetCache.deleteAssetData(message, format: .original, encrypted: false)
            message.imageMessageData?.requestImageDownload()
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

    func testMessageIsDeleted_whenDownloadRequestFail() {
        let (nonce, conversation) = syncMOC.performGroupedAndWait { moc -> (UUID, ZMConversation) in
            // GIVEN
            let message = self.createImageMessage(withAssetId: UUID.create())
            let nonceAndConversation = (message.nonce!, message.conversation!)

            // WHEN
            let response = ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil)
            self.sut.delete(message, with: response, downstreamSync: nil)
            
            // THEN
            XCTAssert(message.isDeleted)
            return nonceAndConversation
        }
        
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        syncMOC.performGroupedAndWait { moc in
            // given
            let message = ZMMessage.fetch(withNonce: nonce, for: conversation, in: moc, prefetchResult: nil)
            
            // then
            XCTAssertNil(message)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
}
