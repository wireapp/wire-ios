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

class EventsWithIdentifierTests: ZMTBaseTest {
    
    var sut: EventsWithIdentifier!
    var identifier: NSUUID!
    var events: [ZMUpdateEvent]!
    
    func messageAddPayload() -> [String : AnyObject] {
        return [
            "conversation": NSUUID.createUUID().transportString(),
            "time": NSDate(),
            "data": [
                "content": "saf",
                "nonce": NSUUID.createUUID().transportString(),
            ],
            "from": NSUUID.createUUID().transportString(),
            "type": "conversation.message-add"
        ];
    }
    
    override func setUp() {
        super.setUp()
        identifier = NSUUID.createUUID()
        let pushChannelData = [
            "id": identifier.transportString(),
            "payload": [messageAddPayload(), messageAddPayload()]
        ]
        
        events = ZMUpdateEvent.eventsArrayFromPushChannelData(pushChannelData)
        sut = EventsWithIdentifier(events: events, identifier: identifier, isNotice:true)
    }
    
    func testThatItCreatesTheEventsWithIdentifierCorrectly() {
        // then
        XCTAssertEqual(identifier, sut.identifier)
        XCTAssertEqual(events, sut.events!)
        XCTAssertTrue(sut.isNotice)
    }
    
    func testThatItFiltersThePreexistingEvent() {
        // given
        guard let preexistingNonce = events.first?.messageNonce() else { return XCTFail() }
        
        // when
        let filteredEventsWithID = sut.filteredWithoutPreexistingNonces([preexistingNonce])
        
        // then
        guard let event = filteredEventsWithID.events?.first else { return XCTFail() }
        XCTAssertEqual(filteredEventsWithID.events?.count, 1)
        XCTAssertNotEqual(event.messageNonce(), preexistingNonce)
        XCTAssertEqual(filteredEventsWithID.identifier, sut.identifier)
        XCTAssertEqual(filteredEventsWithID.isNotice, sut.isNotice)
        XCTAssertEqual(event, events.last)
    }
    
}

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
            XCTAssertEqual(result.0, ZMPushPayloadResult.Success)
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
    
    func testThatItStartsABackgroundActivityWhenTheStatusIsAuthenticated() {
        // when
        sut.didReceiveVoIPNotification(createEventsWithID())
        XCTAssertTrue(sut.hasNotificationIDs)
        
        // then
        XCTAssertNotNil(sut.backgroundActivity)
    }
    
    func testThatItDoesNotStartABackgroundActivityWhenTheStatusIsNotAuthenticated() {
        // given
        authenticationProvider.mockAuthenticationPhase = .Unauthenticated
        
        // when
        sut.didReceiveVoIPNotification(createEventsWithID())
        XCTAssertTrue(sut.hasNotificationIDs)
        
        // then
        XCTAssertNil(sut.backgroundActivity)
    }
    
    func testThatItEndsTheBackgroundActivityWhenRequestCompletesSuccessfully() {
        checkThatItEndsTheBackgroundActivityAfterThePingBackCompleted(true)
    }
    
    func testThatItEndsTheBackgroundActivityWhenRequestCompletesUnsuccessfully() {
        checkThatItEndsTheBackgroundActivityAfterThePingBackCompleted(false)
    }
    
    func checkThatItEndsTheBackgroundActivityAfterThePingBackCompleted(successfully: Bool) {
        // given
        let eventsWithID = createEventsWithID()
        sut.didReceiveVoIPNotification(eventsWithID)
        XCTAssertTrue(sut.hasNotificationIDs)
        XCTAssertNotNil(sut.backgroundActivity)
        
        // when
        let nextID = sut.nextNotificationID()!
        XCTAssertEqual(nextID, eventsWithID.identifier)
        sut.didPerfomPingBackRequest(nextID, success: successfully)
        
        // then
        XCTAssertNil(sut.backgroundActivity)
    }
    
    func checkThatItEndsTheBackgroundActivityAfterTheFetchAndPingBackCompleted(fetchSuccess: Bool, pingBackSuccess: Bool) {
        // given
        let eventsWithID = createEventsWithID(isNotice: true)
        sut.didReceiveVoIPNotification(eventsWithID)
        XCTAssertTrue(sut.hasNotificationIDs)
        XCTAssertTrue(sut.hasNoticeNotificationIDs)
        XCTAssertEqual(sut.status, PingBackStatus.FetchingNotice)
        
        XCTAssertNotNil(sut.backgroundActivity)
        
        // when
        let nextNoticeID = sut.nextNoticeNotificationID()!
        
        sut.didFetchNoticeNotification(nextNoticeID, success: fetchSuccess, events:[])
        if fetchSuccess {
            XCTAssertEqual(sut.status, PingBackStatus.Pinging)
            
            // and when
            let nextID = sut.nextNotificationID()!
            XCTAssertEqual(nextNoticeID, nextID)
            
            sut.didPerfomPingBackRequest(nextID, success: pingBackSuccess)
            XCTAssertEqual(sut.status, PingBackStatus.Done)
        } else {
            XCTAssertEqual(sut.status, PingBackStatus.Done)
        }
        
        // then
        XCTAssertNil(sut.backgroundActivity)
    }
    
    func testThatItEndsTheBackgroundActivityAfterTheFetchAndPingBackCompletedSuccessfully() {
        checkThatItEndsTheBackgroundActivityAfterTheFetchAndPingBackCompleted(true, pingBackSuccess: true)
    }
    
    func testThatItEndsTheBackgroundActivityAfterTheFetchCompletedUnsuccessfully() {
        checkThatItEndsTheBackgroundActivityAfterTheFetchAndPingBackCompleted(false, pingBackSuccess: true)
    }
    
    func testThatItEndsTheBackgroundActivityAfterTheFetchCompletedSuccessfullyPingBackSuccessfully() {
        checkThatItEndsTheBackgroundActivityAfterTheFetchAndPingBackCompleted(true, pingBackSuccess: false)
    }
    
    func testThatItEndsTheBackgroundActivityAfterTheFetchCompletedUnsuccessfullyPingBackUnsuccessfully() {
        checkThatItEndsTheBackgroundActivityAfterTheFetchAndPingBackCompleted(false, pingBackSuccess: false)
    }

    func simulateFetchNoticeAndPingback() {
        let nextNoticeID = sut.nextNoticeNotificationID()!
        sut.didFetchNoticeNotification(nextNoticeID, success: true, events:[])
        XCTAssertEqual(sut.status, PingBackStatus.Pinging)
        
        let nextID = simulatePingBack()
        XCTAssertEqual(nextNoticeID, nextID)
    }
    
    func simulatePingBack() -> NSUUID {
        let nextID = sut.nextNotificationID()!
        sut.didPerfomPingBackRequest(nextID, success: true)
        return nextID
    }
    
    func checkThatItUpdatesStatusToFetchingWhenFirstAndNextNotificationAreNotice(nextIsNotice: Bool) {
       
        // given
        let eventsWithID1 = createEventsWithID(isNotice: true)
        let eventsWithID2 = createEventsWithID(isNotice: nextIsNotice)

        sut.didReceiveVoIPNotification(eventsWithID1)
        sut.didReceiveVoIPNotification(eventsWithID2)

        XCTAssertTrue(sut.hasNotificationIDs)
        XCTAssertTrue(sut.hasNoticeNotificationIDs)
        XCTAssertEqual(sut.status, PingBackStatus.FetchingNotice)
        
        XCTAssertNotNil(sut.backgroundActivity)
        
        // when
        simulateFetchNoticeAndPingback()
        
        // then
        if nextIsNotice {
            XCTAssertEqual(sut.status, PingBackStatus.FetchingNotice)
        } else {
            XCTAssertEqual(sut.status, PingBackStatus.Pinging)
        }
        XCTAssertNotNil(sut.backgroundActivity)

        // and when
        if nextIsNotice {
            simulateFetchNoticeAndPingback()
        } else {
            simulatePingBack()
        }
        
        // then
        XCTAssertNil(sut.backgroundActivity)
        XCTAssertEqual(sut.status, PingBackStatus.Done)
    }
    
    func testThatItUpdatesStatusToFetchingWhenFirstAndNextNotificationAreNoticeNextIsNotice() {
        checkThatItUpdatesStatusToFetchingWhenFirstAndNextNotificationAreNotice(true)
    }
    
    func testThatItUpdatesStatusToFetchingWhenFirstAndNextNotificationAreNoticeNextIsNonNotice() {
        checkThatItUpdatesStatusToFetchingWhenFirstAndNextNotificationAreNotice(false)
    }
    
    func checkThatItUpdatesStatusToFetchingWhenFirstIsNonNoticeAndNextNotification(nextIsNotice: Bool) {
        
        // given
        let eventsWithID1 = createEventsWithID(isNotice: false)
        let eventsWithID2 = createEventsWithID(isNotice: nextIsNotice)
        
        sut.didReceiveVoIPNotification(eventsWithID1)
        sut.didReceiveVoIPNotification(eventsWithID2)
        
        XCTAssertTrue(sut.hasNotificationIDs)
        if nextIsNotice {
            XCTAssertTrue(sut.hasNoticeNotificationIDs)
        } else {
            XCTAssertFalse(sut.hasNoticeNotificationIDs)
        }
        XCTAssertEqual(sut.status, PingBackStatus.Pinging)
        
        XCTAssertNotNil(sut.backgroundActivity)
        
        // when
        simulatePingBack()
        
        // then
        if nextIsNotice {
            XCTAssertEqual(sut.status, PingBackStatus.FetchingNotice)
        } else {
            XCTAssertEqual(sut.status, PingBackStatus.Pinging)
        }
        XCTAssertNotNil(sut.backgroundActivity)
        
        // and when
        if nextIsNotice {
            simulateFetchNoticeAndPingback()
        } else {
            simulatePingBack()
        }
        
        // then
        XCTAssertNil(sut.backgroundActivity)
        XCTAssertEqual(sut.status, PingBackStatus.Done)
    }
    
    func testThatItUpdatesStatusToFetchingWhenFirstIsNonNoticeAndNextNotificationIsNotice() {
        checkThatItUpdatesStatusToFetchingWhenFirstIsNonNoticeAndNextNotification(true)
    }
    
    func testThatItUpdatesStatusToFetchingWhenFirstIsNonNoticeAndNextNotificationIsNotNotice() {
        checkThatItUpdatesStatusToFetchingWhenFirstIsNonNoticeAndNextNotification(false)
    }

    func testThatItTakesTheOrderFromTheNotificationIDsArray() {
        // given
        let eventsWithID1 = createEventsWithID(isNotice: true)
        let eventsWithID2 = createEventsWithID(isNotice: false)
        let eventsWithID3 = createEventsWithID(isNotice: true)

        sut.didReceiveVoIPNotification(eventsWithID1)
        sut.didReceiveVoIPNotification(eventsWithID2)
        sut.didReceiveVoIPNotification(eventsWithID3)

        XCTAssertEqual(sut.status, PingBackStatus.FetchingNotice)

        // when
        simulateFetchNoticeAndPingback()
        XCTAssertEqual(sut.status, PingBackStatus.Pinging)

        simulatePingBack()
        XCTAssertEqual(sut.status, PingBackStatus.FetchingNotice)

        simulateFetchNoticeAndPingback()
        XCTAssertEqual(sut.status, PingBackStatus.Done)
    }

}



// MARK: - Helper

extension BackgroundAPNSPingBackStatus {
    func didReceiveVoIPNotification(eventsWithID: EventsWithIdentifier) {
        didReceiveVoIPNotification(eventsWithID, handler: { _ in })
    }
}

extension BackgroundAPNSPingBackStatusTests {
    func createEventsWithID(identifier: NSUUID = NSUUID.createUUID(), events: [ZMUpdateEvent] = [ZMUpdateEvent()], isNotice: Bool = false) -> EventsWithIdentifier {
        return EventsWithIdentifier(events: events, identifier: identifier, isNotice: isNotice)
    }
}
