//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import XCTest
import WireRequestStrategy
import WireDataModel
import WireTransport

class LinkPreviewUploadRequestStrategyTests: MessagingTestBase {

    private var sut: LinkPreviewUploadRequestStrategy!
    private var applicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()
        applicationStatus = MockApplicationStatus()
        applicationStatus.mockSynchronizationState = .eventProcessing
        sut = LinkPreviewUploadRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: applicationStatus)
    }
    
    override func tearDown() {
        applicationStatus = nil
        sut = nil
        super.tearDown()
    }

    func testThatItDoesNotCreateARequestInState_Done() {
        verifyThatItDoesNotCreateARequest(for: .done)
    }

    func testThatItDoesNotCreateARequestInState_WaitingToBeProcessed() {
        verifyThatItDoesNotCreateARequest(for: .waitingToBeProcessed)
    }

    func testThatItDoesNotCreateARequestInState_Downloaded() {
        verifyThatItDoesNotCreateARequest(for: .downloaded)
    }

    func testThatItDoesNotCreateARequestInState_Processed() {
        verifyThatItDoesNotCreateARequest(for: .processed)
    }

    func testThatItDoesCreateARequestInState_Uploaded() {
        // Given
        let message = insertMessage(with: .uploaded)

        // When
        process(message)

        // Then
        verifyItCreatesARequest(in: groupConversation)
    }

    func testThatItDoesCreateARequestInState_Uploaded_WhenTheFirstRequestFailed() {
        // Given
        let message = insertMessage(with: .uploaded)

        // When
        process(message)
        guard let request = verifyItCreatesARequest(in: groupConversation) else { return }

        // When
        let response = ZMTransportResponse(transportSessionError: NSError.tryAgainLaterError())
        request.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(message.linkPreviewState, .uploaded)

        // Then
        verifyItCreatesARequest(in: groupConversation)
    }
    
    func testThatItReturnsSelfClientAsDependentObjectForMessageIfItHasMissingClients() {
        // Given
        let message = insertMessage(with: .uploaded)
        selfClient.missesClient(otherClient)
        
        // When
        process(message)
        
        // Then
        let dependency = sut.dependentObjectNeedingUpdate(beforeProcessingObject: message)
        XCTAssertEqual(dependency as? UserClient, selfClient)
    }

    func testThatItDoesNotCreateARequestAfterGettingsAResponseForIt() {
        // Given
        let message = insertMessage(with: .uploaded)
        process(message)

        // Then
        guard let request = verifyItCreatesARequest(in: groupConversation) else { return }

        // When
        let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil)
        request.complete(with: response)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(message.linkPreviewState, .done)
        XCTAssertNil(sut.nextRequest())
    }

    // MARK: - Helper

    func insertMessage(with state: ZMLinkPreviewState, file: StaticString = #file, line: UInt = #line) -> ZMClientMessage {
        let message = groupConversation.appendMessage(withText: "Test message") as! ZMClientMessage
        message.linkPreviewState = state
        XCTAssert(syncMOC.saveOrRollback(), file: file, line: line)

        return message
    }

    func verifyThatItDoesNotCreateARequest(for state: ZMLinkPreviewState, file: StaticString = #file, line: UInt = #line) {
        // Given
        let message = insertMessage(with: state)

        // When
        process(message)

        // Then
        XCTAssertNil(sut.nextRequest())
    }

    @discardableResult
    func verifyItCreatesARequest(in conversation: ZMConversation, file: StaticString = #file, line: UInt = #line) -> ZMTransportRequest? {
        let request = sut.nextRequest()
        XCTAssertNotNil(request, "No request generated", file: file, line: line)
        XCTAssertEqual(request?.method, .methodPOST, file: file, line: line)
        XCTAssertEqual(request?.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/otr/messages", file: file, line: line)
        return request
    }

    func process(_ message: ZMClientMessage, file: StaticString = #file, line: UInt = #line) {
        sut.contextChangeTrackers.forEach {
            $0.objectsDidChange([message])
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
    }
}
