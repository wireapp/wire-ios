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
        authStatus = MockClientRegistrationStatus()
        cancellationProvider = MockTaskCancellationProvider()
        sut = AssetDownloadRequestStrategy(
            authStatus: authStatus,
            taskCancellationProvider: cancellationProvider,
            managedObjectContext: syncMOC
        )
        conversation = createConversation()
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

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}

// request generation tests
extension AssetDownloadRequestStrategyTests {

    func testThatItGeneratesNoRequestsIfTheStatusIsEmpty() {
        XCTAssertNil(self.sut.nextRequest())
    }
    
    func testThatItGeneratesNoRequestsIfNotAuthenticated() {
        // GIVEN
        self.authStatus.mockClientIsReadyForRequests = false
        let _ = self.createFileTransferMessage(self.conversation)
        
        // WHEN
        let request : ZMTransportRequest? = self.sut.nextRequest()
        
        // THEN
        XCTAssertNil(request)
    }
    
    
    func testThatItGeneratesNoRequestsIfMessageDoesNotHaveAnAssetId() {
        // GIVEN
        let message = conversation.appendMessage(with: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
        message.assetId = .none
        message.fileMessageData?.transferState = .downloading
        
        self.syncMOC.saveOrRollback()
        
        self.sut.contextChangeTrackers.forEach { tracker in
            tracker.objectsDidChange(Set(arrayLiteral: message))
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        let request : ZMTransportRequest? = self.sut.nextRequest()
        
        // THEN
        XCTAssertNil(request)
    }
    
    func testThatItGeneratesNoRequestsIfMessageIsUploading() {
        // GIVEN
        let message = conversation.appendMessage(with: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
        message.assetId = UUID.create()
        message.fileMessageData?.transferState = .uploaded
        
        self.syncMOC.saveOrRollback()
        
        self.sut.contextChangeTrackers.forEach { tracker in
            tracker.objectsDidChange(Set(arrayLiteral: message))
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        let request : ZMTransportRequest? = self.sut.nextRequest()
        
        // THEN
        XCTAssertNil(request)
    }
    
    func testThatItGeneratesARequest() {
        
        // GIVEN
        let message = self.createFileTransferMessage(self.conversation)

        // WHEN
        let request : ZMTransportRequest? = self.sut.nextRequest()
        
        // THEN
        if let request = request {
            XCTAssertEqual(request.method, ZMTransportRequestMethod.methodGET)
            XCTAssertEqual(request.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/otr/assets/\(message.assetId!.transportString())")
            XCTAssertTrue(request.needsAuthentication)
        } else {
            XCTFail("Empty request")
        }
    }
    
    func testThatItGeneratesARequestOnlyOnce() {
        
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

// tests on result of request
extension AssetDownloadRequestStrategyTests {

    func testThatItMarksDownloadAsSuccessIfSuccessfulDownloadAndDecryption() {
        
        // GIVEN
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        
        
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
        
        let request : ZMTransportRequest? = self.sut.nextRequest()
        let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])
        
        // WHEN
        request?.complete(with: response)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.downloaded.rawValue)
    }
    
    func testThatItMarksDownloadAsFailedIfCannotDownload_PermanentError() {
        // GIVEN
        let message = self.createFileTransferMessage(self.conversation)
        let request : ZMTransportRequest? = self.sut.nextRequest()
        let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 404, transportSessionError: .none)
        
        // WHEN
        request?.complete(with: response)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.failedDownload.rawValue)
    }
    
    func testThatItMarksDownloadAsFailedIfCannotDownload_TemporaryError() {
        // GIVEN
        let message = self.createFileTransferMessage(self.conversation)
        let request : ZMTransportRequest? = self.sut.nextRequest()
        let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 500, transportSessionError: .none)
        
        // WHEN
        request?.complete(with: response)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.failedDownload.rawValue)
    }
    
    func testThatItMarksDownloadAsFailedIfCannotDownload_CannotDecrypt() {
        // GIVEN
        let message = self.createFileTransferMessage(self.conversation)
        let request : ZMTransportRequest? = self.sut.nextRequest()
        let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 200, transportSessionError: .none)
        
