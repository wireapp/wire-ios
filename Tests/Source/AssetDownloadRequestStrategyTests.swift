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
import ZMCDataModel
import ZMTransport
import XCTest

private let testDataURL = Bundle(for: AssetDownloadRequestStrategyTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!

public class MockTaskCancellationProvider: NSObject, ZMRequestCancellation {
    
    var cancelledIdentifiers = [ZMTaskIdentifier]()
    
    public func cancelTask(with identifier: ZMTaskIdentifier) {
        cancelledIdentifiers.append(identifier)
    }
}


class AssetDownloadRequestStrategyTests: MessagingTestBase {
    
    var authStatus: MockClientRegistrationStatus!
    var cancellationProvider: MockTaskCancellationProvider!
    var sut: AssetDownloadRequestStrategy!
    var conversation: ZMConversation!
    
    override func setUp() {
        super.setUp()
        self.authStatus = MockClientRegistrationStatus()
        self.cancellationProvider = MockTaskCancellationProvider()
        self.syncMOC.performGroupedBlockAndWait {

            self.sut = AssetDownloadRequestStrategy(
                authStatus: self.authStatus,
                taskCancellationProvider: self.cancellationProvider,
                managedObjectContext: self.syncMOC
            )
            self.conversation = self.createConversation()
        }
    }
    
    fileprivate func createConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = UUID.create()
        return conversation
    }
    
    fileprivate func createFileTransferMessage(_ conversation: ZMConversation) -> ZMAssetClientMessage {
        let message = conversation.appendMessage(with: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
        message.assetId = UUID.create()
        configureForDownloading(message: message)
        return message
    }

    fileprivate func configureForDownloading(message: ZMAssetClientMessage) {
        message.fileMessageData?.transferState = .downloading
        self.syncMOC.saveOrRollback()

        self.sut.contextChangeTrackers.forEach { tracker in
            tracker.objectsDidChange(Set(arrayLiteral: message))
        }
    }
}

// request generation tests
extension AssetDownloadRequestStrategyTests {

    func testThatItGeneratesNoRequestsIfTheStatusIsEmpty() {
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItGeneratesNoRequestsIfNotAuthenticated() {
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            self.authStatus.mockClientIsReadyForRequests = false
            let _ = self.createFileTransferMessage(self.conversation)
            
            // WHEN
            let request : ZMTransportRequest? = self.sut.nextRequest()
            
            // THEN
            XCTAssertNil(request)
        }
    }
    
    
    func testThatItGeneratesNoRequestsIfMessageDoesNotHaveAnAssetId() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            
            message = self.conversation.appendMessage(with: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
            message.assetId = .none
            message.fileMessageData?.transferState = .downloading
            
            self.syncMOC.saveOrRollback()
            
            self.sut.contextChangeTrackers.forEach { tracker in
                tracker.objectsDidChange(Set(arrayLiteral: message))
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let request : ZMTransportRequest? = self.sut.nextRequest()
            
            // THEN
            XCTAssertNil(request)
        }
    }
    
    func testThatItGeneratesNoRequestsIfMessageIsUploading() {
        // GIVEN
        self.syncMOC.performGroupedBlockAndWait {

            let message = self.conversation.appendMessage(with: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
            message.assetId = UUID.create()
            message.fileMessageData?.transferState = .uploaded
            
            self.syncMOC.saveOrRollback()
            
            self.sut.contextChangeTrackers.forEach { tracker in
                tracker.objectsDidChange(Set(arrayLiteral: message))
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
        let request : ZMTransportRequest? = self.sut.nextRequest()
        
        // THEN
        XCTAssertNil(request)
        }
    }
    
    func testThatItGeneratesARequest() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.createFileTransferMessage(self.conversation)
            
            // WHEN
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            
            // THEN
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodGET)
            XCTAssertEqual(request.path, "/conversations/\(self.conversation.remoteIdentifier!.transportString())/otr/assets/\(message.assetId!.transportString())")
            XCTAssertTrue(request.needsAuthentication)
        }
    }
    
    func testThatItGeneratesARequestOnlyOnce() {
        
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let _ = self.createFileTransferMessage(self.conversation)

            // WHEN
            let request1 : ZMTransportRequest? = self.sut.nextRequest()
            let request2 : ZMTransportRequest? = self.sut.nextRequest()
            
            // THEN
            XCTAssertNotNil(request1)
            XCTAssertNil(request2)
        }
    }

}

// tests on result of request
extension AssetDownloadRequestStrategyTests {

