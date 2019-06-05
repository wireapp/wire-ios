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
@testable import WireMockTransport

class MockTransportSessionBroadcastTests: MockTransportSessionTests {
    
    func assertExpectedPayload(_ payload : [String : Any], in response:  ZMTransportResponse, file: StaticString = #file, line: UInt = #line) {
        let missing = response.payload!.asDictionary()!["missing"] as! [String : Any]
        let redundant = response.payload!.asDictionary()!["redundant"] as! [String : Any]
        
        XCTAssertTrue(NSDictionary(dictionary: missing).isEqual(to: payload["missing"]! as! [String : Any]), "missing clients: \n\(missing)\n doesn't match expected payload:\n \(payload)", file: file, line: line)
        XCTAssertTrue(NSDictionary(dictionary: redundant).isEqual(to: payload["redundant"]! as! [String : Any]), "redundant clients: \n\(redundant)\n doesn't match expected payload:\n \(payload)", file: file, line: line)
    }
    
    func testThatItReturnsMissingConnectedUsersWhenReceivingOTRMessage() {
        // given
        var selfUser : MockUser!
        var selfClient : MockUserClient!
        var secondSelfClient : MockUserClient!
        
        var otherUser : MockUser!
        var otherUserClient : MockUserClient!
        var secondOtherUserClient : MockUserClient!
        var otherUserRedundantClient : MockUserClient!
        
        sut.performRemoteChanges { session in
            selfUser = session.insertSelfUser(withName: "foo")
            selfClient = session.registerClient(for: selfUser, label: "self user", type: "permanent", deviceClass: "phone")
            secondSelfClient = session.registerClient(for: selfUser, label: "self2", type: "permanent", deviceClass: "phone")
            
            otherUser = session.insertUser(withName: "bar")
            otherUserClient = otherUser.clients.anyObject() as? MockUserClient
            secondOtherUserClient = session.registerClient(for: otherUser, label: "other2", type: "permanent", deviceClass: "phone")
            otherUserRedundantClient = session.registerClient(for: otherUser, label: "other redundant", type: "permanent", deviceClass: "phone")
            
            let connection = session.insertConnection(withSelfUser: selfUser, to: otherUser)
            connection.status = "accepted"
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let messageData = "secret message".data(using: .utf8)!
        let base64Content = messageData.base64EncodedString()
        
        let payload : [String : Any] = [
            "sender": selfClient.identifier!,
            "recipients": [
                otherUser.identifier :
                    [ otherUserClient.identifier!: base64Content,
                      otherUserRedundantClient.identifier!: base64Content] ]
        ]
        
        let protoPayload = selfClient.otrMessageBuilderWithRecipients(for: [otherUserClient, otherUserRedundantClient], plainText: messageData).build().data()

        sut.performRemoteChanges { session in
            otherUserRedundantClient.user = nil
        }
        
        // when
        let responseJSON = self.response(forPayload: payload as ZMTransportData, path: "/broadcast/otr/messages", method: .methodPOST)
        let responsePROTO = self.response(forProtobufData: protoPayload, path: "/broadcast/otr/messages", method: .methodPOST)
        
        // then
        for response in [responseJSON, responsePROTO] {
            XCTAssertNotNil(response)
            
            if let response = response {
                XCTAssertEqual(response.httpStatus, 412)
                
                let expectedPayload = [
                    "missing"  : [ selfUser.identifier  : [secondSelfClient.identifier!],
                                   otherUser.identifier : [secondOtherUserClient.identifier!] ],
                    "redundant" : [ otherUser.identifier : [otherUserRedundantClient.identifier!]]
                ]
                
                assertExpectedPayload(expectedPayload, in: response)
            }
        }
    }
    
    func testThatItReturnsMissingTeamMembersWhenReceivingOTRMessage() {
        // given
        var selfUser : MockUser!
        var selfClient : MockUserClient!

        var otherUser : MockUser!
        var otherUserClient : MockUserClient!

        sut.performRemoteChanges { session in
            selfUser = session.insertSelfUser(withName: "Self User")
            selfClient = session.registerClient(for: selfUser, label: "self user", type: "permanent", deviceClass: "phone")

            otherUser = session.insertUser(withName: "Team member1")
            otherUserClient = otherUser.clients.anyObject() as? MockUserClient

            session.insertTeam(withName: "Team Foo", isBound: false, users: Set<MockUser>(arrayLiteral: selfUser, otherUser))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let messageData = "secret message".data(using: .utf8)!

        let payload : [String : Any] = [
            "sender": selfClient.identifier!,
            "recipients": [:]
        ]

        let protoPayload = selfClient.otrMessageBuilderWithRecipients(for: [], plainText: messageData).build().data()

        // when
        let responseJSON = self.response(forPayload: payload as ZMTransportData, path: "/broadcast/otr/messages", method: .methodPOST)
        let responsePROTO = self.response(forProtobufData: protoPayload, path: "/broadcast/otr/messages", method: .methodPOST)

        // then
        for response in [responseJSON, responsePROTO] {
            XCTAssertNotNil(response)

            if let response = response {
                XCTAssertEqual(response.httpStatus, 412)

                let expectedPayload = [
                    "missing"  : [ otherUser.identifier : [otherUserClient.identifier!] ],
                    "redundant" : [:]
                ]

                assertExpectedPayload(expectedPayload, in: response)
            }
        }
    }

    func testThatItAcceptsTeamMembersAsReceiversWhenReceivingOTRMessage() {
        // given
        var selfUser : MockUser!
        var selfClient : MockUserClient!

        var otherUser : MockUser!
        var otherUserClient : MockUserClient!

        sut.performRemoteChanges { session in
            selfUser = session.insertSelfUser(withName: "Self User")
            selfClient = session.registerClient(for: selfUser, label: "self user", type: "permanent", deviceClass: "phone")

            otherUser = session.insertUser(withName: "Team member1")
            otherUserClient = otherUser.clients.anyObject() as? MockUserClient

            session.insertTeam(withName: "Team Foo", isBound: false, users: Set<MockUser>(arrayLiteral: selfUser, otherUser))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let messageData = "secret message".data(using: .utf8)!
        let base64Content = messageData.base64EncodedString()

        let payload : [String : Any] = [
            "sender": selfClient.identifier!,
            "recipients": [ otherUser.identifier : [ otherUserClient.identifier!: base64Content] ]
        ]

        let protoPayload = selfClient.otrMessageBuilderWithRecipients(for: [otherUserClient], plainText: messageData).build().data()

        // when
        let responseJSON = self.response(forPayload: payload as ZMTransportData, path: "/broadcast/otr/messages", method: .methodPOST)
        let responsePROTO = self.response(forProtobufData: protoPayload, path: "/broadcast/otr/messages", method: .methodPOST)

        // then
        for response in [responseJSON, responsePROTO] {
            XCTAssertNotNil(response)

            if let response = response {
                XCTAssertEqual(response.httpStatus, 201)

                let expectedPayload = [
                    "missing"  : [:],
                    "redundant" : [:]
                ]

                assertExpectedPayload(expectedPayload, in: response)
            }
        }
    }

    func testThatItAcceptsConnectedUsersAsReceiversWhenReceivingOTRMessage() {
        // given
        var selfUser : MockUser!
        var selfClient : MockUserClient!

        var otherUser : MockUser!
        var otherUserClient : MockUserClient!

        sut.performRemoteChanges { session in
            selfUser = session.insertSelfUser(withName: "Self User")
            selfClient = session.registerClient(for: selfUser, label: "self user", type: "permanent", deviceClass: "phone")

            otherUser = session.insertUser(withName: "Team member1")
            otherUserClient = otherUser.clients.anyObject() as? MockUserClient

            let connection = session.insertConnection(withSelfUser: selfUser, to: otherUser)
            connection.status = "accepted"
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let messageData = "secret message".data(using: .utf8)!
        let base64Content = messageData.base64EncodedString()

        let payload : [String : Any] = [
            "sender": selfClient.identifier!,
            "recipients": [ otherUser.identifier : [ otherUserClient.identifier!: base64Content] ]
        ]
        let protoPayload = selfClient.otrMessageBuilderWithRecipients(for: [otherUserClient], plainText: messageData).build().data()

        // when
        let responseJSON = self.response(forPayload: payload as ZMTransportData, path: "/broadcast/otr/messages", method: .methodPOST)
        let responsePROTO = self.response(forProtobufData: protoPayload, path: "/broadcast/otr/messages", method: .methodPOST)

        // then
        for response in [responseJSON, responsePROTO] {
            XCTAssertNotNil(response)

            if let response = response {
                XCTAssertEqual(response.httpStatus, 201)

                let expectedPayload = [
                    "missing"  : [:],
                    "redundant" : [:]
                ]

                assertExpectedPayload(expectedPayload, in: response)
            }
        }
    }

}