        // WHEN
        request?.complete(with: response)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.failedDownload.rawValue)
    }
    
    func testThatItDoesNotMarkDownloadAsFailedWhenNotDownloading() {
        // GIVEN
        let message = self.createFileTransferMessage(self.conversation)
        let request : ZMTransportRequest? = self.sut.nextRequest()
        let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 500, transportSessionError: .none)
        
        // WHEN
        message.transferState = .uploaded
        request?.complete(with: response)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.uploaded.rawValue)
    }
    
    func testThatItUpdatesFileDownloadProgress() {
        // GIVEN
        let expectedProgress: Float = 0.5
        let message = self.createFileTransferMessage(self.conversation)
        let request : ZMTransportRequest? = self.sut.nextRequest()
        
        XCTAssertEqual(message.fileMessageData?.progress, 0)

        // WHEN
        request?.updateProgress(expectedProgress)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertEqual(message.fileMessageData?.progress, expectedProgress)
    }
    
    func testThatItSendsTheNotificationIfSuccessfulDownloadAndDecryption() {
        
        // GIVEN
        let plainTextData = Data.secureRandomData(length: 500)
        let key = Data.randomEncryptionKey()
        let encryptedData = plainTextData.zmEncryptPrefixingPlainTextIV(key: key)
        let sha = encryptedData.zmSHA256Digest()
        
        
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
        
        let notificationExpectation = self.expectation(description: "Notification fired")
        
        let _ = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AssetDownloadRequestStrategyNotification.downloadFinishedNotificationName), object: nil, queue: .main) { notification in
            XCTAssertNotNil(notification.userInfo![AssetDownloadRequestStrategyNotification.downloadStartTimestampKey])
            notificationExpectation.fulfill()
        }
        
        let request : ZMTransportRequest? = self.sut.nextRequest()
        request?.markStartOfUploadTimestamp()
        let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])
        
        // WHEN
        request?.complete(with: response)
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
        
        let _ = self.createFileTransferMessage(self.conversation)
        let request : ZMTransportRequest? = self.sut.nextRequest()
        request?.markStartOfUploadTimestamp()
        let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 404, transportSessionError: .none)
        
        // WHEN
        request?.complete(with: response)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }
}

// MARK : - Download Cancellation

extension AssetDownloadRequestStrategyTests {
    
    func testThatItInformsTheTaskCancellationProviderToCancelARequestForAnAssetMessageWhenItReceivesTheNotification() {
        // GIVEN
        let message = createFileTransferMessage(conversation)
        XCTAssertNotNil(message.objectID)
        
        // GIVEN the task has been created
        guard let request = sut.nextRequest() else { return XCTFail("No request created") }
        
        request.callTaskCreationHandlers(withIdentifier: 42, sessionIdentifier: name!)
        XCTAssertTrue(syncMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let identifier = message.associatedTaskIdentifier
        XCTAssertNotNil(identifier)
        
        // WHEN the transfer is cancelled
        message.fileMessageData?.cancelTransfer()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN the cancellation provider should be informed to cancel the request
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 1)
        let cancelledIdentifier = cancellationProvider.cancelledIdentifiers.first
        XCTAssertEqual(cancelledIdentifier, identifier)
        
        // It should nil-out the identifier as it has been cancelled
        XCTAssertNil(message.associatedTaskIdentifier)
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
        
        let request : ZMTransportRequest? = self.sut.nextRequest()
        let response = ZMTransportResponse(imageData: encryptedData, httpStatus: 200, transportSessionError: .none, headers: [:])
        
        // WHEN
        message.visibleInConversation = nil
        message.hiddenInConversation = conversation
        
        request?.complete(with: response)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNotEqual(message.fileMessageData?.transferState.rawValue, ZMFileTransferState.downloaded.rawValue)
    }
    
    
    func testThatItDoesNotAddAHiddenMessage(){
        // GIVEN
        let message = conversation.appendMessage(with: ZMFileMetadata(fileURL: testDataURL)) as! ZMAssetClientMessage
        message.assetId = UUID.create()
        message.fileMessageData?.transferState = .downloading
        message.visibleInConversation = nil
        message.hiddenInConversation = conversation
        self.syncMOC.saveOrRollback()
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // WHEN
        self.sut.contextChangeTrackers.forEach { tracker in
            tracker.objectsDidChange(Set(arrayLiteral: message))
        }
        
        // THEN
        XCTAssertNil(sut.nextRequest())
    }

}