    func testThatItMarksDownloadAsSuccessIfSuccessfulDownloadAndDecryption() {
        
        // GIVEN
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        var message: ZMAssetClientMessage!
        
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createFileTransferMessage(self.conversation)
            
            let dataBuilder = ZMAssetRemoteDataBuilder()
            dataBuilder.setSha256(sha)
            dataBuilder.setOtrKey(key)
            
            let assetBuilder = ZMAssetBuilder()
            assetBuilder.setUploaded(dataBuilder.build())
            
            let genericAssetMessageBuilder = ZMGenericMessageBuilder()
            genericAssetMessageBuilder.merge(from: message.genericAssetMessage)
            genericAssetMessageBuilder.setAsset(assetBuilder.build())
            
            message.add(genericAssetMessageBuilder.build())
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            
            XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.downloaded.rawValue)
        }
    }
    
    func testThatItMarksDownloadAsFailedIfCannotDownload_PermanentError() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createFileTransferMessage(self.conversation)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 404, transportSessionError: .none)
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.failedDownload.rawValue)
        }
    }
    
    func testThatItMarksDownloadAsFailedIfCannotDownload_TemporaryError() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createFileTransferMessage(self.conversation)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 500, transportSessionError: .none)
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.failedDownload.rawValue)
        }
    }
    
    func testThatItMarksDownloadAsFailedIfCannotDownload_CannotDecrypt() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createFileTransferMessage(self.conversation)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 200, transportSessionError: .none)
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.failedDownload.rawValue)
        }
    }
    
    func testThatItDoesNotMarkDownloadAsFailedWhenNotDownloading() {
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createFileTransferMessage(self.conversation)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 500, transportSessionError: .none)
            message.transferState = .uploaded
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.uploaded.rawValue)
        }
    }
    
    func testThatItUpdatesFileDownloadProgress() {
        // GIVEN
        var message: ZMAssetClientMessage!
        let expectedProgress: Float = 0.5
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createFileTransferMessage(self.conversation)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            XCTAssertEqual(message.fileMessageData?.progress, 0)
            request.updateProgress(expectedProgress)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.fileMessageData?.progress, expectedProgress)
        }
    }
    
    func testThatItSendsTheNotificationIfSuccessfulDownloadAndDecryption() {
        
        // GIVEN
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        
        self.syncMOC.performGroupedBlockAndWait {
            let message = self.createFileTransferMessage(self.conversation)
        
            let dataBuilder = ZMAssetRemoteDataBuilder()
            dataBuilder.setSha256(sha)
            dataBuilder.setOtrKey(key)
            
            let assetBuilder = ZMAssetBuilder()
            assetBuilder.setUploaded(dataBuilder.build())
            
            let genericAssetMessageBuilder = ZMGenericMessageBuilder()
            genericAssetMessageBuilder.merge(from: message.genericAssetMessage)
            genericAssetMessageBuilder.setAsset(assetBuilder.build())
            
            message.add(genericAssetMessageBuilder.build())
        }
        
        let notificationExpectation = self.expectation(description: "Notification fired")
        
        let _ = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AssetDownloadRequestStrategyNotification.downloadFinishedNotificationName), object: nil, queue: .main) { notification in
            XCTAssertNotNil(notification.userInfo![AssetDownloadRequestStrategyNotification.downloadStartTimestampKey])
            notificationExpectation.fulfill()
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            request.markStartOfUploadTimestamp()
            let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])
            request.complete(with: response)
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }
    
    func testThatItSendsTheNotificationIfCannotDownload() {
        // GIVEN
        
        let notificationExpectation = self.expectation(description: "Notification fired")
        
        let _ = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AssetDownloadRequestStrategyNotification.downloadFailedNotificationName), object: nil, queue: .main) { notification in
            XCTAssertNotNil(notification.userInfo![AssetDownloadRequestStrategyNotification.downloadStartTimestampKey])
            notificationExpectation.fulfill()
        }
        
        self.syncMOC.performGroupedBlockAndWait {
            _ = self.createFileTransferMessage(self.conversation)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            request.markStartOfUploadTimestamp()
            let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 404, transportSessionError: .none)
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }
}

// MARK : - Download Cancellation

extension AssetDownloadRequestStrategyTests {
    
    func testThatItInformsTheTaskCancellationProviderToCancelARequestForAnAssetMessageWhenItReceivesTheNotification() {
        // GIVEN
        var message: ZMAssetClientMessage!
        var identifier: ZMTaskIdentifier?
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createFileTransferMessage(self.conversation)
            XCTAssertNotNil(message.objectID)
            guard let request = self.sut.nextRequest() else { return XCTFail("No request created") }
            request.callTaskCreationHandlers(withIdentifier: 42, sessionIdentifier: self.name!)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.syncMOC.performGroupedBlockAndWait {
            identifier = message.associatedTaskIdentifier
            XCTAssertNotNil(identifier)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
        }
        
        // WHEN the transfer is cancelled
        self.syncMOC.performGroupedBlockAndWait {
            message.fileMessageData?.cancelTransfer()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN the cancellation provider should be informed to cancel the request
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.cancellationProvider.cancelledIdentifiers.count, 1)
            let cancelledIdentifier = self.cancellationProvider.cancelledIdentifiers.first
            XCTAssertEqual(cancelledIdentifier, identifier)
            
            // It should nil-out the identifier as it has been cancelled
            XCTAssertNil(message.associatedTaskIdentifier)
        }
    }
}

// MARK : - Ephemeral
extension AssetDownloadRequestStrategyTests {

    func testThatItDoesNotProcessTheResponseIfTheMessageHasBeenDeletedInTheMeantime() {
        // GIVEN
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.createFileTransferMessage(self.conversation)
        
            let dataBuilder = ZMAssetRemoteDataBuilder()
            dataBuilder.setSha256(sha)
            dataBuilder.setOtrKey(key)
            
            let assetBuilder = ZMAssetBuilder()
            assetBuilder.setUploaded(dataBuilder.build())
            
            let genericAssetMessageBuilder = ZMGenericMessageBuilder()
            genericAssetMessageBuilder.merge(from: message.genericAssetMessage)
            genericAssetMessageBuilder.setAsset(assetBuilder.build())
            
            message.add(genericAssetMessageBuilder.build())
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {

            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])
        
            message.visibleInConversation = nil
            message.hiddenInConversation = self.conversation
        
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNotEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.downloaded.rawValue)
        }
    }
    
    
    func testThatItDoesNotAddAHiddenMessage(){
        // GIVEN
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            message = self.conversation.appendMessage(with: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
            message.assetId = UUID.create()
            message.fileMessageData?.transferState = .downloading
            message.visibleInConversation = nil
            message.hiddenInConversation = self.conversation
            self.syncMOC.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            self.sut.contextChangeTrackers.forEach { tracker in
                tracker.objectsDidChange(Set(arrayLiteral: message))
            }
        }
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.sut.nextRequest())
        }
    }

}
