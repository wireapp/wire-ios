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
import ZMCDataModel



class ImageUploadRequestStrategyTests: MessagingTestBase {
    
    fileprivate var clientRegistrationStatus : MockClientRegistrationStatus!
    fileprivate var sut : ImageUploadRequestStrategy!
    
    override func setUp() {
        super.setUp()
        self.clientRegistrationStatus = MockClientRegistrationStatus()
        self.sut = ImageUploadRequestStrategy(clientRegistrationStatus: clientRegistrationStatus, managedObjectContext: self.syncMOC)
    }
    
    /// MARK - Helpers
    
    func createImageMessage(isEphemeral: Bool = false) -> ZMAssetClientMessage {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        if isEphemeral {
            conversation.messageDestructionTimeout = 10;
        }
        let message = conversation.appendOTRMessage(withImageData: verySmallJPEGData(), nonce: UUID.create())
        syncMOC.saveOrRollback()
        
        return message
    }
    
    func prepare(_ message: ZMAssetClientMessage, forUploadingFormat format: ZMImageFormat) {
        let otherFormat : ZMImageFormat = format == .medium ? .preview : .medium
        
        let properties = ZMIImageProperties(size: message.imageAssetStorage!.originalImageSize(), length: 1000, mimeType: "image/jpg")
        message.imageAssetStorage?.setImageData(message.imageAssetStorage?.originalImageData(), for:format, properties: properties)
        message.imageAssetStorage?.setImageData(message.imageAssetStorage?.originalImageData(), for:otherFormat, properties: properties)
        message.uploadState = format == .medium ? .uploadingFullAsset : .uploadingPlaceholder
        
        syncMOC.saveOrRollback()
    }
        
