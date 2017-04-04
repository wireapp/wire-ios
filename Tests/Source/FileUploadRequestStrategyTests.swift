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
import WireDataModel



private class FakeCancelationProvider : NSObject, ZMRequestCancellation {
    
    var cancelledIdentifiers = [ZMTaskIdentifier]()
    
    @objc func cancelTask(with identifier: ZMTaskIdentifier) {
        cancelledIdentifiers.append(identifier)
    }
}

@objc class FakeZMURLSessionDelegate: NSObject, ZMURLSessionDelegate {
    @objc func urlSessionDidReceiveData(_ URLSession: ZMURLSession) {}
    @objc func urlSession(_ URLSession: ZMURLSession, dataTask: URLSessionDataTask, didReceive didReceiveResponse: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {}
    @objc func urlSessionDidFinishEvents(forBackgroundURLSession URLSession: ZMURLSession) {}
    @objc func urlSession(_ URLSession: ZMURLSession, taskDidComplete: URLSessionTask, transportRequest: ZMTransportRequest, responseData:Data) {}
}

private let testDataURL = Bundle(for: FilePreprocessorTests.self).url(forResource: "Lorem Ipsum", withExtension: "txt")!
private let testData = try! Data(contentsOf: testDataURL)

// MARK: - Tests setup
class FileUploadRequestStrategyTests: MessagingTestBase {

    fileprivate var sut: FileUploadRequestStrategy!
    fileprivate var cancellationProvider: FakeCancelationProvider!
	fileprivate var clientRegistrationStatus : MockClientRegistrationStatus!
    
    override func setUp() {
        super.setUp()
        self.cancellationProvider = FakeCancelationProvider()
		self.clientRegistrationStatus = MockClientRegistrationStatus()
        self.sut = FileUploadRequestStrategy(
			clientRegistrationStatus: self.clientRegistrationStatus,
            managedObjectContext: self.syncMOC,
            taskCancellationProvider: self.cancellationProvider
        )
    }
    
    /// Creates a message that should generate request
    func createMessage(_ name: String, uploadState: ZMAssetUploadState = .uploadingPlaceholder, thumbnail: Data? = nil, url: URL = testDataURL, isEphemeral: Bool = false) -> ZMAssetClientMessage {
        var msg: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            if isEphemeral {
                self.groupConversation.messageDestructionTimeout = 10
            }
            // This is a video metadata since it's the only file type which supports thumbnails at the moment.
            msg = self.groupConversation.appendMessage(with: ZMVideoMetadata(fileURL: url, thumbnail: thumbnail)) as! ZMAssetClientMessage
            msg.uploadState = uploadState
            self.syncMOC.saveOrRollback()
        }
        return msg
    }

