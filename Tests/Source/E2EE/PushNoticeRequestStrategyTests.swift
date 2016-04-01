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


import zmessaging
import ZMTesting
import ZMCMockTransport


// MARK: - Tests

class PushNoticeRequestStrategyTests: MessagingTest {
    
    var sut: PushNoticeRequestStrategy!
    var authenticationStatus: MockAuthenticationStatus!
    var pingBackStatus: MockBackgroundAPNSPingBackStatus!
    var notificationDispatcher: LocalNotificationDispatchType!
    var selfClient : UserClient!
    
    override func setUp() {
        super.setUp()
        selfClient = createSelfClient()
        
        notificationDispatcher = MockNotificationDispatcher()
        authenticationStatus = MockAuthenticationStatus(phase: .Authenticated)
        
        pingBackStatus = MockBackgroundAPNSPingBackStatus(
            syncManagedObjectContext: syncMOC,
            authenticationProvider: authenticationStatus,
            localNotificationDispatcher: notificationDispatcher
        )
        
        sut = PushNoticeRequestStrategy(
            managedObjectContext: syncMOC,
            backgroundAPNSPingBackStatus: pingBackStatus,
            authenticationStatus: authenticationStatus
        )
    }
    
    func testThatItGeneratesARequestWhenThePingBackStatusReturnsANotificationIDAndTheStateIsAuthenticated() {
        // given
        let notificationID = NSUUID.createUUID()
        pingBackStatus.mockNextNotificationID = notificationID
        pingBackStatus.mockStatus = .FetchingNotice
        XCTAssertTrue(pingBackStatus.hasNoticeNotificationIDs)
        
        // when
        let request = sut.nextRequest()
        
        // then
        XCTAssertEqual(request?.method, .MethodGET)
        XCTAssertEqual(request?.path, "/notifications/\(notificationID.transportString())?client=\(selfClient.remoteIdentifier)")
        XCTAssertNil(request?.payload)
    }
    
    func testThatItDoesNotGenerateARequestWhenThePingBackStatusReturnsANotificationIDButTheStatusIsNotFetching() {
        // given
        let notificationID = NSUUID.createUUID()
        pingBackStatus.mockNextNotificationID = notificationID
        pingBackStatus.mockStatus = .Pinging
        XCTAssertTrue(pingBackStatus.hasNoticeNotificationIDs)
        
        // when
        let request = sut.nextRequest()
        
        // then
        XCTAssertNil(request)
    }
    
    func testThatItDoesNotGenerateARequestWhenThePingBackStatusReturnsANotificationIDButTheStateIsUnauthenticated() {
        // given
        authenticationStatus.mockPhase = .Unauthenticated
        pingBackStatus.mockNextNotificationID = NSUUID.createUUID()
        XCTAssertTrue(pingBackStatus.hasNoticeNotificationIDs)
        
        // when
        let request = sut.nextRequest()
        
        // then
        XCTAssertNil(request)
    }
    
    func testThatItDoesNotGenerateARequestWhenThePingBackStatusReturnsNoNotificationIDButTheStateIsAuthenticated() {
        // given
        authenticationStatus.mockPhase = .Authenticated
        XCTAssertFalse(pingBackStatus.hasNoticeNotificationIDs)
        
        // when
        let request = sut.nextRequest()
        
        // then
        XCTAssertNil(request)
    }
    
    func testThatItCallsDidFetchNoticeNotificationWithSuccessOnThePingBackStatusAfterSuccessfullyPerformingTheFetch() {
        // given
        let nextUUID = NSUUID.createUUID()
        var didPerformPingBackCalled = false
        var receivedUUID: NSUUID?
        var receivedSuccess = false
        var receivedEvents = []
        
        pingBackStatus.mockNextNotificationID = nextUUID
        pingBackStatus.mockStatus = .FetchingNotice
        pingBackStatus.didFetchNoticeNotification = { uuid, success, events in
            didPerformPingBackCalled = true
            receivedSuccess = success
            receivedUUID = uuid
            receivedEvents = events
        }
        
        XCTAssertTrue(pingBackStatus.hasNoticeNotificationIDs)
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.remoteIdentifier = NSUUID()
        let eventPayload = self.payloadForMessageInConversation(conversation, type: EventConversationAdd, data: [])
        let event = ZMUpdateEvent(fromEventStreamPayload:eventPayload, uuid: nextUUID)
        
        // when
        let response = ZMTransportResponse(payload: ["payload": [eventPayload], "id": nextUUID.transportString()], HTTPstatus: 200, transportSessionError: nil)
        let request = sut.nextRequest()
        request?.completeWithResponse(response)
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertTrue(didPerformPingBackCalled)
        XCTAssertTrue(receivedSuccess)
        XCTAssertEqual(receivedUUID, nextUUID)
        XCTAssertEqual(receivedEvents, [event])
    }
    
    func testThatItCallsDidFetchNoticeNotificationOnThePingBackStatusAfterFailingPerformingTheFetch() {
        // given
        let nextUUID = NSUUID.createUUID()
        var didPerformPingBackCalled = false
        var receivedUUID: NSUUID?
        var receivedSuccess = false
        var receivedEvents = []

        pingBackStatus.mockNextNotificationID = nextUUID
        pingBackStatus.mockStatus = .FetchingNotice
        pingBackStatus.didFetchNoticeNotification = { uuid, success, events in
            didPerformPingBackCalled = true
            receivedSuccess = success
            receivedUUID = uuid
            receivedEvents = events
        }
        
        XCTAssertTrue(pingBackStatus.hasNoticeNotificationIDs)
        
        // when
        let response = ZMTransportResponse(payload: nil, HTTPstatus: 401, transportSessionError: nil)
        let request = sut.nextRequest()
        request?.completeWithResponse(response)
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertTrue(didPerformPingBackCalled)
        XCTAssertFalse(receivedSuccess)
        XCTAssertEqual(receivedUUID, nextUUID)
        XCTAssertEqual(receivedEvents, [])
    }
}