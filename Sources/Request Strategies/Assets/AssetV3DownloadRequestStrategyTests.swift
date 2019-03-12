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


private let testDataURL = Bundle(for: AssetV3DownloadRequestStrategyTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!


public class MockTaskCancellationProvider: NSObject, ZMRequestCancellation {

    var cancelledIdentifiers = [ZMTaskIdentifier]()

    public func cancelTask(with identifier: ZMTaskIdentifier) {
        cancelledIdentifiers.append(identifier)
    }

    deinit {
        cancelledIdentifiers.removeAll()
    }
}


class AssetV3DownloadRequestStrategyTests: MessagingTestBase {

    var mockApplicationStatus: MockApplicationStatus!
    var sut: AssetV3DownloadRequestStrategy!
    var conversation: ZMConversation!
    var user: ZMUser!

    override func setUp() {
        super.setUp()
        
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .eventProcessing
        sut = AssetV3DownloadRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: mockApplicationStatus)
        
        self.syncMOC.performGroupedBlockAndWait {
            self.user = self.createUser(alsoCreateClient: true)
            self.conversation = self.createGroupConversation(with: self.user)
        }
    }
    
    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        user = nil
        conversation = nil
        super.tearDown()
    }
    
    fileprivate func createFileMessageWithAssetId(
        in aConversation: ZMConversation,
        otrKey: Data = Data.randomEncryptionKey(),
        sha: Data  = Data.randomEncryptionKey()
        ) -> (message: ZMAssetClientMessage, assetId: String, assetToken: String)? {

        let message = aConversation.append(file: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
        let (assetId, token) = (UUID.create().transportString(), UUID.create().transportString())
        let uploaded = ZMGenericMessage.message(content: ZMAsset.asset(withUploadedOTRKey: otrKey, sha256: sha), nonce: message.nonce!, expiresAfter: aConversation.messageDestructionTimeoutValue)

        guard let uploadedWithId = uploaded.updatedUploaded(withAssetId: assetId, token: token) else {
            XCTFail("Failed to update asset")
            return nil
        }
        
        message.updateTransferState(.uploaded, synchronize: false)
        message.add(uploadedWithId)
        deleteDownloadedFileFor(message: message)
        XCTAssertEqual(message.version, 3)
        syncMOC.saveOrRollback()
        return (message, assetId, token)
    }

    fileprivate func deleteDownloadedFileFor(message: ZMAssetClientMessage) {
        contextDirectory.uiContext.zm_fileAssetCache.deleteAssetData(message)
        contextDirectory.syncContext.zm_fileAssetCache.deleteAssetData(message)
    }
    
    func testThatItMarksMessageAsDownloading_WhenRequestingFileDownload() {
        
        var assetMessage: ZMAssetClientMessage!
        syncMOC.performGroupedBlockAndWait {
            
            // Given
            guard let (message, _, _) = self.createFileMessageWithAssetId(in: self.conversation) else { return XCTFail("No message") }
            assetMessage = message
            
            // When
            message.requestFileDownload()
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        syncMOC.performGroupedBlockAndWait {
            // Then
            XCTAssertTrue(assetMessage.isDownloading)
        }
    }
    
    func testThatItDoesNotMarksMessageAsDownloading_WhenRequestingFileDownloadIfFileIsAlreadyDownloaded() {
        
        var assetMessage: ZMAssetClientMessage!
        syncMOC.performGroupedBlockAndWait {
            
            // Given
            guard let (message, _, _) = self.createFileMessageWithAssetId(in: self.conversation) else { return XCTFail("No message") }
            self.syncMOC.zm_fileAssetCache.storeAssetData(message, encrypted: false, data: Data())
            assetMessage = message
            
            // When
            message.requestFileDownload()
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        syncMOC.performGroupedBlockAndWait {
            // Then
            XCTAssertFalse(assetMessage.isDownloading)
        }
    }

    func testThatItGeneratesARequestToTheV3EndpointIfTheProtobufContainsAnAssetID_V3() {
        
        var expectedAssetId: String = ""
        syncMOC.performGroupedBlockAndWait {
        
            // Given
            guard let (message, assetId, token) = self.createFileMessageWithAssetId(in: self.conversation) else { return XCTFail("No message") }
            guard let assetData = message.genericAssetMessage?.assetData else { return XCTFail("No assetData found") }
            
            expectedAssetId = assetId
            XCTAssert(assetData.hasUploaded())
            XCTAssertEqual(assetData.uploaded.assetId, assetId)
            XCTAssertEqual(assetData.uploaded.assetToken, token)
            message.requestFileDownload()
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        syncMOC.performGroupedBlockAndWait {
            // When
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated") }
            
            // Then
            XCTAssertEqual(request.method, .methodGET)
            XCTAssertEqual(request.path, "/assets/v3/\(expectedAssetId)")
            XCTAssert(request.needsAuthentication)
        }
    }

    func testThatItGeneratesARequestToTheV3EndpointITheProtobufContainsAnAssetID_EphemeralConversation_V3() {
        
        var expectedAssetId: String = ""
        syncMOC.performGroupedBlockAndWait {
            
            // Given
            self.conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 5))
            guard let (message, assetId, token) = self.createFileMessageWithAssetId(in: self.conversation) else { return XCTFail("No message") }
            guard let assetData = message.genericAssetMessage?.assetData else { return XCTFail("No assetData found") }
            
            expectedAssetId = assetId
            XCTAssert(assetData.hasUploaded())
            XCTAssertEqual(assetData.uploaded.assetId, assetId)
            XCTAssertEqual(assetData.uploaded.assetToken, token)
            XCTAssert(message.genericAssetMessage!.hasEphemeral())
            message.requestFileDownload()
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        syncMOC.performGroupedBlockAndWait {
            // When
            guard let request = self.sut.nextRequest() else { return XCTFail("No request generated") }
            
            // Then
            XCTAssertEqual(request.method, .methodGET)
            XCTAssertEqual(request.path, "/assets/v3/\(expectedAssetId)")
            XCTAssert(request.needsAuthentication)
        }
    }

    func testThatItGeneratesNoRequestsIfMessageIsUploading_V3() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            guard let (message , _, _) = self.createFileMessageWithAssetId(in: self.conversation) else { return XCTFail() } // V3
            message.updateTransferState(.uploading, synchronize: false)
            message.requestFileDownload()
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertNil(self.sut.nextRequest())
        }
    }

}

