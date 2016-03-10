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

class MockAuthenticationStatus: ZMAuthenticationStatus {
    
    var mockPhase: ZMAuthenticationPhase
    
    init(phase: ZMAuthenticationPhase) {
        mockPhase = phase
        super.init()
    }
    
    override var currentPhase: ZMAuthenticationPhase {
        return mockPhase
    }
}

class MockBackgroundAPNSPingBackStatus: BackgroundAPNSPingBackStatus {
    
    var mockNextNotificationID: NSUUID?
    var didPerformPingBackVerification: ((NSUUID, Bool) -> Void)?
    
    override var hasNotificationIDs: Bool {
        return nil != mockNextNotificationID
    }
    
    override func nextNotificationID() -> NSUUID? {
        return mockNextNotificationID
    }
    
    override func didPerfomPingBackRequest(notificationID: NSUUID, success: Bool) {
        didPerformPingBackVerification?(notificationID, success)
    }
}


// MARK: - Tests

class PingBackRequestStrategyTests: MessagingTest {

    var sut: PingBackRequestStrategy!
    var authenticationStatus: MockAuthenticationStatus!
    var pingBackStatus: MockBackgroundAPNSPingBackStatus!
    var notificationDispatcher: LocalNotificationDispatchType!
    
    override func setUp() {
        super.setUp()
        notificationDispatcher = MockNotificationDispatcher()
        authenticationStatus = MockAuthenticationStatus(phase: .Authenticated)
        
        pingBackStatus = MockBackgroundAPNSPingBackStatus(
            syncManagedObjectContext: syncMOC,
            authenticationProvider: authenticationStatus,
            localNotificationDispatcher: notificationDispatcher
        )
        
        sut = PingBackRequestStrategy(
            managedObjectContext: syncMOC,
            backgroundAPNSPingBackStatus: pingBackStatus,
            authenticationStatus: authenticationStatus
        )
    }

    func testThatItGeneratesARequestWhenThePingBackStatusReturnsANotificationIDAndTheStateIsAuthenticated() {
        // given
        let notificationID = NSUUID.createUUID()
        pingBackStatus.mockNextNotificationID = notificationID
        XCTAssertTrue(pingBackStatus.hasNotificationIDs)
        
        // when
        let request = sut.nextRequest()
        
        // then
        XCTAssertEqual(request?.method, .MethodPOST)
        XCTAssertEqual(request?.path, "/push/fallback/\(notificationID.transportString())/cancel")
        XCTAssertNil(request?.payload)
        if let request = request {
            XCTAssertTrue(request.shouldUseOnlyForegroundSession)
        }
    }
    
    func testThatItDoesNotGenerateARequestWhenThePingBackStatusReturnsANotificationIDButTheStateIsUnauthenticated() {
        // given
        authenticationStatus.mockPhase = .Unauthenticated
        pingBackStatus.mockNextNotificationID = NSUUID.createUUID()
        XCTAssertTrue(pingBackStatus.hasNotificationIDs)
        
        // when
        let request = sut.nextRequest()
        
        // then
        XCTAssertNil(request)
    }
    
    func testThatItDoesNotGenerateARequestWhenThePingBackStatusReturnsNoNotificationIDButTheStateIsAuthenticated() {
        // given
        authenticationStatus.mockPhase = .Authenticated
        XCTAssertFalse(pingBackStatus.hasNotificationIDs)
        
        // when
        let request = sut.nextRequest()
        
        // then
        XCTAssertNil(request)
    }

    func testThatItCallsDidPerformPingBackRequestWithSuccessOnThePingBackStatusAfterSuccessfullyPerformingThePingBack() {
        // given
        let nextUUID = NSUUID.createUUID()
        var didPerformPingBackCalled = false
        var receivedUUID: NSUUID?
        var receivedSuccess = false
        
        pingBackStatus.mockNextNotificationID = nextUUID
        pingBackStatus.didPerformPingBackVerification = { uuid, success in
            didPerformPingBackCalled = true
            receivedSuccess = success
            receivedUUID = uuid
        }
        
        XCTAssertTrue(pingBackStatus.hasNotificationIDs)
        
        // when
        let response = ZMTransportResponse(payload: nil, HTTPstatus: 200, transportSessionError: nil)
        let request = sut.nextRequest()
        request?.completeWithResponse(response)
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertTrue(didPerformPingBackCalled)
        XCTAssertTrue(receivedSuccess)
        XCTAssertEqual(receivedUUID, nextUUID)
    }
    
    func testThatItCallsDidPerformPingBackRequestOnThePingBackStatusAfterFailingPerformingThePingBack() {
        // given
        let nextUUID = NSUUID.createUUID()
        var didPerformPingBackCalled = false
        var receivedUUID: NSUUID?
        var receivedSuccess = false
        
        pingBackStatus.mockNextNotificationID = nextUUID
        pingBackStatus.didPerformPingBackVerification = { uuid, success in
            didPerformPingBackCalled = true
            receivedSuccess = success
            receivedUUID = uuid
        }
        
        XCTAssertTrue(pingBackStatus.hasNotificationIDs)
        
        // when
        let response = ZMTransportResponse(payload: nil, HTTPstatus: 401, transportSessionError: nil)
        let request = sut.nextRequest()
        request?.completeWithResponse(response)
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertTrue(didPerformPingBackCalled)
        XCTAssertFalse(receivedSuccess)
        XCTAssertEqual(receivedUUID, nextUUID)
    }
}
