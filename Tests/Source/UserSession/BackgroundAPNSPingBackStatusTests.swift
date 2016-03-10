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


import zmessaging
import ZMTesting
import ZMCMockTransport


// MARK: - Mocks

class OperationLoopNewRequestObserver {
    
    var notifications = [NSNotification]()
    private var notificationCenter = NSNotificationCenter.defaultCenter()
    private var newRequestNotification = "ZMOperationLoopNewRequestAvailable"
    
    init() {
        notificationCenter.addObserverForName(newRequestNotification, object: nil, queue: .mainQueue()) { [weak self] note in
         self?.notifications.append(note)
        }
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
}


@objc class MockAuthenticationProvider: NSObject, AuthenticationStatusProvider {
    var mockAuthenticationPhase: ZMAuthenticationPhase = .Authenticated
    
    var currentPhase: ZMAuthenticationPhase {
        return mockAuthenticationPhase
    }
}


@objc class MockNotificationDispatcher: NSObject, LocalNotificationDispatchType {
    var didReceiveUpdateEventsBlock: ([ZMUpdateEvent]? -> Void)?
    var callCount = 0
    
    func didReceiveUpdateEvents(events: [ZMUpdateEvent]?) {
        callCount++
        didReceiveUpdateEventsBlock?(events)
    }
}


// MARK: - Tests

class BackgroundAPNSPingBackStatusTests: MessagingTest {

    var sut: BackgroundAPNSPingBackStatus!
    var observer: OperationLoopNewRequestObserver!
    var authenticationProvider: MockAuthenticationProvider!
    var notificationDispatcher: MockNotificationDispatcher!
    
    override func setUp() {
        super.setUp()
        authenticationProvider = MockAuthenticationProvider()
        notificationDispatcher = MockNotificationDispatcher()
        sut = BackgroundAPNSPingBackStatus(
            syncManagedObjectContext: syncMOC,
            authenticationProvider: authenticationProvider,
            localNotificationDispatcher: notificationDispatcher
        )
        observer = OperationLoopNewRequestObserver()
    }

    func testThatItSetsTheNotificationID() {
        // given
        XCTAssertFalse(sut.hasNotificationIDs)
        let notificationID = NSUUID.createUUID()
        
        // when
        sut.didReceiveVoIPNotification(createEventsWithID(notificationID))
        
        // then
        XCTAssertTrue(sut.hasNotificationIDs)
        XCTAssertEqual(sut.status, PingBackStatus.Pinging)
        
        // when
        let notificationIDToPing = sut.nextNotificationID()
        
        // then
        XCTAssertEqual(notificationID, notificationIDToPing)
        XCTAssertNil(sut.nextNotificationID())
        XCTAssertFalse(sut.hasNotificationIDs)
    }
    
    func testThatItPostsNewRequestsAvailableNotificationWhenAddingANotificationID() {
        // when
        sut.didReceiveVoIPNotification(createEventsWithID())
        
        // then
        XCTAssertEqual(observer.notifications.count, 1)
    }
    
    func testThatItNotifiesTheLocalNotificationDispatcherIfThePingBackSucceded() {
        
        // given
        let eventsWithID = createEventsWithID()
        sut.didReceiveVoIPNotification(eventsWithID)
        notificationDispatcher.didReceiveUpdateEventsBlock = { events in
            guard let unwrappedEvents = events else { return XCTFail() }
            XCTAssertEqual(unwrappedEvents, eventsWithID.events!)
        }
        
        // when
        _ = sut.nextNotificationID()
        sut.didPerfomPingBackRequest(eventsWithID.identifier, success: true)
        
        // then
        XCTAssertEqual(notificationDispatcher.callCount, 1)
    }
    
    func testThatItDoesNotNotifyTheLocalNotificationDispatcherIfThePingBackFailed() {
        
        // given
        let eventsWithID = createEventsWithID()
        sut.didReceiveVoIPNotification(eventsWithID)
        
        // when
        _ = sut.nextNotificationID()
        sut.didPerfomPingBackRequest(eventsWithID.identifier, success: false)
        
        // then
        XCTAssertEqual(notificationDispatcher.callCount, 0)
    }
    
    func testThatItCallsTheHandlerAfterPingBackRequestCompletedSuccessfully() {
        checkThatItCallsTheHandlerAfterPingBackRequestCompleted(true)
    }
    
    func testThatItCallsTheHandlerAfterPingBackRequestCompletedUnsuccessfully() {
        checkThatItCallsTheHandlerAfterPingBackRequestCompleted(false)
    }
    