    /// Forces the strategy to process the message
    func process(_ strategy: FileUploadRequestStrategy,
                 message: ZMAssetClientMessage,
                 file: StaticString = #file,
                 line: UInt = #line) {
        // first change will start preprocessing
        self.syncMOC.performGroupedBlock {
            strategy.contextChangeTrackers.forEach { $0.objectsDidChange(Set(arrayLiteral: message)) }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // second change will make it be picked up by uploader
        self.syncMOC.performGroupedBlock {
            strategy.contextChangeTrackers.forEach { $0.objectsDidChange(Set(arrayLiteral: message)) }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}

// MARK: - Request generation
extension FileUploadRequestStrategyTests {

    func testThatItGeneratesARequestForAFileMessageThatIsPreprocessed() {
        
        // GIVEN
        var placeholderRequest: ZMTransportRequest?
        let msg = self.createMessage("foo")
        self.process(sut, message: msg)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            placeholderRequest = self.sut.nextRequest() // Asset.Original request (message-add)
        }
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let msgConversation = msg.conversation else { return XCTFail("message conversation was nil") }
            XCTAssertNotNil(placeholderRequest)
            guard let requestUploaded = placeholderRequest else { return XCTFail() }
            XCTAssertEqual(requestUploaded.path, "/conversations/\(msgConversation.remoteIdentifier!.transportString())/otr/messages")
            XCTAssertEqual(requestUploaded.method, ZMTransportRequestMethod.methodPOST)
            
            guard let genericMessage = self.decryptedMessage(fromRequestData: requestUploaded.binaryData!, forClient: self.otherClient) else { return XCTFail() }
            XCTAssertFalse(genericMessage.asset.hasNotUploaded())
            XCTAssertTrue(genericMessage.asset.hasOriginal())
            let original = genericMessage.asset.original!
            XCTAssertEqual(original.name, msg.filename)
            XCTAssertEqual(original.mimeType, msg.mimeType)
            XCTAssertEqual(original.size, msg.size)
            XCTAssertFalse(genericMessage.asset.hasUploaded())
        }
    }
    
    func testThatItSets_UploadingThumbnail_OnMessageWhenAssetOriginalRequestCompletesSuccesfully_Video() {
        
        // GIVEN
        guard let url = Bundle(for: type(of: self)).url(forResource: "video", withExtension:"mp4") else { return XCTFail() }
        let msg = self.createMessage(self.name!, thumbnail: self.mediumJPEGData(), url: url)
        self.process(sut, message: msg)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let placeholderRequest = self.sut.nextRequest() // Asset.Original request (message-add)
            placeholderRequest?.complete(status: 201)
        }
        
        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingThumbnail)
            XCTAssertEqual(msg.transferState, ZMFileTransferState.uploading)
        }
    }
    
    
    func testThatItSets_UploadingThumbnail_OnMessageWhenAssetOriginalRequestCompletesSuccesfully_Text() {
        
        // GIVEN
        guard let url = Bundle(for: type(of: self)).url(forResource: "Lorem Ipsum", withExtension:"txt") else { return XCTFail() }
        let msg = self.createMessage(self.name!, thumbnail: self.mediumJPEGData(), url: url)
        self.process(self.sut, message: msg)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let placeholderRequest = self.sut.nextRequest() // Asset.Original request (message-add)
            placeholderRequest?.complete(status: 201)
        }
        
        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingThumbnail)
            XCTAssertEqual(msg.transferState, ZMFileTransferState.uploading)
        }
    }
    
    func testThatItSets_UploadingFullAsset_OnMessageWithoutThumbnail_Text() {
        
        // GIVEN
        guard let url = Bundle(for: type(of: self)).url(forResource: "Lorem Ipsum", withExtension:"txt") else { return XCTFail() }
        let msg = self.createMessage(self.name!, thumbnail: nil, url: url)
        self.process(self.sut, message: msg)

        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let placeholderRequest = self.sut.nextRequest() // Asset.Original request (message-add)
            placeholderRequest?.complete(status: 201)
        }
        
        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingFullAsset)
            XCTAssertEqual(msg.transferState, ZMFileTransferState.uploading)
        }
    }

    
    func testThatItSets_UploadingFullAsset_OnVideoFileMessageWhenTheThumbnailRequestCompletesSuccesfully() {
        
        // GIVEN
        guard let url = Bundle(for: type(of: self)).url(forResource: "video", withExtension:"mp4") else { return XCTFail() }
        let msg = self.createMessage(self.name!, thumbnail: self.mediumJPEGData(), url: url)
        self.process(sut, message: msg)
        
        // WHEN
        var placeholderRequest: ZMTransportRequest?
        self.syncMOC.performGroupedBlockAndWait {
            placeholderRequest = self.sut.nextRequest() // Asset.Original request (message-add / .UploadingPlaceholder)
            placeholderRequest?.complete(status: 201)
        }
        
        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNotNil(placeholderRequest)
            XCTAssertEqual(placeholderRequest?.path, "/conversations/\(msg.conversation!.remoteIdentifier!.transportString())/otr/messages")
            XCTAssertEqual(placeholderRequest?.method, ZMTransportRequestMethod.methodPOST)
            XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingThumbnail)
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let thumbnailRequest = self.sut.nextRequest() else { return XCTFail() } // Asset.Preview request (message-add / .UploadingThumbnail)
            XCTAssertEqual(thumbnailRequest.path, "/conversations/\(msg.conversation!.remoteIdentifier!.transportString())/otr/assets")
            XCTAssertEqual(thumbnailRequest.method, ZMTransportRequestMethod.methodPOST)
            thumbnailRequest.complete(status: 201)
        }
        
        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingFullAsset)
            XCTAssertEqual(msg.transferState, ZMFileTransferState.uploading)
        }
        
        // WHEN
        var fullRequest: ZMTransportRequest?
        self.syncMOC.performGroupedBlockAndWait {
            fullRequest = self.sut.nextRequest() // Asset.Uploaded request (message-add / .UploadingFullAsset)
            fullRequest?.complete(status: 201)
        }
        
        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNotNil(fullRequest)
            XCTAssertEqual(fullRequest?.path, "/conversations/\(msg.conversation!.remoteIdentifier!.transportString())/otr/assets")
            XCTAssertEqual(fullRequest?.method, ZMTransportRequestMethod.methodPOST)
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItSets_UploadingFullAsset_OnFileMessageWhenThePlaceholderRequestCompletesSuccesfully() {
        
        // GIVEN
        let msg = createMessage(name!)
        self.process(self.sut, message: msg)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let placeholderRequest = self.sut.nextRequest() else { return XCTFail("Unable to create placeholder request") } // Asset.Original request (message-add / .UploadingPlaceholder)
            placeholderRequest.complete(status: 201)
        
            // THEN
            XCTAssertEqual(placeholderRequest.path, "/conversations/\(msg.conversation!.remoteIdentifier!.transportString())/otr/messages")
            XCTAssertEqual(placeholderRequest.method, ZMTransportRequestMethod.methodPOST)
        }
        
        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingFullAsset)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.uploading)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let fullRequest = self.sut.nextRequest() else { return XCTFail("Unable to create full asset request") } // Asset.Uploaded request (message-add / .UploadingFullAsset)
            fullRequest.complete(status: 201)
            
            // THEN
            XCTAssertEqual(fullRequest.path, "/conversations/\(msg.conversation!.remoteIdentifier!.transportString())/otr/assets")
            XCTAssertEqual(fullRequest.method, ZMTransportRequestMethod.methodPOST)
        }

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItDoesNotGeneratesARequestWhenNotAuthenticated() {
        
        // GIVEN
		self.clientRegistrationStatus.mockClientIsReadyForRequests = false
        let msg = self.createMessage("foo")
        self.process(self.sut, message: msg)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let reqUploaded = self.sut.nextRequest() // uploaded
        
            // THEN
            XCTAssertNil(reqUploaded)
        }
    }
    
    func testThatItDoesNotGenerateARequestForTheNextMessageWhenThereIsAPreviousOriginalBeingUploaded() {
        
        // GIVEN
        let msg1 = createMessage("foo")
        self.process(sut, message: msg1)
        let msg2 = createMessage("foo")
        self.process(sut, message: msg2)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            _ = self.sut.nextRequest() // original
            let nextRequest = self.sut.nextRequest()
        
        
            // THEN
            XCTAssertNil(nextRequest)
        }
    }
    
    func testThatItGeneratesRequestForTheNextMessageWhenThereIsAPreviousFileBeingUploaded() {
        
        // GIVEN
        let msg1 = self.createMessage("foo")
        self.process(sut, message: msg1)
        
        self.syncMOC.performGroupedBlockAndWait {

            // first request: msg1 original
            let msg1Original = self.sut.nextRequest() // original
            XCTAssertEqual(msg1Original?.path, "/conversations/\(msg1.conversation!.remoteIdentifier!.transportString())/otr/messages")
        
            msg1Original?.complete(status: 200)
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.saveOrRollback()
        }
        self.process(sut, message: msg1)
    
        self.syncMOC.performGroupedBlockAndWait {
            // second request: msg1 file
            let msg1File = self.sut.nextRequest()
            XCTAssertEqual(msg1File?.path, "/conversations/\(msg1.conversation!.remoteIdentifier!.transportString())/otr/assets")
        }
        // WHEN
        let msg2 = self.createMessage("foo")
        self.process(sut, message: msg2)
        
        // THEN
        // third request: msg2 original
        self.syncMOC.performGroupedBlockAndWait {
            let msg2Original = self.sut.nextRequest()
            XCTAssertEqual(msg2Original?.path, "/conversations/\(msg1.conversation!.remoteIdentifier!.transportString())/otr/messages")
        }
    }
}