// tests on result of request
extension AssetV3DownloadRequestStrategyTests {

    func testThatItMarksDownloadAsSuccessIfSuccessfulDownloadAndDecryption_V3() {
        // GIVEN
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        
        var message: ZMMessage!
        self.syncMOC.performGroupedBlockAndWait {
            let sha = encryptedData.zmSHA256Digest()
            let (msg, _, _) = self.createFileMessageWithAssetId(in: self.conversation, otrKey: key, sha: sha)!
            msg.requestFileDownload()
            message = msg
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])
            
            // WHEN
            request?.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertEqual(message.fileMessageData?.downloadState, .downloaded)
        }
    }

    func testThatItDeletesMessageIfItCannotDownload_PermanentError_V3() {
        let message: ZMAssetClientMessage = syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let (msg, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            msg.requestFileDownload()
            return msg
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 404, transportSessionError: .none)
            
            // WHEN
            request?.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertTrue(message.isZombieObject)
        }
    }

    func testThatItMarksDownloadAsFailedIfCannotDownload_TemporaryError_V3() {
        let message: ZMAssetClientMessage = syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let (msg, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            msg.requestFileDownload()
            return msg
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 500, transportSessionError: nil)

            // WHEN
            request?.complete(with: response)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertEqual(message.fileMessageData?.downloadState, .remote)
        }
    }

    func testThatItMarksDownloadAsFailedIfCannotDownload_CannotDecrypt_V3() {
        
        // GIVEN
        var message : ZMMessage!
        self.syncMOC.performGroupedBlockAndWait {
            let (msg, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            msg.requestFileDownload()
            message = msg
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        performIgnoringZMLogError {
            self.syncMOC.performGroupedBlockAndWait {
                let request = self.sut.nextRequest()
                let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 200, transportSessionError: .none)
                request?.complete(with: response)
            }
            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }
        
        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.fileMessageData?.downloadState, .remote)
        }
    }

    func testThatItUpdatesFileDownloadProgress_V3() {
        var message : ZMMessage!
        let expectedProgress: Float = 0.5

        // GIVEN
        self.syncMOC.performGroupedBlockAndWait {
            let (msg, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            msg.requestFileDownload()
            message = msg
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            XCTAssertEqual(message.fileMessageData?.progress, 0)
            request?.updateProgress(expectedProgress)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.fileMessageData?.progress, expectedProgress)
        }
    }

    func testThatItSendsTheNotificationIfSuccessfulDownloadAndDecryption_V3() {
        
        // EXPECT
        var token: Any? = nil
        let expectation = self.expectation(description: "Notification fired")
        token = NotificationInContext.addObserver(name: AssetDownloadRequestStrategyNotification.downloadFinishedNotificationName,
                                                  context: self.uiMOC.notificationContext,
                                                  object: nil)
        { note in
            XCTAssertNotNil(note.userInfo[AssetDownloadRequestStrategyNotification.downloadStartTimestampKey] as? Date)
            expectation.fulfill()
        }
        
        // GIVEN
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        
        self.syncMOC.performGroupedBlockAndWait {
            let (message, _, _) = self.createFileMessageWithAssetId(in: self.conversation, otrKey: key, sha: sha)!
            message.requestFileDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail("Did not create expected request") }
            request.markStartOfUploadTimestamp()
            let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])
            
            request.complete(with: response)
        }
        
        // THEN
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }
    
    func testThatItRecategorizeMessageAfterDownloadingAssetContent() {
        let plainTextData = self.verySmallJPEGData()
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        let messageId = UUID.create()
        
        var message : ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let asset = ZMAssetBuilder()
                .setOriginal(ZMAssetOriginalBuilder()
                    .setMimeType("image/jpeg")
                    .setSize(UInt64(plainTextData.count))
                    .setImage(ZMAssetImageMetaDataBuilder()
                        .setWidth(100)
                        .setHeight(100)
                        .setTag("medium")))
                .setUploaded(ZMAssetRemoteDataBuilder()
                    .setOtrKey(key)
                    .setSha256(sha)
                    .setAssetId("someId")
                    .setAssetToken("someToken"))
                .build()
            
            let genericMessage = ZMGenericMessage.message(content: asset!, nonce: messageId)
            
            let dict = ["recipient": self.selfClient.remoteIdentifier!,
                        "sender": self.selfClient.remoteIdentifier!,
                        "text": genericMessage.data().base64String()] as NSDictionary
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: ([
                "type": "conversation.otr-message-add",
                "data":dict,
                "from" : self.selfClient.user!.remoteIdentifier!,
                "conversation":self.conversation.remoteIdentifier!.transportString(),
                "time":Date(timeIntervalSince1970: 555555).transportString()] as NSDictionary), uuid: nil)!
            
            message = ZMOTRMessage.messageUpdateResult(from: updateEvent, in: self.syncMOC, prefetchResult: nil)?.message as? ZMAssetClientMessage
            message.visibleInConversation = self.conversation
            message.updateTransferState(.uploaded, synchronize: false)
            self.syncMOC.saveOrRollback()
            message.requestFileDownload()
            
            XCTAssertEqual(message.category, [.image, .excludedFromCollection])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout:0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            self.sut.contextChangeTrackers.forEach { (tracker) in
                tracker.objectsDidChange([message])
            }
            
            let request = self.sut.nextRequest()
            request?.markStartOfUploadTimestamp()
            let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])
            
            // WHEN
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout:0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertEqual(message.category, [.image])
        }
    }
    
    func testThatItRecategorizeMessageWithSvgAttachmentAfterDownloadingAssetContent() {
        guard let plainTextData = ("<svg width=\"100\" height=\"100\">"
            + "<rect width=\"100\" height=\"100\"/>"
            + "</svg>").data(using: .utf8) else {
                XCTFail("Unable to convert SVG to Data");
                return;
        }
        
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        let messageId = UUID.create()
        
        var message : ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let asset = ZMAssetBuilder()
                .setOriginal(ZMAssetOriginalBuilder()
                    .setMimeType("image/svg+xml")
                    .setSize(UInt64(plainTextData.count))
                    .setImage(ZMAssetImageMetaDataBuilder() // Even if we treat them as files, SVGs are sent as images.
                        .setWidth(100)
                        .setHeight(100)
                        .setTag("medium")))
                .setUploaded(ZMAssetRemoteDataBuilder()
                    .setOtrKey(key)
                    .setSha256(sha)
                    .setAssetId("someId")
                    .setAssetToken("someToken"))
                .build()
            
            let genericMessage = ZMGenericMessage.message(content: asset!, nonce: messageId)
            
            let dict = ["recipient": self.selfClient.remoteIdentifier!,
                        "sender": self.selfClient.remoteIdentifier!,
                        "text": genericMessage.data().base64String()] as NSDictionary
            let updateEvent = ZMUpdateEvent(fromEventStreamPayload: ([
                "type": "conversation.otr-message-add",
                "data":dict,
                "from" : self.selfClient.user!.remoteIdentifier!,
                "conversation":self.conversation.remoteIdentifier!.transportString(),
                "time":Date(timeIntervalSince1970: 555555).transportString()] as NSDictionary), uuid: nil)!
            
            message = ZMOTRMessage.messageUpdateResult(from: updateEvent, in: self.syncMOC, prefetchResult: nil)?.message as? ZMAssetClientMessage
            message.visibleInConversation = self.conversation
            message.updateTransferState(.uploaded, synchronize: false)
            self.syncMOC.saveOrRollback()
            message.requestFileDownload()
            
            XCTAssertEqual(message.category, [.file])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout:0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            let request = self.sut.nextRequest()
            request?.markStartOfUploadTimestamp()
            let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])
            
            // WHEN
            request?.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout:0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            // THEN
            XCTAssertEqual(message.category, [.file])
        }
    }
    
    func testThatItSendsTheNotificationIfCannotDownload_V3() {
        // EXPECT
        var token: Any? = nil
        let expectation = self.expectation(description: "Notification fired")
        token = NotificationInContext.addObserver(name: AssetDownloadRequestStrategyNotification.downloadFailedNotificationName,
                                                  context: self.uiMOC.notificationContext,
                                                  object: nil)
        { note in
            XCTAssertNotNil(note.userInfo[AssetDownloadRequestStrategyNotification.downloadStartTimestampKey] as? Date)
            expectation.fulfill()
        }
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let (message, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            message.requestFileDownload()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail("No message")}
            
            request.markStartOfUploadTimestamp()
            let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 404, transportSessionError: .none)
            
            // WHEN
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }
}

