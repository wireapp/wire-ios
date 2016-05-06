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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation
@testable import zmessaging

// MARK: - Fakes
private class FakeAuthStatus : AuthenticationStatusProvider {
    
    var mockedPhase : ZMAuthenticationPhase = .Authenticated
        
    @objc var currentPhase : ZMAuthenticationPhase {
        return self.mockedPhase
    }
}

@objc class FakeClientRegistrationStatus : NSObject, ZMClientClientRegistrationStatusProvider {
    
    var readyToUse : Bool = true
    
    var currentClientReadyToUse : Bool {
        return self.readyToUse
    }
    
    func didDetectCurrentClientDeletion() {
        // noop
    }
}

private class FakeCancelationProvider : NSObject, ZMRequestCancellation {
    
    var cancelledIdentifiers = [ZMTaskIdentifier]()
    
    @objc func cancelTaskWithIdentifier(identifier: ZMTaskIdentifier) {
        cancelledIdentifiers.append(identifier)
    }
}

@objc class FakeZMURLSessionDelegate: NSObject, ZMURLSessionDelegate {
    @objc func URLSessionDidReceiveData(URLSession: ZMURLSession) {}
    @objc func URLSession(URLSession: ZMURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse: NSURLResponse, completionHandler: NSURLSessionResponseDisposition -> Void) {}
    @objc func URLSessionDidFinishEventsForBackgroundURLSession(URLSession: ZMURLSession) {}
    @objc func URLSession(URLSession: ZMURLSession, taskDidComplete: NSURLSessionTask, transportRequest: ZMTransportRequest, responseData:NSData) {}
}

private let testDataURL = NSBundle(forClass: FilePreprocessorTests.self).URLForResource("Lorem Ipsum", withExtension: "txt")!
private let testData = NSData(contentsOfURL: testDataURL)!

// MARK: - Tests setup
@objc class FileUploadRequestStrategyTests: MessagingTest {

    private var sut: FileUploadRequestStrategy!
    private var authStatus: FakeAuthStatus!
    private var cancellationProvider: FakeCancelationProvider!
	private var clientRegistrationStatus : FakeClientRegistrationStatus!
    
    override func setUp() {
        super.setUp()
        createSelfClient()
        self.authStatus = FakeAuthStatus()
        self.cancellationProvider = FakeCancelationProvider()
		self.clientRegistrationStatus = FakeClientRegistrationStatus()
        self.sut = FileUploadRequestStrategy(
            authenticationStatus: self.authStatus,
			clientRegistrationStatus: self.clientRegistrationStatus,
            managedObjectContext: self.syncMOC,
            taskCancellationProvider: self.cancellationProvider
        )
    }
    
    /// Creates a message that should generate request
    func createMessage(name: String, previewUploaded: Bool = false, inConversation: ZMConversation? = nil) -> ZMAssetClientMessage {
        let conversation = inConversation ?? ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
        conversation!.remoteIdentifier = NSUUID.createUUID()
        let msg = conversation!.appendMessageWithFileAtURL(testDataURL) as! ZMAssetClientMessage
        if previewUploaded {
            msg.setNeedsToUploadData(.Placeholder, needsToUpload: false)
            msg.setNeedsToUploadData(.FileData, needsToUpload: true)
        }
        self.syncMOC.saveOrRollback()
        return msg
    }
    
    func createOtherClientAndConversation() -> (UserClient, ZMConversation) {
        let otherUser = ZMUser.insertNewObjectInManagedObjectContext(syncMOC)
        otherUser.remoteIdentifier = .createUUID()
        let otherClient = createClientForUser(otherUser, createSessionWithSelfUser: true)
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(syncMOC)
        conversation.conversationType = .Group
        conversation.addParticipant(otherUser)
        XCTAssertTrue(syncMOC.saveOrRollback())
        
        return (otherClient, conversation)
    }
    
    func zmurlSessionWithIdentifier(id: String) -> ZMURLSession {
        return ZMURLSession(configuration: .defaultSessionConfiguration(), delegate: FakeZMURLSessionDelegate(), delegateQueue: .mainQueue(), identifier: id)
    }