// MARK: - Parse response
extension FileUploadRequestStrategyTests {
    
    func testThatItMarksAnUploadedFileAsFailedToUploadWhenTheRequestCompletesUnsuccesfully() {
        
        // GIVEN
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            let placeholderRequest = self.sut.nextRequest() // Asset.Original request (message-add)
            placeholderRequest?.complete(status: 400)
        }
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(msg.transferState, ZMFileTransferState.failedUpload)
            XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingFailed)
            let nextRequest = self.sut.nextRequest()
            XCTAssertNil(nextRequest)
        }
    }
    
    func testThatItDoesGenerateTheRequestToUploadTheMediumAfterThePreviewCompletedSuccessfully() {
        
        // GIVEN
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        
        // WHEN
        var placeholderRequest: ZMTransportRequest?
        self.syncMOC.performGroupedBlockAndWait {
            placeholderRequest = self.sut.nextRequest() // Asset.Original request (message-add)
            placeholderRequest?.complete(status: 201)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            let uploadedRequest = self.sut.nextRequest() // Uploaded request (asset-add)
            guard let msgConversation = msg.conversation else { return XCTFail("Conversation was nil") }
            XCTAssertEqual(msg.uploadState, ZMAssetUploadState.uploadingFullAsset)
            XCTAssertNotNil(placeholderRequest)
            XCTAssertNotNil(uploadedRequest)
            XCTAssertNotNil(uploadedRequest?.fileUploadURL)
            XCTAssertEqual(uploadedRequest?.path, "/conversations/\(msgConversation.remoteIdentifier!.transportString())/otr/assets")
     
            guard let request = uploadedRequest,
                let requestMultipart = try? Data(contentsOf: request.fileUploadURL!) else {
                    return XCTFail("No data at fileUploadURL")
            }
            
            let genericPartData = (requestMultipart as NSData).multipartDataItemsSeparated(withBoundary: "frontier").first as! ZMMultipartBodyItem
            guard let genericMessage = self.decryptedMessage(fromRequestData: genericPartData.data, forClient: self.otherClient) else { return XCTFail() }
            XCTAssertTrue(genericMessage.asset.hasOriginal())
            XCTAssertFalse(genericMessage.asset.hasNotUploaded())
            XCTAssertTrue(genericMessage.asset.hasUploaded())
            XCTAssertNil(self.sut.nextRequest())
        }
    }
    
    func testThatItUpdatesTheMessageWithTheAssetIDFromTheUploadedReponseHeader() {
        
        // GIVEN
        let msg = createMessage(name!, uploadState: .uploadingFullAsset)
        let assetId = UUID.create()
        self.process(sut, message: msg)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 200, transportSessionError: nil, headers: ["Location": assetId.transportString()])
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(msg.delivered)
            XCTAssertEqual(msg.transferState, ZMFileTransferState.downloaded)
            XCTAssertEqual(msg.assetId, assetId)
        }
    }
    
    func testThatItDeletesDataForAnUploadedFile() {
        
        // GIVEN
        let msg = createMessage(name!, uploadState: .uploadingFullAsset)
        self.process(sut, message: msg)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            request.complete(status: 200)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
    }
    
    func testThatItMarksAFailedFile_OriginalFailed() {
        
        // GIVEN
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            request.complete(status: 400)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(msg.delivered)
            XCTAssertEqual(msg.transferState, ZMFileTransferState.failedUpload)
        }
    }
    
    func testThatItMarksAFailedFile_UploadedFailed() {
        
        // GIVEN
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        
        // WHEN
        guard let request = sut.nextRequest() else { return XCTFail() }
        request.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertFalse(msg.delivered)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.failedUpload)
    }
    
    func testThatItMarksAFailedFile_UploadedFailed_TemporaryError() {
        
        // GIVEN
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        
        // WHEN
        guard let request = sut.nextRequest() else { return XCTFail() }
        request.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 500, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertFalse(msg.delivered)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.failedUpload)
    }
    
    func testThatItDeletesDataForAFailedFile_OriginalFailed() {
        
        // GIVEN
        let msg = createMessage(name!)
        self.process(sut, message: msg)
        
        // WHEN
        guard let request = sut.nextRequest() else { return XCTFail() }
        request.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
    }
    
    func testThatItDeletesUnencryptedDataForAFailedFile_UploadedFailed() {
        
        // GIVEN
        let msg = createMessage(name!, uploadState: .uploadingFullAsset)
        self.process(sut, message: msg)
        
        // WHEN
        guard let request = sut.nextRequest() else { return XCTFail() }
        request.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: false))
    }
    
    func testThatItSendsNotificaitonForAnUploadedFile() {
        
        // GIVEN
        let msg = createMessage(name!, uploadState: .uploadingFullAsset)
        self.process(sut, message: msg)

        guard let request = sut.nextRequest() else { return XCTFail() }
        request.markStartOfUploadTimestamp()
        let notificationExpectation = self.expectation(description: "Notification fired")
        
        let _ = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FileUploadRequestStrategyNotification.uploadFinishedNotificationName), object: nil, queue: .main) { notification in
            XCTAssertNotNil(notification.userInfo![FileUploadRequestStrategyNotification.requestStartTimestampKey])
            notificationExpectation.fulfill()
        }
        // WHEN
        let assetId = UUID.create()
        let response = ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 200, transportSessionError: nil, headers: ["Location": assetId.transportString()])
        request.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }
    
    func testThatItSendsNotificaitonForAFailedFile() {
        
        // GIVEN
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        request.markStartOfUploadTimestamp()
        let notificationExpectation = self.expectation(description: "Notification fired")
        
        let _ = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: FileUploadRequestStrategyNotification.uploadFailedNotificationName), object: nil, queue: .main) { notification in
            XCTAssertNotNil(notification.userInfo![FileUploadRequestStrategyNotification.requestStartTimestampKey])
            notificationExpectation.fulfill()
        }
        // WHEN
        request.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }
    
    func testThatItDoesNotCancelCurrentlyRunningRequestWhenTheUploadFails_FullAsset() {
        
        // GIVEN
        let msg = createMessage(name!, uploadState: .uploadingFullAsset)
        let identifier = ZMTaskIdentifier(identifier: 12345, sessionIdentifier: "background-session")
        msg.associatedTaskIdentifier = identifier
        process(sut, message: msg)
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 0)
        
        // WHEN
        guard let request = sut.nextRequest() else { return XCTFail() }
        request.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN there should not be a running upload request as the upload failed by itself,
        // next request would be the Asset.NotUploaded request
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 0)
    }
    
    func testThatItDoesNotCancelCurrentlyRunningRequestWhenTheUploadFails_Thumbnail() {
        
        // GIVEN
        guard let url = Bundle(for: type(of: self)).url(forResource: "video", withExtension:"mp4") else { return XCTFail() }
        let msg = createMessage(name!, uploadState: .uploadingThumbnail, thumbnail: mediumJPEGData(), url: url)
        
        let identifier = ZMTaskIdentifier(identifier: 12345, sessionIdentifier: "background-session")
        msg.associatedTaskIdentifier = identifier
        process(sut, message: msg)
        
        XCTAssertEqual(msg.genericAssetMessage?.asset.preview.hasImage(), true)
        guard let request = sut.nextRequest() else { return XCTFail() }
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 0)
        
        // WHEN
        msg.fileMessageData!.cancelTransfer()
        request.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN there should not be a running upload request as the upload failed by itself,
        // next request would be the Asset.NotUploaded request
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 0)
    }
    
    func testThatItCancelsCurrentlyRunningRequestWhenTheUploadIsCancelledAndItCreatesThe_NotUploaded_Request() {
        
        // GIVEN
        let msg = createMessage(name!, uploadState: .uploadingFullAsset)
        let identifier = ZMTaskIdentifier(identifier: 12345, sessionIdentifier: "background-session")
        msg.associatedTaskIdentifier = identifier
        process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 0)
        
        // WHEN
        msg.fileMessageData?.cancelTransfer()
        sut.objectsDidChange(Set(arrayLiteral: msg))
        request.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 0, transportSessionError: NSError.tryAgainLaterError() as Error))
        
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        guard let _ = sut.nextRequest() else { return XCTFail("Request was nil") } // Asset.NotUploaded
        
        // THEN
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 1)
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.first, identifier)
    }
    
    func testThatItUpdatesTheAssociatedTaskIdentifierWhenTheTaskHasBeenCreated_PlaceholderUpload() {
        // GIVEN
        let msg = createMessage(name!) // We did not yet generate the request to upload the Asset.Original
        process(sut, message: msg)
        
        // WHEN
        guard let originalRequest = sut.nextRequest() else { return XCTFail() } // Asset.Original
        originalRequest.callTaskCreationHandlers(withIdentifier: 42, sessionIdentifier: name!)
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNotNil(msg.associatedTaskIdentifier);
        XCTAssertEqual(msg.associatedTaskIdentifier?.sessionIdentifier, name);
        XCTAssertEqual(msg.associatedTaskIdentifier?.identifier, 42);
    }
    
    func testThatItUpdatesTheAssociatedTaskIdentifierWhenTheTaskHasBeenCreated_ThumbnailUpload() {
        // GIVEN
        guard let url = Bundle(for: type(of: self)).url(forResource: "video", withExtension:"mp4") else { return XCTFail() }
        let msg = createMessage(name!, uploadState: .uploadingThumbnail, thumbnail: mediumJPEGData(), url: url)
        process(sut, message: msg)
        
        // WHEN
        guard let originalRequest = sut.nextRequest() else { return XCTFail() } // Asset.Preview
        originalRequest.callTaskCreationHandlers(withIdentifier: 42, sessionIdentifier: name!)
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNotNil(msg.associatedTaskIdentifier);
        XCTAssertEqual(msg.associatedTaskIdentifier?.sessionIdentifier, name);
        XCTAssertEqual(msg.associatedTaskIdentifier?.identifier, 42);
    }
    
    func testThatItUpdatesTheAssociatedTaskIdentifierWhenTheTaskHasBeenCreated_FileDataUpload() {
        // GIVEN
        let msg = createMessage(name!, uploadState: .uploadingFullAsset) // We did  generate the request to upload the Asset.Original
        process(sut, message: msg)
        
        // WHEN
        guard let originalRequest = sut.nextRequest() else { return XCTFail() } // Asset.Uploaded
        originalRequest.callTaskCreationHandlers(withIdentifier: 42, sessionIdentifier: name!)
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNotNil(msg.associatedTaskIdentifier);
        XCTAssertEqual(msg.associatedTaskIdentifier?.sessionIdentifier, name);
        XCTAssertEqual(msg.associatedTaskIdentifier?.identifier, 42);
    }
    
    func testThatItResetTheAssociatedTaskIdentifierAfterThe_Placeholder_UploadCompleted_Successfully() {
        assertThatItResetsTheAssociatedTaskIdentifier(.uploadingPlaceholder, HTTPStatus: 200)
    }
    
    func testThatItResetTheAssociatedTaskIdentifierAfterThe_Placeholder_UploadCompleted_Failure() {
        assertThatItResetsTheAssociatedTaskIdentifier(.uploadingPlaceholder, HTTPStatus: 401)
    }
    
    func testThatItResetTheAssociatedTaskIdentifierAfterThe_Thumbnail_UploadCompleted_Succesfully() {
        assertThatItResetsTheAssociatedTaskIdentifier(.uploadingThumbnail, HTTPStatus: 200)
    }
    
    func testThatItResetTheAssociatedTaskIdentifierAfterThe_Thumbnail_UploadCompleted_Failure() {
        assertThatItResetsTheAssociatedTaskIdentifier(.uploadingThumbnail, HTTPStatus: 401)
    }
    
    func testThatItResetTheAssociatedTaskIdentifierAfterThe_FileData_UploadCompleted_Succesfully() {
        assertThatItResetsTheAssociatedTaskIdentifier(.uploadingFullAsset, HTTPStatus: 200)
    }
    
    func testThatItResetTheAssociatedTaskIdentifierAfterThe_FileData_UploadCompleted_Failure() {
        assertThatItResetsTheAssociatedTaskIdentifier(.uploadingFullAsset, HTTPStatus: 401)
    }
    
    func assertThatItResetsTheAssociatedTaskIdentifier(_ uploadState: ZMAssetUploadState, HTTPStatus: Int) {
        // GIVEN
        let msg: ZMAssetClientMessage
        if uploadState == .uploadingThumbnail {
            guard let url = Bundle(for: type(of: self)).url(forResource: "video", withExtension:"mp4") else { return XCTFail() }
            msg = createMessage(name!, uploadState: .uploadingThumbnail, thumbnail: mediumJPEGData(), url: url)
        } else {
            msg = createMessage(name!, uploadState: uploadState)
        }
        
        process(sut, message: msg)
        guard let originalRequest = sut.nextRequest() else { return XCTFail("Did not generate a request") }

        originalRequest.callTaskCreationHandlers(withIdentifier: 42, sessionIdentifier: name!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(msg.associatedTaskIdentifier);
        
        // WHEN
        originalRequest.complete(status: HTTPStatus)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNil(msg.associatedTaskIdentifier)
    }
    
    func testThatItGeneratesARequestWhenTheFileTransferIsSetTo_NotUploaded_Cancelled_PreviewNotYetUploaded() {
        
        // GIVEN
        let msg = createMessage(name!)
        process(sut, message: msg)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.uploading)
        
        // WHEN
        msg.fileMessageData?.cancelTransfer()
        
        // THEN
        XCTAssertEqual(msg.transferState, ZMFileTransferState.cancelledUpload)
        XCTAssertTrue(syncMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        guard let request = sut.nextRequest() else { return XCTFail("Request was nil") }
        guard let msgConversation = msg.conversation else { return XCTFail("Conversation was nil") }
        let expectedPath = "/conversations/\(msgConversation.remoteIdentifier!.transportString())/otr/messages"

        XCTAssertEqual(request.path, expectedPath)
        XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)

        guard let genericMessage = decryptedMessage(fromRequestData: request.binaryData!, forClient: otherClient) else { return XCTFail() }
        XCTAssertTrue(genericMessage.asset.hasNotUploaded())
        XCTAssertTrue(genericMessage.asset.hasOriginal())
        XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        XCTAssertFalse(genericMessage.asset.hasUploaded())
        
        // Asset should still be there in case we want to retry
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItGeneratesARequestWhenTheFileTransferIsSetTo_NotUploaded_Cancelled_ThumbnailUploading() {
        
        // GIVEN
        guard let url = Bundle(for: type(of: self)).url(forResource: "video", withExtension:"mp4") else { return XCTFail() }
        let msg = createMessage(name!, uploadState: .uploadingThumbnail, thumbnail: mediumJPEGData(), url: url)
        process(sut, message: msg)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.uploading)
        
        // WHEN
        msg.fileMessageData?.cancelTransfer()
        
        // THEN
        XCTAssertEqual(msg.transferState, ZMFileTransferState.cancelledUpload)
        XCTAssertTrue(syncMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        guard let request = sut.nextRequest() else { return XCTFail("Request was nil") }
        let expectedPath = "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages"

        XCTAssertEqual(request.path, expectedPath)
        XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
        
        guard let genericMessage = decryptedMessage(fromRequestData: request.binaryData!, forClient: otherClient) else { return XCTFail() }
        XCTAssertTrue(genericMessage.asset.hasNotUploaded())
        XCTAssertTrue(genericMessage.asset.hasOriginal())
        XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        XCTAssertFalse(genericMessage.asset.hasUploaded())
        
        // Asset should still be there in case we want to retry
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItGeneratesARequestWhenTheFileTransferIsSetTo_NotUploaded_Cancelled_ThumbnailUploaded_Video() {
        
        // GIVEN
        guard let url = Bundle(for: type(of: self)).url(forResource: "video", withExtension:"mp4") else { return XCTFail() }
        let msg = createMessage(name!, uploadState: .uploadingFullAsset, thumbnail: mediumJPEGData(), url: url)
        process(sut, message: msg)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.uploading)
        
        // WHEN
        msg.fileMessageData?.cancelTransfer()
        
        // THEN
        XCTAssertEqual(msg.transferState, ZMFileTransferState.cancelledUpload)
        XCTAssertTrue(syncMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        guard let request = sut.nextRequest() else { return XCTFail("Request was nil") }
        let expectedPath = "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages"

        XCTAssertEqual(request.path, expectedPath)
        XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)
        
        guard let genericMessage = decryptedMessage(fromRequestData: request.binaryData!, forClient: otherClient) else { return XCTFail() }
        XCTAssertTrue(genericMessage.asset.hasNotUploaded())
        XCTAssertTrue(genericMessage.asset.hasOriginal())
        XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        XCTAssertFalse(genericMessage.asset.hasUploaded())
        
        // Asset should still be there in case we want to retry
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItGeneratesARequestWhenTheFileTransferIsSetTo_NotUploaded_Cancelled_PreviewUploaded() {
        
        // GIVEN
        let msg = createMessage(name!, uploadState: .uploadingFullAsset)
        process(sut, message: msg)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.uploading)
        
        // WHEN
        msg.fileMessageData?.cancelTransfer()
        
        // THEN
        XCTAssertEqual(msg.transferState, ZMFileTransferState.cancelledUpload)
        XCTAssertTrue(syncMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        guard let request = sut.nextRequest() else { return XCTFail("Request was nil") }
        let expectedPath = "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages"
        XCTAssertEqual(request.path, expectedPath)
        XCTAssertEqual(request.method, ZMTransportRequestMethod.methodPOST)

        guard let genericMessage = decryptedMessage(fromRequestData: request.binaryData!, forClient: otherClient) else { return XCTFail() }
        XCTAssertTrue(genericMessage.asset.hasNotUploaded())
        XCTAssertTrue(genericMessage.asset.hasOriginal())
        XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        XCTAssertFalse(genericMessage.asset.hasUploaded())
        
        // Asset should still be there in case we want to retry
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItGeneratesARequestWhenTheFileTransferIsSetTo_NotUploaded_Cancelled_PreviewAndOriginalUploaded() {
        
        // GIVEN
        let msg = createMessage(name!, uploadState: .uploadingFullAsset)
        process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail("Should return the request to upload Asset.Uploaded") }
        XCTAssertEqual(msg.transferState, ZMFileTransferState.uploading)
        
        // WHEN
        msg.fileMessageData?.cancelTransfer()
        sut.objectsDidChange(Set(arrayLiteral: msg))
        request.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: 0, transportSessionError: NSError.tryAgainLaterError() as Error))
        
        // THEN
        XCTAssertEqual(msg.transferState, ZMFileTransferState.cancelledUpload)
        XCTAssertTrue(syncMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        guard let secondRequest = sut.nextRequest() else { return XCTFail("Request was nil") }
        let expectedPath = "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages"
        XCTAssertEqual(secondRequest.path, expectedPath)
        XCTAssertEqual(secondRequest.method, ZMTransportRequestMethod.methodPOST)
        
        guard let genericMessage = decryptedMessage(fromRequestData: secondRequest.binaryData!, forClient: otherClient) else { return XCTFail() }
        XCTAssertTrue(genericMessage.asset.hasNotUploaded())
        XCTAssertTrue(genericMessage.asset.hasOriginal())
        XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        XCTAssertFalse(genericMessage.asset.hasUploaded())
        
        // Asset should still be there in case we want to retry
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItCreatesARequestToUploadA_NotUploaded_WhenTheFileDataFailsToUpload() {
        
        // GIVEN
        let msg = createMessage(name!, uploadState: .uploadingFullAsset)
        
        process(sut, message: msg)
        guard let uploadedRequest = sut.nextRequest() else { return XCTFail("Should return the request to upload Asset.Uploaded") }
        XCTAssertEqual(msg.transferState, ZMFileTransferState.uploading)
        
        // WHEN
        uploadedRequest.complete(status: 401)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        guard let notUploadedRequest = sut.nextRequest() else { return XCTFail("Request was nil") }
        let expectedPath = "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages"

        XCTAssertEqual(notUploadedRequest.path, expectedPath)
        XCTAssertEqual(notUploadedRequest.method, ZMTransportRequestMethod.methodPOST)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.failedUpload)
        
        guard let genericMessage = decryptedMessage(fromRequestData: notUploadedRequest.binaryData!, forClient: otherClient) else { return XCTFail() }
        XCTAssertTrue(genericMessage.asset.hasNotUploaded())
        XCTAssertTrue(genericMessage.asset.hasOriginal())
        XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.FAILED)
        XCTAssertFalse(genericMessage.asset.hasUploaded())
        
        // Encrypted Asset should still be there in case we want to retry
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: false))
        XCTAssertNil(sut.nextRequest())
    }
    
    
    // MARK: - Decryption Helper
    
    func decryptedMessage(fromRequestData data: Data, forClient client: UserClient) -> ZMGenericMessage? {
        let otrMessage = ZMNewOtrMessage.builder().merge(from: data).build() as? ZMNewOtrMessage
        XCTAssertNotNil(otrMessage, "Unable to generate OTR message")
        let clientEntries = otrMessage?.recipients.flatMap { $0.clients }.joined()
        XCTAssertEqual(clientEntries?.count, 1)
        
        guard let entry = clientEntries?.first else { XCTFail("Unable to get client entry"); return nil }
        guard let decryptedData = self.decryptMessageFromSelf(cypherText: entry.text, to: client) else {
            XCTFail()
            return nil
        }
        
        return ZMGenericMessage.builder().merge(from: decryptedData).build() as? ZMGenericMessage
    }

    func testThatItRemovesDeletedClients() {
        
        // GIVEN
        let msg = createMessage("foo")

        // client and user
        let user = ZMUser.insertNewObject(in: self.syncMOC)
        user.remoteIdentifier = UUID.create()
        let client = UserClient.insertNewObject(in: self.syncMOC)
        client.remoteIdentifier = "abc123123"
        client.user = user
        
        self.syncMOC.saveOrRollback()
        XCTAssertEqual(user.clients.count, 1)
        
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        
        // payload
        let payload: [String : Any] = [
            "time" : "2015-03-11T09:34:00.436Z",
            "deleted" : [
                user.remoteIdentifier!.transportString() : [
                    client.remoteIdentifier!
                ]
            ],
        ]
        
        // WHEN
        request.complete(with: ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 200, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertEqual(user.clients.count, 0)
    }
    
    func testThatItAddMissingClients() {
        
        // GIVEN
        let msg = createMessage("foo")
        let clientID = "1234567abc"
        
        // user
        let user = ZMUser.insertNewObject(in: self.syncMOC)
        user.remoteIdentifier = UUID.create()
        
        self.syncMOC.saveOrRollback()
        XCTAssertEqual(user.clients.count, 0)
        
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        
        // payload
        let payload = [
            "missing" : [
                user.remoteIdentifier!.transportString() : [
                    clientID
                ]
            ]
        ]
        
        // WHEN
        request.complete(with: ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 412, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        if let client = user.clients.first {
            XCTAssertEqual(client.remoteIdentifier, clientID)
        } else {
            XCTFail()
        }
    }
    
    func testThatAMessageWithMissingClientsDependsOnThoseClients() {
        
        // GIVEN
        var request: ZMTransportRequest?
        var payload: ZMTransportData!
        var message: ZMAssetClientMessage!
        self.syncMOC.performGroupedBlockAndWait {
            
            message = self.createMessage("foo")
            let clientID = "1234567abc"
            
            // user
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = UUID.create()
            
            self.syncMOC.saveOrRollback()
            XCTAssertEqual(user.clients.count, 0)

            payload = [
                "missing" : [
                    user.remoteIdentifier!.transportString() : [
                        clientID
                    ]
                ]
                ] as NSDictionary

        }
        
        self.process(self.sut, message: message)
        self.syncMOC.performGroupedBlockAndWait {
            request = self.sut.nextRequest()
        }
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait {
            request?.complete(with: ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: 412, transportSessionError: nil))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            
            let nextRequest = self.sut.nextRequest()
            XCTAssertNil(nextRequest)
        }
    }
}