// MARK : - Download Cancellation

extension AssetV3DownloadRequestStrategyTests {

    func testThatItInformsTheTaskCancellationProviderToCancelARequestForAnAssetMessageWhenItReceivesTheNotification_V3() {
        var message : ZMAssetClientMessage!
        var identifier: ZMTaskIdentifier?
        
        // GIVEN
        self.syncMOC.performGroupedBlockAndWait {
            let (msg, _, _) = self.createFileMessageWithAssetId(in: self.conversation)!
            msg.requestFileDownload()
            message = msg
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout:0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            //  task has been created
            guard let request = self.sut.nextRequest() else { return XCTFail("No request created") }
            
            request.callTaskCreationHandlers(withIdentifier: 42, sessionIdentifier: self.name)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout:0.5))

        self.syncMOC.performGroupedBlockAndWait {
            identifier = message.associatedTaskIdentifier
        }
        XCTAssertNotNil(identifier)

        // WHEN the transfer is cancelled
        self.syncMOC.performGroupedBlock {
            message.fileMessageData?.cancelTransfer()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout:0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            // THEN the cancellation provider should be informed to cancel the request
            XCTAssertEqual(self.mockApplicationStatus.cancelledIdentifiers.count, 1)
            let cancelledIdentifier = self.mockApplicationStatus.cancelledIdentifiers.first
            XCTAssertEqual(cancelledIdentifier, identifier)
            
            // It should nil-out the identifier as it has been cancelled
            XCTAssertNil(message.associatedTaskIdentifier)
        }
    }
    
}