    func assertRequestIsGeneratedToSendOTRAssetWhenAMessageIsInserted(withFormat format: ZMImageFormat, block: @escaping (_ message: ZMMessage) -> Void) {
        
        syncMOC.performGroupedBlock { 
            let message = self.createImageMessage()
            let conversationId = message.conversation!.remoteIdentifier!.transportString()
            
            self.prepare(message, forUploadingFormat: format)
            
            // WHEN
            block(message)
            let request = self.sut.nextRequest()
            
            // THEN
            let expectedPath = "/conversations/\(conversationId)/otr/assets"
            XCTAssertEqual(expectedPath, request?.path)
            
            let metadataItem = request?.multipartBodyItems()?.first as! ZMMultipartBodyItem
            let messageFromSync = self.sut.managedObjectContext.object(with: message.objectID) as! ZMAssetClientMessage
            let messageDataFromSync = messageFromSync.encryptedMessagePayloadForImageFormat(format)?.otrMessageData.data()
            
            XCTAssertEqual(metadataItem.data, messageDataFromSync)
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
 
    func testRequestIsGeneratedToSendAsset_whenOTRAssetIsInsertedOnInitialization() {
        assertRequestIsGeneratedToSendOTRAssetWhenAMessageIsInserted(withFormat: .medium) { (message) in
            ZMChangeTrackerBootstrap.bootStrapChangeTrackers(self.sut.contextChangeTrackers, on: self.syncMOC)
        }
    }
    
    func testRequestIsGeneratedToSendAsset_whenOTRAssetIsInsertedOnObjectsDidChange() {
        assertRequestIsGeneratedToSendOTRAssetWhenAMessageIsInserted(withFormat: .medium) { (message) in
            let messageFromSyncMoc = self.sut.managedObjectContext .object(with: message.objectID)
            
            for changeTracker in self.sut.contextChangeTrackers {
                changeTracker.objectsDidChange(Set(arrayLiteral: messageFromSyncMoc))
            }
        }
    }
        
    func assertMessageIsDeleted_whenFailedToCreatedUpdateRequestAndNoOriginalDataStored(_ format: ZMImageFormat) {
        syncMOC.performGroupedBlock {
            // GIVEN
            let message = self.createImageMessage()
            let properties = ZMIImageProperties(size: CGSize(width: 100, height: 100), length: UInt(100), mimeType: "")
            
            message.add(ZMGenericMessage.genericMessage(
                mediumImageProperties: properties,
                processedImageProperties: properties,
                encryptionKeys: nil,
                nonce: message.nonce.transportString(),
                format: format))
            
            // WHEN
            switch format {
            case .preview:
                message.uploadState = .uploadingPlaceholder
            case .medium:
                message.uploadState = .uploadingFullAsset
            default:
                break
            }
            
            _ = self.sut.request(forUpdating: message, forKeys: Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey))
            
            // THEN
            XCTAssertTrue(message.isZombieObject)
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testMessageIsDeleted_whenFailedToCreatedUpdateRequestForMediumFormatAndNoOriginalDataStored() {
        assertMessageIsDeleted_whenFailedToCreatedUpdateRequestAndNoOriginalDataStored(.medium)
    }
    
    func testMessageIsDeleted_whenFailedToCreatedUpdateRequestForPreviewFormatAndNoOriginalDataStored() {
        assertMessageIsDeleted_whenFailedToCreatedUpdateRequestAndNoOriginalDataStored(.preview)
    }
    
    func testNoRequestIsGenerated_whenProcessingIsNeeded() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let message = self.createImageMessage()
            self.prepare(message, forUploadingFormat: .medium)
            
            for changeTracker in self.sut.contextChangeTrackers {
                changeTracker.objectsDidChange(Set(arrayLiteral: message))
            }
            
            // WHEN
            message.managedObjectContext?.zm_imageAssetCache.deleteAssetData(message.nonce, format: .medium, encrypted: true)
            let request = self.sut.nextRequest()
            
            // THEN
            XCTAssertNil(request)
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testNeedsToUploadMediumKeyIsReset_whenParsingTheResponseForPreviewImage() {
        syncMOC.performGroupedBlock { 
            // GIVEN
            let key = ZMAssetClientMessageUploadedStateKey
            let message = self.createImageMessage()
            message.uploadState = .uploadingPlaceholder
            XCTAssertTrue(message.hasLocalModifications(forKey: key))
            
            let responsePayload = ["time" : Date().transportString()] as ZMTransportData
            let response = ZMTransportResponse(payload: responsePayload, httpStatus: 200, transportSessionError: nil)
            
            // WHEN
            _ = self.sut.updateUpdatedObject(message, requestUserInfo: nil, response: response, keysToParse: Set(arrayLiteral: key))
            
            // THEN
            XCTAssertTrue(message.hasLocalModifications(forKey: key))
            XCTAssertEqual(message.uploadState, ZMAssetUploadState.uploadingFullAsset)
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testAssetIdIsNotSet_whenParsingTheResponseForPreviewImage() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let message = self.createImageMessage()
            message.uploadState = .uploadingPlaceholder
            
            let responsePayload = ["time" : Date().transportString()] as ZMTransportData
            let response = ZMTransportResponse(payload: responsePayload, httpStatus: 200, transportSessionError: nil)
            
            // WHEN
            _ = self.sut.updateUpdatedObject(message, requestUserInfo: nil, response: response, keysToParse: Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey))
            
            // THEN
            XCTAssertNil(message.assetId)
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testNeedsToUploadMediumKeyIsReset_whenParsingTheResponseForMediumImage() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let key = ZMAssetClientMessageUploadedStateKey
            let message = self.createImageMessage()
            let assetId = UUID.create()
            message.uploadState = .uploadingFullAsset
            XCTAssertTrue(message.hasLocalModifications(forKey: key))
            
            let responsePayload = ["time" : Date().transportString()] as ZMTransportData
            let responseHeader = ["Location" : assetId.transportString()]
            let response = ZMTransportResponse(payload: responsePayload, httpStatus: 200, transportSessionError: nil, headers: responseHeader)
            
            // WHEN
            _ = self.sut.updateUpdatedObject(message, requestUserInfo: nil, response: response, keysToParse: Set(arrayLiteral: key))
            
            // THEN
            XCTAssertFalse(message.hasLocalModifications(forKey: key))
            XCTAssertEqual(message.uploadState, ZMAssetUploadState.done)
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testAssetIdIsSet_whenParsingTheResponseForMediumImage() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let message = self.createImageMessage()
            let assetId = UUID.create()
            message.uploadState = .uploadingFullAsset
            
            let responsePayload = ["time" : Date().transportString()] as ZMTransportData
            let responseHeader = ["Location" : assetId.transportString()]
            let response = ZMTransportResponse(payload: responsePayload, httpStatus: 200, transportSessionError: nil, headers: responseHeader)
            
            // WHEN
            _ = self.sut.updateUpdatedObject(message, requestUserInfo: nil, response: response, keysToParse: Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey))
            
            // THEN
            XCTAssertEqual(message.assetId, assetId)
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testKeysAreReset_whenRequestFailsBecauseSelfClientWasDeleted() {
        self.syncMOC.performGroupedBlock { 
            // GIVEN
            let keys = Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey)
            let message = self.createImageMessage()
            
            message.setLocallyModifiedKeys(keys)
            let request = ZMUpstreamRequest(transportRequest: ZMTransportRequest(getFromPath: "foo"))!
            
            // WHEN
            let response = ZMTransportResponse(payload: ["label" : "unknown-client"] as ZMTransportData, httpStatus: 403, transportSessionError: nil)
            _ = self.sut.shouldRetryToSyncAfterFailed(toUpdate: message, request: request, response: response, keysToParse: keys)
            
            // THEN
            XCTAssertEqual(message.uploadState, ZMAssetUploadState.uploadingFailed);
            XCTAssertTrue(message.hasLocalModifications(forKeys: keys))
            XCTAssertFalse(message.conversation!.needsToBeUpdatedFromBackend)
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
}


// MARK: - Ephemeral
extension ImageUploadRequestStrategyTests {
    
    
    func setupConversation(for message: ZMMessage) {
        message.conversation?.conversationType = .oneOnOne
        message.conversation?.connection = ZMConnection.insertNewObject(in: self.syncMOC)
        message.conversation?.connection?.to = ZMUser.insertNewObject(in: self.syncMOC)
        message.conversation?.connection?.to.remoteIdentifier = UUID()
    }
    
    func testThatItAddsEphemeralMessages(){
        syncMOC.performGroupedBlock {
            // GIVEN
            let message = self.createImageMessage(isEphemeral: true)
            self.setupConversation(for: message)
            
            XCTAssertTrue(message.isEphemeral)
            self.prepare(message, forUploadingFormat: .medium)
            
            for changeTracker in self.sut.contextChangeTrackers {
                changeTracker.objectsDidChange(Set(arrayLiteral: message))
            }
            
            // WHEN
            let request = self.sut.nextRequest()

            // THEN
            XCTAssertNotNil(request)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    
    }
    
    func testThatItPreprocessesEphemeralImageMessages(){
        syncMOC.performGroupedBlock {
            // GIVEN
            let message = self.createImageMessage(isEphemeral: true)
            self.setupConversation(for: message)
            XCTAssertTrue(message.isEphemeral)
            
            self.prepare(message, forUploadingFormat: .medium)
            
            for changeTracker in self.sut.contextChangeTrackers {
                changeTracker.objectsDidChange(Set(arrayLiteral: message))
            }
            
            // WHEN
            message.managedObjectContext?.zm_imageAssetCache.deleteAssetData(message.nonce, format: .medium, encrypted: true)
            XCTAssertFalse(self.sut.shouldCreateRequest(toSyncObject:message, forKeys:Set(arrayLiteral: "uploadState"), withSync: NSObject()))

            let properties = ZMIImageProperties(size: message.imageAssetStorage!.originalImageSize(), length: 1000, mimeType: "image/jpg")
            message.imageAssetStorage?.setImageData(message.imageAssetStorage?.originalImageData(), for:.medium, properties: properties)
            
            // THEN
            XCTAssertTrue(self.sut.shouldCreateRequest(toSyncObject:message, forKeys:Set(arrayLiteral: "uploadState"), withSync: NSObject()))
            XCTAssertTrue(message.isEphemeral)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

    }

}
