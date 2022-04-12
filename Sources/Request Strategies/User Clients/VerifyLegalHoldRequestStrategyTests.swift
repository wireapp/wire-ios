// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
@testable import WireRequestStrategy

struct ClientUpdateResponse: Codable {

    typealias ClientList = [String: [String]]

    enum ErrorLabel: String, Codable {
        case unknownClient = "unknown-client"
    }

    var label: ErrorLabel?
    var missing: ClientList?
    var deleted: ClientList?
    var redundant: ClientList?

}

class VerifyLegalHoldRequestStrategyTests: MessagingTestBase {

    var sut: VerifyLegalHoldRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        sut = VerifyLegalHoldRequestStrategy(withManagedObjectContext: self.syncMOC, applicationStatus: mockApplicationStatus)
    }

    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        super.tearDown()
    }

    func missingClientsResponse(_ clientUpdateResponse: ClientUpdateResponse) -> ZMTransportData {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(clientUpdateResponse)
        return try! JSONSerialization.jsonObject(with: encoded, options: []) as! ZMTransportData
    }

    // MARK: Request generation

    func testThatItCreatesARequest_WhenConversationNeedsToVerifyLegalHold() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> =  [conversation]

            // WHEN
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            self.sut.objectsDidChange(conversationSet)

            // THEN
            XCTAssertEqual(self.sut.nextRequest(for: .v0)?.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/otr/messages")
        }
    }

    // MARK: Response handling

    func testThatItResetsNeedsToVerifyLegalHoldFlag_WhenReceivingTheResponse() {
        var conversation: ZMConversation!
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            conversation = self.createGroupConversation(with: self.otherUser)
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            let conversationSet: Set<NSManagedObject> = [conversation]
            self.sut.objectsDidChange(conversationSet)
            let request = self.sut.nextRequest(for: .v0)

            // WHEN
            request?.complete(with: ZMTransportResponse(payload: [:] as ZMTransportData, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(conversation.needsToVerifyLegalHold)
        }
    }

    func testThatItRegistersMissingClients() {
        var conversation: ZMConversation!
        let clientID = "client123"
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> = [conversation]
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))

            self.sut.objectsDidChange(conversationSet)
            let request = self.sut.nextRequest(for: .v0)
            let payload = self.missingClientsResponse(ClientUpdateResponse(label: nil, missing: [self.otherUser.remoteIdentifier.transportString(): [clientID]], deleted: nil, redundant: nil))

            // WHEN
            request?.complete(with: ZMTransportResponse(payload: payload, httpStatus: 412, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            guard let client = UserClient.fetchUserClient(withRemoteId: clientID, forUser: self.otherUser, createIfNeeded: false) else { return XCTFail("Failed to fetch client") }

            XCTAssertEqual(client.remoteIdentifier, clientID)
        }
    }

    func testThatItDeletesDeletedClients() {
        var conversation: ZMConversation!
        let deletedClientID = "client1"
        let existingClientID = "client2"
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            XCTAssertNotNil(UserClient.fetchUserClient(withRemoteId: deletedClientID, forUser: self.otherUser, createIfNeeded: true))
            XCTAssertNotNil(UserClient.fetchUserClient(withRemoteId: existingClientID, forUser: self.otherUser, createIfNeeded: true))

            conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> = [conversation]
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            self.sut.objectsDidChange(conversationSet)

            let request = self.sut.nextRequest(for: .v0)
            let payload = self.missingClientsResponse(ClientUpdateResponse(label: nil, missing: [self.otherUser.remoteIdentifier.transportString(): [existingClientID]], deleted: nil, redundant: nil))

            // WHEN
            request?.complete(with: ZMTransportResponse(payload: payload, httpStatus: 412, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            guard let existingClient = UserClient.fetchUserClient(withRemoteId: existingClientID, forUser: self.otherUser, createIfNeeded: false) else { return XCTFail("Failed to fetch existing client") }

            XCTAssertNil(UserClient.fetchUserClient(withRemoteId: deletedClientID, forUser: self.otherUser, createIfNeeded: false))
            XCTAssertEqual(existingClient.remoteIdentifier, existingClientID)
        }
    }

    func testThatItDeletesAllClients_WhenUserHasNoMissingClientEntry() {
        var conversation: ZMConversation!
        let deletedClientID = "client1"
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            XCTAssertNotNil(UserClient.fetchUserClient(withRemoteId: deletedClientID, forUser: self.otherUser, createIfNeeded: true))

            conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> = [conversation]
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            self.sut.objectsDidChange(conversationSet)

            let request = self.sut.nextRequest(for: .v0)
            let payload = self.missingClientsResponse(ClientUpdateResponse(label: nil, missing: [:], deleted: nil, redundant: nil))

            // WHEN
            request?.complete(with: ZMTransportResponse(payload: payload, httpStatus: 412, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(UserClient.fetchUserClient(withRemoteId: deletedClientID, forUser: self.otherUser, createIfNeeded: false))
        }
    }

    func testThatItIgnoresMissingSelfClients() {
        var conversation: ZMConversation!
        let selfClientID = "selfClient1"

        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            conversation = self.createGroupConversation(with: self.otherUser)
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            let clientSet: Set<NSManagedObject> = [conversation]
            self.sut.objectsDidChange(clientSet)

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let request = self.sut.nextRequest(for: .v0)
            let payload = self.missingClientsResponse(ClientUpdateResponse(label: nil, missing: [selfUser.remoteIdentifier.transportString(): [selfClientID]], deleted: nil, redundant: nil))

            // WHEN
            request?.complete(with: ZMTransportResponse(payload: payload, httpStatus: 412, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)

            XCTAssertNotNil(selfUser.selfClient())
        }
    }

}
