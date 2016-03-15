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
import Foundation
@testable import zmessaging

class TestInvitationNotificationObserver : NSObject, ZMInvitationStatusObserver {
    
    private let block : (note: ZMInvitationStatusChangedNotification)->()
    
    init(notificationBlock: (note: ZMInvitationStatusChangedNotification)->()) {
        self.block = notificationBlock
    }
    
    @objc func invitationStatusChanged(note: ZMInvitationStatusChangedNotification!) {
        self.block(note: note)
    }
}


class PersonalInvitationRequestStrategyTests: MessagingTest {
    
    enum InvitationType : String {
        case Email = "email"
        case Phone = "phone"
    }
    
    private var strategy: PersonalInvitationRequestStrategy!
    private var contact1: ZMAddressBookContact!
    
    override func setUp() {
        super.setUp()
        self.strategy = PersonalInvitationRequestStrategy(context: self.uiMOC)
        self.contact1 = ZMAddressBookContact()
        self.contact1.emailAddresses = ["hello@example.com"]
        self.contact1.phoneNumbers = ["0123456789"]
    }
    
    override func tearDown() {
        self.strategy = nil
        super.tearDown()
    }
    
    func testThatItGeneratesARequestWhenBootstrapping() {
        
        // given
        let selfUser = ZMUser.selfUserInContext(self.uiMOC)
        let _ = ZMPersonalInvitation(fromUser:selfUser, toContact:self.contact1, email:self.contact1.emailAddresses[0] as! String, conversation:nil, managedObjectContext:self.uiMOC)
        ZMChangeTrackerBootstrap.bootStrapChangeTrackers([self.strategy.insertSync], onContext: self.uiMOC)
        
        // when
        let request : ZMTransportRequest? = self.strategy.nextRequest()
        
        // then
        if let request = request {  
            XCTAssertEqual(request.method, ZMTransportRequestMethod.MethodPOST)
            XCTAssertEqual(request.path, "/invitations")
            XCTAssertTrue(request.needsAuthentication)
        } else {
            XCTFail("Empty request")
        }
    }
    
    private func requestForInsertingInvitationForType(invitationType: InvitationType) -> ZMTransportRequest? {
        let selfUser = ZMUser.selfUserInContext(self.uiMOC)
        let invitation = { () -> ZMPersonalInvitation in
            switch invitationType {
            case .Email: return ZMPersonalInvitation(fromUser:selfUser, toContact:self.contact1, email:self.contact1.emailAddresses[0] as! String, conversation:nil, managedObjectContext:self.uiMOC)
            case .Phone: return ZMPersonalInvitation(fromUser: selfUser, toContact: self.contact1, phoneNumber: self.contact1.phoneNumbers[0] as! String, conversation:nil , managedObjectContext: self.uiMOC)
            }
        }()
        
        for changeTracker in self.strategy.contextChangeTrackers {
            changeTracker.objectsDidChange([invitation])
        }
        
        return self.strategy.nextRequest()
    }
    
    func testThatItGeneratesARequestWhenTheObjectIsInserted() {
        
        // given
        let selfUser = ZMUser.selfUserInContext(self.uiMOC)
        
        // when
        guard let request = self.requestForInsertingInvitationForType(.Email) else {
            XCTFail()
            return
        }
        
        // then
        XCTAssertEqual(request.method, ZMTransportRequestMethod.MethodPOST)
        XCTAssertEqual(request.path, "/invitations")
        XCTAssertTrue(request.needsAuthentication)
        XCTAssertEqual(request.payload.asDictionary()["message"] as? String, " ")
        XCTAssertEqual(request.payload.asDictionary()["email"] as? String, self.contact1.emailAddresses[0] as? String)
        XCTAssertEqual(request.payload.asDictionary()["inviter_name"] as? String, selfUser.displayName)
        XCTAssertEqual(request.payload.asDictionary()["invitee_name"] as? String, self.contact1.name)
    }
    
    func testThatItFetchesConnectionIfInvitedUserIsAlreadyOnWire() {
        self.performPretendingUiMocIsSyncMoc { () -> Void in
            
            //Given
            let UUID = NSUUID.createUUID()
            let response = ZMTransportResponse(payload: nil, HTTPstatus: 201, transportSessionError: nil, headers: ["Location" : "/self/connections/\(UUID.transportString())"])
            
            guard let request = self.requestForInsertingInvitationForType(.Email) else {
                XCTFail()
                return
            }
            // When
            request.completeWithResponse(response)
            
            // Then
            XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
            
            let user = ZMUser(remoteID: UUID, createIfNeeded: false, inContext: self.uiMOC)
            XCTAssertNotNil(user)
            AssertOptionalNotNil(user) { (user : ZMUser) in
                XCTAssertTrue(user.needsToBeUpdatedFromBackend)
            }
            
            let connection = user?.connection
            XCTAssertNotNil(connection)
            AssertOptionalNotNil(connection) { (connection : ZMConnection) in
                XCTAssertTrue(connection.needsToBeUpdatedFromBackend)
            }
        }
    }
    