// MARK: - Preprocessing
extension FileUploadRequestStrategyTests {

    func testThatItPreprocessMessages() {
        
        // GIVEN
        let msg = createMessage("foo")
        XCTAssertFalse(msg.isReadyToUploadFile)
        
        // WHEN
        sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set(arrayLiteral: msg)) }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    
        // THEN after processing it should set 'needsToUploadPreview' to true
        XCTAssertTrue(msg.isReadyToUploadFile)
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: "foo", encrypted:true))
    }
    
    func testThatItPreprocessesAFileMessageAndGeneratesTheThumbnail() {
        
        // GIVEN
        guard let url = Bundle(for: type(of: self)).url(forResource: "video", withExtension:"mp4") else { return XCTFail() }
        let message = createMessage(name!, thumbnail: mediumJPEGData(), url: url)
        
        // WHEN
        sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set(arrayLiteral: message)) }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    
        // THEN
        XCTAssertEqual(message.genericAssetMessage?.asset.hasPreview(), true)
        guard let preview = message.genericAssetMessage?.asset.preview else { return XCTFail("Unable to get the preview") }
        
        let encrypted = syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true)
        let decrypted = syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: false)
        
        XCTAssertNotNil(decrypted)
        XCTAssertNotNil(encrypted)
        
        let (otrKey, sha256) = (preview.remote.otrKey, preview.remote.sha256)
        
        XCTAssertEqual(encrypted?.zmSHA256Digest(), sha256)
        XCTAssertEqual(decrypted, encrypted?.zmDecryptPrefixedPlainTextIV(key: otrKey!))
        
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .preview, encrypted: false))
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .preview, encrypted: true))
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .original, encrypted: false))
        
        XCTAssertTrue(preview.hasImage())
        XCTAssertTrue(preview.image.width > 0)
    }
    
    func testThatItDoesNotPreprocessAFileMessageAndGeneratesThePreviewIfTheMessageIsNotAVideo() {
        // GIVEN
        let message = createMessage(name!)
        
        // WHEN
        sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set(arrayLiteral: message)) }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertEqual(message.genericAssetMessage?.asset.hasPreview(), false)
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true))
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: false))
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .preview, encrypted: false))
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .preview, encrypted: true))
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .original, encrypted: false))
    }
    
    func testThatItDoesNotGeneratePreviewsForImageMessages() {
        // GIVEN
        let messageNonce = UUID.create()
        let message = self.groupConversation.appendOTRMessage(withImageData: mediumJPEGData(), nonce: messageNonce)
        
        // WHEN
        sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set(arrayLiteral: message)) }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertNil(message.genericAssetMessage)
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true))
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: false))
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .preview, encrypted: false))
        XCTAssertNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .preview, encrypted: true))
        
        XCTAssertNotNil(syncMOC.zm_imageAssetCache.assetData(message.nonce, format: .original, encrypted: false))
    }
}


// MARK: - Ephemeral
extension FileUploadRequestStrategyTests {

    func testThatItPreprocessesEphemeralMessages() {
        
        // GIVEN
        let msg = createMessage("foo", isEphemeral: true)
        XCTAssertFalse(msg.isReadyToUploadFile)
        
        // WHEN
        sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set(arrayLiteral: msg)) }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN after processing it should set 'needsToUploadPreview' to true
        XCTAssertTrue(msg.isReadyToUploadFile)
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: "foo", encrypted:true))
    }
}


extension ZMTransportRequest {
    
    fileprivate func complete(status: Int) {
        self.complete(with: ZMTransportResponse(payload: [] as ZMTransportData, httpStatus: status, transportSessionError: nil))
    }
}