    func checkThatItCallsTheHandlerAfterPingBackRequestCompleted(successfully: Bool) {
        // given
        let eventsWithID = createEventsWithID()
        let expectation = expectationWithDescription("It calls the completion handler")
        
        // expect
        sut.didReceiveVoIPNotification(eventsWithID)  { result in
            XCTAssertEqual(result, ZMPushPayloadResult.Success)
            expectation.fulfill()
        }
        
        // when
        sut.didPerfomPingBackRequest(eventsWithID.identifier, success: successfully)
        
        // then
        XCTAssertTrue(waitForCustomExpectationsWithTimeout(0.5))
    }
    
    func testThatItDoesSetTheStatusToDoneIfThereAreNoMoreNotifactionIDs() {
        
        // given
        let eventsWithID = createEventsWithID()
        XCTAssertEqual(sut.status, PingBackStatus.Done)
        sut.didReceiveVoIPNotification(eventsWithID)
        XCTAssertEqual(sut.status, PingBackStatus.Pinging)
        
        // when
        _ = sut.nextNotificationID()
        sut.didPerfomPingBackRequest(eventsWithID.identifier, success: true)
        
        // then
        XCTAssertFalse(sut.hasNotificationIDs)
        XCTAssertEqual(sut.status, PingBackStatus.Done)
    }
    
    func testThatItRemovesEventsFromIdentifierEventsMappingAfterSuccesfullyPerformingPingBack() {
        // given
        let eventsWithIDs = createEventsWithID()
        let expectedIdentifier = eventsWithIDs.identifier

        // when
        sut.didReceiveVoIPNotification(eventsWithIDs)
        guard let currentEvents = sut.eventsWithHandlerByNotificationID[expectedIdentifier]?.events else { return XCTFail() }
        
        // then
        XCTAssertTrue(sut.hasNotificationIDs)
        XCTAssertEqual(currentEvents, eventsWithIDs.events!)
        
        // when
        sut.didPerfomPingBackRequest(expectedIdentifier, success: true)
        
        // then
        XCTAssertNil(sut.eventsWithHandlerByNotificationID[expectedIdentifier])
    }
    
    func testThatItRemovesEventsWithHandlerFromIdentifierEventsMappingAfterFailingToPerformPingBack() {
        // given
        let eventsWithIDs = createEventsWithID()
        let expectedIdentifier = eventsWithIDs.identifier
        
        // when
        sut.didReceiveVoIPNotification(eventsWithIDs)
        guard let currentEventsWithHandler = sut.eventsWithHandlerByNotificationID[expectedIdentifier] else { return XCTFail() }
        
        // then
        XCTAssertTrue(sut.hasNotificationIDs)
        XCTAssertEqual(currentEventsWithHandler.events!, eventsWithIDs.events!)
        
        // when
        sut.didPerfomPingBackRequest(expectedIdentifier, success: false)
        
        // then
        XCTAssertNil(sut.eventsWithHandlerByNotificationID[expectedIdentifier])
    }
    
    func testThatItDoesNotRemoveTheIdentifierFromTheEventsIdentifierMappingWhenPingBackForOtherIDsFinishes() {
        // given
        let firstEventsWithIDs = createEventsWithID()
        let secondEventsWithIDs = createEventsWithID()
        let thirdEventsWithIDs = createEventsWithID()
        let expectedIdentifier = firstEventsWithIDs.identifier
        
        // when
        [firstEventsWithIDs, secondEventsWithIDs, thirdEventsWithIDs].forEach(sut.didReceiveVoIPNotification)
        guard let currentEvents = sut.eventsWithHandlerByNotificationID[expectedIdentifier]?.events else { return XCTFail() }
        
        // then
        XCTAssertEqual(sut.eventsWithHandlerByNotificationID.keys.count, 3)
        XCTAssertTrue(sut.hasNotificationIDs)
        XCTAssertEqual(currentEvents, firstEventsWithIDs.events!)
        
        // when
        sut.didPerfomPingBackRequest(secondEventsWithIDs.identifier, success: true)
        sut.didPerfomPingBackRequest(thirdEventsWithIDs.identifier, success: false)
        
        // then
        guard let finalEvents = sut.eventsWithHandlerByNotificationID[expectedIdentifier]?.events else { return XCTFail() }
        XCTAssertEqual(finalEvents, firstEventsWithIDs.events!)
    }

}

// MARK: - Helper

extension BackgroundAPNSPingBackStatus {
    func didReceiveVoIPNotification(eventsWithID: EventsWithIdentifier) {
        didReceiveVoIPNotification(eventsWithID, handler: { _ in })
    }
}

extension BackgroundAPNSPingBackStatusTests {
    func createEventsWithID(identifier: NSUUID = NSUUID.createUUID(), events: [ZMUpdateEvent] = [ZMUpdateEvent()]) -> EventsWithIdentifier {
        return EventsWithIdentifier(events: events, identifier: identifier)
    }
}