    func testThatItTriggerConnectionRequestSentNotificationIfInvitedUserIsAlreadyOnWire() {
        self.performPretendingUiMocIsSyncMoc { () -> Void in
            //Given
            let expectation = self.expectationWithDescription("Connection request notification")
            let observer = TestInvitationNotificationObserver { (note) -> () in
                guard note.newStatus == .ConnectionRequestSent else {
                    XCTFail()
                    return
                }
                expectation.fulfill()
            }
            let UUID = NSUUID.createUUID()
            let response = ZMTransportResponse(payload: nil, HTTPstatus: 201, transportSessionError: nil, headers: ["Location" : "/self/connections/\(UUID.transportString())"])
            
            guard let request = self.requestForInsertingInvitationForType(.Email) else {
                XCTFail()
                return
            }
            ZMInvitationStatusChangedNotification.addInvitationStatusObserver(observer)
            // When
            request.completeWithResponse(response)
            
            // Then
            XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
            ZMInvitationStatusChangedNotification.addInvitationStatusObserver(observer)
        }
    }
    
    private func testThatNotificationTriggerCorrectStatus(status: ZMInvitationStatus, forTransportResponse response: ZMTransportResponse) {
        // given
        let expectation = self.expectationWithDescription("Received status notification")
        let observer = TestInvitationNotificationObserver { note in
            guard note.newStatus == status else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }
        
        guard let request = self.requestForInsertingInvitationForType(.Email) else {
            XCTFail()
            return
        }
        ZMInvitationStatusChangedNotification.addInvitationStatusObserver(observer)
        
        // when
        request.completeWithResponse(response)
        
        // then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
        ZMInvitationStatusChangedNotification.removeInvitationStatusObserver(observer)
    }
    
    func testThatItNotifiesTheUIWhenFailingToUploadToBackend() {
        self.testThatNotificationTriggerCorrectStatus(.Failed, forTransportResponse: ZMTransportResponse(payload: nil, HTTPstatus: 400, transportSessionError: nil))
    }
    
    func testThatItNotifiesTheUIWhenSucceedToUploadtoBackend() {
        self.testThatNotificationTriggerCorrectStatus(.Sent, forTransportResponse: ZMTransportResponse(payload: ["id" : NSUUID().UUIDString, "created_at" : "2015-11-11T14:22:32.719Z"], HTTPstatus: 201, transportSessionError: nil))
    }
    
    func testThatItReceivesEmailWhenInvitingWithEmail() {
        
        // given
        let expectation = self.expectationWithDescription("Received email notification")
        let observer = TestInvitationNotificationObserver { note in
            
            guard note.newStatus == .Sent, let emailAddress = note.emailAddress else {
                XCTFail()
                return
            }
            let contactEmailAddress = self.contact1.emailAddresses[0] as? String
            XCTAssertEqual(emailAddress, contactEmailAddress)
            expectation.fulfill()
        }
        
        guard let request = self.requestForInsertingInvitationForType(.Email) else {
            XCTFail()
            return
        }
        ZMInvitationStatusChangedNotification.addInvitationStatusObserver(observer)
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: ["id": NSUUID().UUIDString, "created_at": "2015-11-11T14:22:32.719Z", "email" : self.contact1.emailAddresses[0]], HTTPstatus: 201, transportSessionError: nil))
        // then
        ZMInvitationStatusChangedNotification.removeInvitationStatusObserver(observer)
        
    }
    
    func testThatItReceivesPhoneWhenInvitingWithPhone() {
        
        // given
        let expectation = self.expectationWithDescription("Received phone notification")
        
        let observer = TestInvitationNotificationObserver { note in
            
            guard note.newStatus == .Sent, let phoneNumber = note.phoneNumber else {
                XCTFail()
                return
            }
            let contactPhoneNumber = self.contact1.phoneNumbers[0] as? String
            XCTAssertEqual(phoneNumber, contactPhoneNumber)
            expectation.fulfill()
        }
        
        guard let request = self.requestForInsertingInvitationForType(.Phone) else {
            XCTFail()
            return
        }
        ZMInvitationStatusChangedNotification.addInvitationStatusObserver(observer)
        
        // when
        request.completeWithResponse(ZMTransportResponse(payload: ["id": NSUUID().UUIDString, "created_at": "2015-11-11T14:22:32.719Z", "phone" : self.contact1.phoneNumbers[0]], HTTPstatus: 201, transportSessionError: nil))
        // then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
        ZMInvitationStatusChangedNotification.removeInvitationStatusObserver(observer)
    }
}