    /// Forces the strategy to process the message
    func process(strategy: FileUploadRequestStrategy, message: ZMAssetClientMessage) {
        // first change will start preprocessing
        strategy.contextChangeTrackers.forEach { $0.objectsDidChange(Set(arrayLiteral: message)) }
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // second change will make it be picked up by uploader
        strategy.contextChangeTrackers.forEach { $0.objectsDidChange(Set(arrayLiteral: message)) }
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
    
    func completeRequest(request: ZMTransportRequest?, HTTPStatus: Int) {
        request?.completeWithResponse(ZMTransportResponse(payload: nil, HTTPstatus: HTTPStatus, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
}

// MARK: - Request generation
extension FileUploadRequestStrategyTests {

    func testThatItGeneratesARequestForAFileMessageThatIsPreprocessed() {
        
        // given
        let (otherClient, conversation) = createOtherClientAndConversation()

        let msg = createMessage("foo", inConversation: conversation)
        self.process(sut, message: msg)
        
        // when
        let placeholderRequest = sut.nextRequest() // Asset.Original request (message-add)
        
        guard let msgConversation = msg.conversation else { return XCTFail("message conversation was nil") }
        
        // then
        XCTAssertNotNil(placeholderRequest)
        guard let requestUploaded = placeholderRequest else { return XCTFail() }
        XCTAssertEqual(requestUploaded.path, "/conversations/\(msgConversation.remoteIdentifier.transportString())/otr/messages")
        XCTAssertEqual(requestUploaded.method, ZMTransportRequestMethod.MethodPOST)
        
        guard let genericMessage = decryptedMessage(fromRequestData: requestUploaded.binaryData, forClient: otherClient) else { return XCTFail() }
        XCTAssertFalse(genericMessage.asset.hasNotUploaded())
        XCTAssertTrue(genericMessage.asset.hasOriginal())
        let original = genericMessage.asset.original
        XCTAssertEqual(original.name, msg.filename)
        XCTAssertEqual(original.mimeType, msg.mimeType)
        XCTAssertEqual(original.size, msg.size)
        XCTAssertFalse(genericMessage.asset.hasUploaded())
    }
    
    func testThatItSets_NeedsToUploadMedium_OnMessageWhenAssetOriginalRequestCompletesSuccesfully() {
        
        // given
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        XCTAssertFalse(msg.needsToUploadMedium)
        XCTAssertTrue(msg.needsToUploadPreview)
        
        // when
        let placeholderRequest = sut.nextRequest() // Asset.Original request (message-add)
        completeRequest(placeholderRequest, HTTPStatus: 201)
        
        // then
        XCTAssertTrue(msg.needsToUploadMedium)
        XCTAssertFalse(msg.needsToUploadPreview)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.Uploading)
    }
    
    func testThatItDoesNotGeneratesARequestWhenNotAuthenticated() {
        
        // given
		self.authStatus.mockedPhase = .Unauthenticated
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        
        // when
        let reqUploaded = sut.nextRequest() // uploaded
        
        // then
        XCTAssertNil(reqUploaded)
    }
    
    func testThatItDoesNotGeneratesARequestWhenStillRegisteringClient() {
        
        // given
		self.clientRegistrationStatus.readyToUse = false
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        
        // when
        let reqUploaded = sut.nextRequest() // uploaded
        
        // then
        XCTAssertNil(reqUploaded)
    }
    
    func testThatItDoesNotGenerateARequestForTheNextMessageWhenThereIsAPreviousOriginalBeingUploaded() {
        
        // given
        let msg1 = createMessage("foo")
        self.process(sut, message: msg1)
        let msg2 = createMessage("foo", inConversation: msg1.conversation)
        self.process(sut, message: msg2)
        
        // when
        _ = sut.nextRequest() // original
        let nextRequest = sut.nextRequest()
        
        
        // then
        XCTAssertNil(nextRequest)
    }
    
    func testThatItGeneratesRequestForTheNextMessageWhenThereIsAPreviousFileBeingUploaded() {
        
        // given
        let msg1 = createMessage("foo")
        self.process(sut, message: msg1)
        
        guard let msg1Conversation = msg1.conversation else { return XCTFail("message conversation was nil") }
        
        // first request: msg1 original
        let msg1Original = sut.nextRequest() // original
        XCTAssertEqual(msg1Original?.path, "/conversations/\(msg1Conversation.remoteIdentifier.transportString())/otr/messages")
        
        // when
        msg1Original?.completeWithResponse(ZMTransportResponse(payload: nil, HTTPstatus: 200, transportSessionError: nil))
        XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        self.syncMOC.saveOrRollback()
        self.process(sut, message: msg1)
        
        // second request: msg1 file
        let msg1File = sut.nextRequest()
        XCTAssertEqual(msg1File?.path, "/conversations/\(msg1Conversation.remoteIdentifier.transportString())/otr/assets")
        
        // Given 
        let msg2 = createMessage("foo", inConversation: msg1.conversation)
        self.process(sut, message: msg2)
        
        // third request: msg2 original
        let msg2Original = sut.nextRequest()
        XCTAssertEqual(msg2Original?.path, "/conversations/\(msg1Conversation.remoteIdentifier.transportString())/otr/messages")
        msg2Original?.completeWithResponse(ZMTransportResponse(payload: nil, HTTPstatus: 200, transportSessionError: nil))
        XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        self.syncMOC.saveOrRollback()
        self.process(sut, message: msg1)
    }
}

// MARK: - Parse response
extension FileUploadRequestStrategyTests {
    
    func testThatItMarksAnUploadedFile() {
        
        // given
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        XCTAssertFalse(msg.needsToUploadMedium)
        XCTAssertTrue(msg.needsToUploadPreview)
        
        // when
        let placeholderRequest = sut.nextRequest() // Asset.Original request (message-add)
        completeRequest(placeholderRequest, HTTPStatus: 400)
        
        // then
        XCTAssertEqual(msg.transferState, ZMFileTransferState.FailedUpload)
        XCTAssertFalse(msg.needsToUploadPreview)
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItDoesGenerateTheRequestToUploadTheMediumAfterThePreviewCompletedSuccessfully() {
        
        // given
        let (otherClient, conversation) = createOtherClientAndConversation()
        let msg = createMessage("foo", inConversation: conversation)
        self.process(sut, message: msg)
        XCTAssertFalse(msg.needsToUploadMedium)
        XCTAssertTrue(msg.needsToUploadPreview)
        
        // when
        let placeholderRequest = sut.nextRequest() // Asset.Original request (message-add)
        completeRequest(placeholderRequest, HTTPStatus: 201)
        let uploadedRequest = sut.nextRequest() // Uploaded request (asset-add)
        syncMOC.saveOrRollback()

        guard let msgConversation = msg.conversation else { return XCTFail("Conversation was nil") }
        
        // then
        XCTAssertNotNil(placeholderRequest)
        XCTAssertNotNil(uploadedRequest)
        XCTAssertNotNil(uploadedRequest?.fileUploadURL)
        XCTAssertEqual(uploadedRequest?.path, "/conversations/\(msgConversation.remoteIdentifier.transportString())/otr/assets")
     
        guard let request = uploadedRequest,
            let requestMultipart = NSData(contentsOfURL: request.fileUploadURL) else {
                return XCTFail("No data at fileUploadURL")
        }
        let genericPartData = requestMultipart.multipartDataItemsSeparatedWithBoundary("frontier").first as! ZMMultipartBodyItem
        guard let genericMessage = decryptedMessage(fromRequestData: genericPartData.data, forClient: otherClient) else { return XCTFail() }
        XCTAssertFalse(genericMessage.asset.hasNotUploaded())
        XCTAssertTrue(genericMessage.asset.hasOriginal())
        XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        XCTAssertTrue(genericMessage.asset.hasUploaded())
    }
    
    func testThatItDoesNotSet_NeedsToUploadMedium_OnMessageWhenAssetOriginalRequestCompletesUnsuccessfully() {
        
        // given
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        XCTAssertFalse(msg.needsToUploadMedium)
        XCTAssertTrue(msg.needsToUploadPreview)
        
        // when
        let placeholderRequest = sut.nextRequest() // Asset.Original request (message-add)
        completeRequest(placeholderRequest, HTTPStatus: 400)
        
        // then
        XCTAssertEqual(msg.transferState, ZMFileTransferState.FailedUpload)
        XCTAssertFalse(msg.needsToUploadPreview)
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItUpdatesTheMessageWithTheAssetIDFromTheUploadedReponseHeader() {
        
        // given
        let msg = createMessage(name!, previewUploaded: true)
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        
        // when
        let assetId = NSUUID.createUUID()
        let response = ZMTransportResponse(payload: nil, HTTPstatus: 200, transportSessionError: nil, headers: ["Location": assetId.transportString()])
        request.completeWithResponse(response)
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertTrue(msg.delivered)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.Downloaded)
        XCTAssertEqual(msg.assetId, assetId)
    }
    
    func testThatItDeletesDataForAnUploadedFile() {
        
        // given
        let msg = createMessage(name!, previewUploaded: true)
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: nil, HTTPstatus: 200, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
    }
    
    func testThatItMarksAFailedFile_OriginalFailed() {
        
        // given
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: nil, HTTPstatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertFalse(msg.delivered)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.FailedUpload)
    }
    
    func testThatItMarksAFailedFile_UploadedFailed() {
        
        // given
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: nil, HTTPstatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertFalse(msg.delivered)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.FailedUpload)
    }
    
    func testThatItMarksAFailedFile_UploadedFailed_TemporaryError() {
        
        // given
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: nil, HTTPstatus: 500, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertFalse(msg.delivered)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.FailedUpload)
    }
    
    func testThatItDeletesDataForAFailedFile_OriginalFailed() {
        
        // given
        let msg = createMessage(name!)
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: nil, HTTPstatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
    }
    
    func testThatItDeletesUnencryptedDataForAFailedFile_UploadedFailed() {
        
        // given
        let msg = createMessage(name!, previewUploaded: true)
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: nil, HTTPstatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: false))
    }
    
    func testThatItSendsNotificaitonForAnUploadedFile() {
        
        // given
        let msg = createMessage(name!, previewUploaded: true)
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        
        request.markStartOfUploadTimestamp()
        let notificationExpectation = self.expectationWithDescription("Notification fired")
        
        let _ = NSNotificationCenter.defaultCenter().addObserverForName(FileUploadRequestStrategyNotification.uploadFinishedNotificationName, object: nil, queue: .mainQueue()) { notification in
            XCTAssertNotNil(notification.userInfo![FileUploadRequestStrategyNotification.requestStartTimestampKey])
            notificationExpectation.fulfill()
        }
        // when
        let assetId = NSUUID.createUUID()
        let response = ZMTransportResponse(payload: nil, HTTPstatus: 200, transportSessionError: nil, headers: ["Location": assetId.transportString()])
        request.completeWithResponse(response)
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
    }
    
    func testThatItSendsNotificaitonForAFailedFile() {
        
        // given
        let msg = createMessage("foo")
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        request.markStartOfUploadTimestamp()
        let notificationExpectation = self.expectationWithDescription("Notification fired")
        
        let _ = NSNotificationCenter.defaultCenter().addObserverForName(FileUploadRequestStrategyNotification.uploadFailedNotificationName, object: nil, queue: .mainQueue()) { notification in
            XCTAssertNotNil(notification.userInfo![FileUploadRequestStrategyNotification.requestStartTimestampKey])
            notificationExpectation.fulfill()
        }
        // when
        request.completeWithResponse(ZMTransportResponse(payload: nil, HTTPstatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
    }
    
    func testThatItDoesNotCancelCurrentlyRunningRequestWhenTheUploadFails() {
        
        // given
        let msg = createMessage(name!, previewUploaded: true)
        let identifier = ZMTaskIdentifier(identifier: 12345, sessionIdentifier: "background-session")
        msg.associatedTaskIdentifier = identifier
        process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 0)
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: nil, HTTPstatus: 400, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then there should not be a running upload request as the upload failed by itself,
        // next request would be the Asset.NotUploaded request
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 0)
    }
    
    func testThatItCancelsCurrentlyRunningRequestWhenTheUploadIsCancelledAndItCreatesThe_NotUploaded_Request() {
        
        // given
        let msg = createMessage(name!, previewUploaded: true)
        let identifier = ZMTaskIdentifier(identifier: 12345, sessionIdentifier: "background-session")
        msg.associatedTaskIdentifier = identifier
        process(sut, message: msg)
        guard let _ = sut.nextRequest() else { return XCTFail() }
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 0)
        
        // when
        msg.fileMessageData!.cancelTransfer()
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        
        guard let _ = sut.nextRequest() else { return XCTFail("Request was nil") } // Asset.NotUploaded
        
        // then
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.count, 1)
        XCTAssertEqual(cancellationProvider.cancelledIdentifiers.first, identifier)
    }
    
    func testThatItUpdatesTheAssociatedTaskIdentifierWhenTheTaskHasBeenCreated_PlaceholderUpload() {
        // given
        let msg = createMessage(name!, previewUploaded: false) // We did not yet generate the request to upload the Asset.Original
        process(sut, message: msg)
        
        // when
        guard let originalRequest = sut.nextRequest() else { return XCTFail() } // Asset.Original
        // We need a valid instance of a NSURLSessionTask here in order to have it return a taskIdentifier
        let task = NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: originalRequest.path)!)
        originalRequest.callTaskCreationHandlersWithTask(task, session: zmurlSessionWithIdentifier(name!))
        
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertNotNil(msg.associatedTaskIdentifier);
        XCTAssertEqual(msg.associatedTaskIdentifier?.sessionIdentifier, name);
        XCTAssertEqual(msg.associatedTaskIdentifier?.identifier, UInt(task.taskIdentifier));
    }
    
    func testThatItUpdatesTheAssociatedTaskIdentifierWhenTheTaskHasBeenCreated_FileDataUpload() {
        // given
        let msg = createMessage(name!, previewUploaded: true) // We did  generate the request to upload the Asset.Original
        process(sut, message: msg)
        
        // when
        guard let originalRequest = sut.nextRequest() else { return XCTFail() } // Asset.Uploaded
        // We need a valid instance of a NSURLSessionTask here in order to have it return a taskIdentifier
        let task = NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: originalRequest.path)!)
        originalRequest.callTaskCreationHandlersWithTask(task, session: zmurlSessionWithIdentifier(name!))
        
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertNotNil(msg.associatedTaskIdentifier);
        XCTAssertEqual(msg.associatedTaskIdentifier?.sessionIdentifier, name);
        XCTAssertEqual(msg.associatedTaskIdentifier?.identifier, UInt(task.taskIdentifier));
    }
    
    func testThatItResetTheAssociatedTaskIdentifierAfterThe_Placeholder_UploadCompleted_Successfully() {
        assertThatItRestsTheAssociatedTaskIdentifier(false, HTTPStatus: 200)
    }
    
    func testThatItResetTheAssociatedTaskIdentifierAfterThe_Placeholder_UploadCompleted_Failure() {
        assertThatItRestsTheAssociatedTaskIdentifier(false, HTTPStatus: 401)
    }
    
    func testThatItResetTheAssociatedTaskIdentifierAfterThe_FilaData_UploadCompleted_Succesfully() {
        assertThatItRestsTheAssociatedTaskIdentifier(true, HTTPStatus: 200)
    }
    
    func testThatItResetTheAssociatedTaskIdentifierAfterThe_FilaData_UploadCompleted_Failure() {
        assertThatItRestsTheAssociatedTaskIdentifier(true, HTTPStatus: 401)
    }
    
    func assertThatItRestsTheAssociatedTaskIdentifier(previewAlreadyUploaded: Bool, HTTPStatus: Int) {
        // given
        let msg = createMessage(name!, previewUploaded: previewAlreadyUploaded)
        process(sut, message: msg)
        guard let originalRequest = sut.nextRequest() else { return XCTFail("Did not generate a request") }
        
		// We need a valid instance of a NSURLSessionTask here in order to have it return a taskIdentifier
        let task = NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: originalRequest.path)!)
        originalRequest.callTaskCreationHandlersWithTask(task, session: zmurlSessionWithIdentifier(name!))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        XCTAssertNotNil(msg.associatedTaskIdentifier);
        
        // when
        completeRequest(originalRequest, HTTPStatus: HTTPStatus)
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertNil(msg.associatedTaskIdentifier)
    }
    
    func testThatItGeneratesARequestWhenTheFileTransferIsSetTo_NotUploaded_Cancelled_PreviewNotYetUploaded() {
        
        // given
        let (otherClient, conversation) = createOtherClientAndConversation()
        let msg = createMessage(name!, previewUploaded: false, inConversation: conversation)
        process(sut, message: msg)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.Uploading)
        
        // when
        msg.fileMessageData!.cancelTransfer()
        
        // then
        XCTAssertEqual(msg.transferState, ZMFileTransferState.CancelledUpload)
        XCTAssertTrue(syncMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        guard let request = sut.nextRequest() else { return XCTFail("Request was nil") }
        guard let msgConversation = msg.conversation else { return XCTFail("message conversation was nil") }

        let expectedPath = "/conversations/\(msgConversation.remoteIdentifier.transportString())/otr/messages"
        XCTAssertEqual(request.path, expectedPath)
        XCTAssertEqual(request.method, ZMTransportRequestMethod.MethodPOST)

        guard let genericMessage = decryptedMessage(fromRequestData: request.binaryData, forClient: otherClient) else { return XCTFail() }
        XCTAssertTrue(genericMessage.asset.hasNotUploaded())
        XCTAssertTrue(genericMessage.asset.hasOriginal())
        XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        XCTAssertFalse(genericMessage.asset.hasUploaded())
        
        // Asset should still be there in case we want to retry
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItGeneratesARequestWhenTheFileTransferIsSetTo_NotUploaded_Cancelled_PreviewUploaded() {
        
        // given
        let (otherClient, conversation) = createOtherClientAndConversation()
        let msg = createMessage(name!, previewUploaded: true, inConversation: conversation)
        process(sut, message: msg)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.Uploading)
        
        // when
        msg.fileMessageData!.cancelTransfer()
        
        // then
        XCTAssertEqual(msg.transferState, ZMFileTransferState.CancelledUpload)
        XCTAssertTrue(syncMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        guard let request = sut.nextRequest() else { return XCTFail("Request was nil") }
        guard let msgConversation = msg.conversation else { return XCTFail("message conversation was nil") }
            
        let expectedPath = "/conversations/\(msgConversation.remoteIdentifier.transportString())/otr/messages"
        XCTAssertEqual(request.path, expectedPath)
        XCTAssertEqual(request.method, ZMTransportRequestMethod.MethodPOST)

        guard let genericMessage = decryptedMessage(fromRequestData: request.binaryData, forClient: otherClient) else { return XCTFail() }
        XCTAssertTrue(genericMessage.asset.hasNotUploaded())
        XCTAssertTrue(genericMessage.asset.hasOriginal())
        XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        XCTAssertFalse(genericMessage.asset.hasUploaded())
        
        // Asset should still be there in case we want to retry
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItGeneratesARequestWhenTheFileTransferIsSetTo_NotUploaded_Cancelled_PreviewAndOriginalUploaded() {
        
        // given
        let (otherClient, conversation) = createOtherClientAndConversation()
        let msg = createMessage(name!, previewUploaded: true, inConversation: conversation)
        process(sut, message: msg)
        guard let _ = sut.nextRequest() else { return XCTFail("Should return the request to upload Asset.Uploaded") }
        XCTAssertEqual(msg.transferState, ZMFileTransferState.Uploading)
        
        // when
        msg.fileMessageData!.cancelTransfer()
        
        // then
        XCTAssertEqual(msg.transferState, ZMFileTransferState.CancelledUpload)
        XCTAssertTrue(syncMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        guard let request = sut.nextRequest() else { return XCTFail("Request was nil") }
        guard let msgConversation = msg.conversation else { return XCTFail("message conversation was nil") }

        let expectedPath = "/conversations/\(msgConversation.remoteIdentifier.transportString())/otr/messages"
        XCTAssertEqual(request.path, expectedPath)
        XCTAssertEqual(request.method, ZMTransportRequestMethod.MethodPOST)
        
        guard let genericMessage = decryptedMessage(fromRequestData: request.binaryData, forClient: otherClient) else { return XCTFail() }
        XCTAssertTrue(genericMessage.asset.hasNotUploaded())
        XCTAssertTrue(genericMessage.asset.hasOriginal())
        XCTAssertEqual(genericMessage.asset.notUploaded, ZMAssetNotUploaded.CANCELLED)
        XCTAssertFalse(genericMessage.asset.hasUploaded())
        
        // Asset should still be there in case we want to retry
        XCTAssertNotNil(syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: msg.filename!, encrypted: true))
        XCTAssertNil(sut.nextRequest())
    }
    
    func testThatItCreatesARequestToUploadA_NotUploaded_WhenTheFileDataFailsToUpload() {
        
        // given
        let (otherClient, conversation) = createOtherClientAndConversation()
        let msg = createMessage(name!, previewUploaded: true, inConversation: conversation)
        
        process(sut, message: msg)
        guard let uploadedRequest = sut.nextRequest() else { return XCTFail("Should return the request to upload Asset.Uploaded") }
        XCTAssertEqual(msg.transferState, ZMFileTransferState.Uploading)
        
        // when
        completeRequest(uploadedRequest, HTTPStatus: 401)
        
        // then
        guard let notUploadedRequest = sut.nextRequest() else { return XCTFail("Request was nil") }
        guard let msgConversation = msg.conversation else { return XCTFail("Conversation was nil") }
        let expectedPath = "/conversations/\(msgConversation.remoteIdentifier.transportString())/otr/messages"
        XCTAssertEqual(notUploadedRequest.path, expectedPath)
        XCTAssertEqual(notUploadedRequest.method, ZMTransportRequestMethod.MethodPOST)
        XCTAssertEqual(msg.transferState, ZMFileTransferState.FailedUpload)
        
        guard let genericMessage = decryptedMessage(fromRequestData: notUploadedRequest.binaryData, forClient: otherClient) else { return XCTFail() }
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
    
    func decryptedMessage(fromRequestData data: NSData, forClient client: UserClient) -> ZMGenericMessage? {
        let otrMessage = ZMNewOtrMessage.builder().mergeFromData(data).build() as? ZMNewOtrMessage
        XCTAssertNotNil(otrMessage, "Unable to generate OTR message")
        let clientEntries = otrMessage?.recipients.flatMap { $0 as? ZMUserEntry }.flatMap { $0.clients }.flatten()
        XCTAssertEqual(clientEntries?.count, 1)
        
        let box = syncMOC.zm_cryptKeyStore.box
        guard let entry = clientEntries?.first as? ZMClientEntry else { XCTFail("Unable to get client entry"); return nil }
        
        do {
            let session = try box.sessionById(client.remoteIdentifier)
            let decryptedData = try session.decrypt(entry.text)
            return ZMGenericMessage.builder().mergeFromData(decryptedData).build() as? ZMGenericMessage
        } catch {
            XCTFail("Failed to decrypt generic message: \(error)")
            return nil
        }
    }

    func testThatItRemovesDeletedClients() {
        
        // given
        let msg = createMessage("foo")

        // client and user
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
        user.remoteIdentifier = NSUUID.createUUID()
        let client = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
        client.remoteIdentifier = "abc123123"
        client.user = user
        
        self.syncMOC.saveOrRollback()
        XCTAssertEqual(user.clients.count, 1)
        
        self.process(sut, message: msg)
        guard let request = sut.nextRequest() else { return XCTFail() }
        
        // payload
        let payload = [
            "deleted" : [
                user.remoteIdentifier!.transportString() : [
                    client.remoteIdentifier
                ]
            ]
        ]
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: payload, HTTPstatus: 200, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(user.clients.count, 0)
    }
    
    func testThatItAddMissingClients() {
        
        // given
        let msg = createMessage("foo")
        let clientID = "1234567abc"
        
        // user
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
        user.remoteIdentifier = NSUUID.createUUID()
        
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
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: payload, HTTPstatus: 412, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        if let client = user.clients.first {
            XCTAssertEqual(client.remoteIdentifier, clientID)
        } else {
            XCTFail()
        }
    }
    
    func testThatAMessageWithMissingClientsDependsOnThoseClients() {
        
        // given
        let msg = createMessage("foo")
        let clientID = "1234567abc"
        
        // user
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
        user.remoteIdentifier = NSUUID.createUUID()
        
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
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: payload, HTTPstatus: 412, transportSessionError: nil))
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        let nextRequest = sut.nextRequest()
        
        // then
        XCTAssertNil(nextRequest)
    }
}

// MARK: - Preprocessing
extension FileUploadRequestStrategyTests {

    func testThatItPreprocessMessages() {
        
        // given
        let msg = createMessage("foo")
        
        // when
        sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set(arrayLiteral: msg)) }
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
    
        // then after processing it should set 'needsToUploadPreview' to true
        XCTAssertFalse(msg.needsToUploadMedium);
        XCTAssertTrue(msg.needsToUploadPreview);
        XCTAssertNotNil(self.syncMOC.zm_fileAssetCache.assetData(msg.nonce, fileName: "foo", encrypted:true))
    }
}
