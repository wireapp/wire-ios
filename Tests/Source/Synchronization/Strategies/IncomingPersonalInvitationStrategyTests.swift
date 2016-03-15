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


import XCTest
import zmessaging

class IncomingPersonalInvitationStrategyTests: MessagingTest {
    
    private var sut : IncomingPersonalInvitationStrategy!
    
    private let payload = [
        "email" : "john.doe@example.com",
        "inviter" : NSUUID.createUUID().transportString(),
        "name": "John Doe",
        "created_at" : NSDate().transportString(),
        "id" : NSUUID.createUUID().transportString()
    ]
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        self.sut = IncomingPersonalInvitationStrategy(managedObjectContext: self.uiMOC);
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        super.tearDown()
    }
    
    func testThatNoRequestIsGeneratedWithoutPendingInvitationCode() {
        XCTAssertEqual(self.sut.nextRequest(), nil)
    }
    
    func testThatRequestIsGeneratedForPendingInvitationCode() {
        // Given
        IncomingPersonalInvitationStrategy.storePendingInvitation("123", context: self.uiMOC)
        
        // When
        let request = self.sut.nextRequest()
        
        // Then
        XCTAssertEqual(request?.path, "/invitations/info?code=123")
        
    }
    
    func testThatPendingInvitationCodeIsClearedOnSuccessfullResponse() {
        // Given
        IncomingPersonalInvitationStrategy.storePendingInvitation("123", context: self.uiMOC)
        let request = self.sut.nextRequest()
        
        // When
        let response = ZMTransportResponse(payload: payload, HTTPstatus: 200, transportSessionError: nil)
        request?.completeWithResponse(response)
        
        // Then
        XCTAssertEqual(self.sut.nextRequest(), nil)
    }
    
    func testNotificationIsSentBeforeRequestingInvitation() {
        // Given
        IncomingPersonalInvitationStrategy.storePendingInvitation("123", context: self.uiMOC)
        let expectation = self.expectationWithDescription("Notification sent")
        
        let token = ZMIncomingPersonalInvitationNotification.addObserverWithBlock { (notification: ZMIncomingPersonalInvitationNotification!) -> Void in
            if (notification.type == ZMIncomingPersonalInvitationNotificationType.WillFetchInvitation) {
                expectation.fulfill()
            }
        }
        
        // When
        self.sut.nextRequest()
        
        // Then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
        NSNotificationCenter.defaultCenter().removeObserver(token);
    }
    
    func testNotificationIsSentOnReceivingInvitation() {
        // Given
        IncomingPersonalInvitationStrategy.storePendingInvitation("123", context: self.uiMOC)
        let request = self.sut.nextRequest()
        let expectation = self.expectationWithDescription("Notification sent")
        
        let token = ZMIncomingPersonalInvitationNotification.addObserverWithBlock { (notification: ZMIncomingPersonalInvitationNotification!) -> Void in
            if (notification.type == ZMIncomingPersonalInvitationNotificationType.DidReceiveInvitationToRegisterAsUser) {
                expectation.fulfill()
            }
        }
        
        // When
        let response = ZMTransportResponse(payload: payload, HTTPstatus: 200, transportSessionError: nil)
        request?.completeWithResponse(response)
        
        // Then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
        NSNotificationCenter.defaultCenter().removeObserver(token);
    }
    
    func testNotificationIsSentOnFailureToFetchInvitation() {
        // Given
        IncomingPersonalInvitationStrategy.storePendingInvitation("123", context: self.uiMOC)
        let request = self.sut.nextRequest()
        let expectation = self.expectationWithDescription("Notification sent")
        
        let token = ZMIncomingPersonalInvitationNotification.addObserverWithBlock { (notification: ZMIncomingPersonalInvitationNotification!) -> Void in
            if (notification.type == ZMIncomingPersonalInvitationNotificationType.DidFailToFetchInvitation) {
                expectation.fulfill()
            }
        }
        
        // When
        let response = ZMTransportResponse(payload: nil, HTTPstatus: 400, transportSessionError: nil)
        request?.completeWithResponse(response)
        
        // Then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
        NSNotificationCenter.defaultCenter().removeObserver(token);
    }
}
