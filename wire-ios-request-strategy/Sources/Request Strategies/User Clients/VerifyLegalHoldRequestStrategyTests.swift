//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

private typealias ClientListByUser = [String: [String]]
private typealias UserListByDomain = [String: ClientListByUser]

// MARK: - TransportDataConvertible

private protocol TransportDataConvertible: Codable {
    var transportData: ZMTransportData { get }
}

extension TransportDataConvertible {
    fileprivate var transportData: ZMTransportData {
        let encoded = try! JSONEncoder.defaultEncoder.encode(self)
        return try! JSONSerialization.jsonObject(with: encoded, options: []) as! ZMTransportData
    }
}

// MARK: - ClientUpdateResponse

private struct ClientUpdateResponse: Codable, TransportDataConvertible {
    // MARK: Lifecycle

    init(missing: ClientListByUser) {
        self.missing = missing
    }

    // MARK: Internal

    enum ErrorLabel: String, Codable {
        case unknownClient = "unknown-client"
    }

    var label: ErrorLabel?
    var missing: ClientListByUser?
    var deleted: ClientListByUser?
    var redundant: ClientListByUser?
}

// MARK: - Payload.MessageSendingStatusV1 + TransportDataConvertible

extension Payload.MessageSendingStatusV1: TransportDataConvertible {
    fileprivate init(missing: UserListByDomain) {
        self.init(
            time: .init(),
            missing: missing,
            redundant: .init(),
            deleted: .init(),
            failedToSend: .init()
        )
    }
}

// MARK: - Payload.MessageSendingStatusV4 + TransportDataConvertible

extension Payload.MessageSendingStatusV4: TransportDataConvertible {
    fileprivate init(missing: UserListByDomain) {
        self.init(
            time: .init(),
            missing: missing,
            redundant: .init(),
            deleted: .init(),
            failedToSend: .init(),
            failedToConfirm: .init()
        )
    }
}

// MARK: - VerifyLegalHoldRequestStrategyTests

class VerifyLegalHoldRequestStrategyTests: MessagingTestBase {
    // MARK: Internal

    var sut: VerifyLegalHoldRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        sut = VerifyLegalHoldRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus
        )
    }

    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        super.tearDown()
    }

    // MARK: Request generation

    func testThatItCreatesARequest_WhenConversationNeedsToVerifyLegalHold() {
        testThatItCreatesARequest_WhenConversationNeedsToVerifyLegalHold(apiVersion: .v0)
        testThatItCreatesARequest_WhenConversationNeedsToVerifyLegalHold(apiVersion: .v1)
    }

    func testThatItCreatesARequest_WhenConversationNeedsToVerifyLegalHold(apiVersion: APIVersion) {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> = [conversation]

            // WHEN
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            self.sut.objectsDidChange(conversationSet)

            // THEN
            var expectedPath =
                switch apiVersion {
                case .v0:
                    "/conversations/\(conversation.remoteIdentifier!.transportString())/otr/messages"
                case .v1,
                     .v2,
                     .v3,
                     .v4,
                     .v5,
                     .v6:
                    "/v\(apiVersion.rawValue)/conversations/\(conversation.domain!)/\(conversation.remoteIdentifier!.transportString())/proteus/messages"
                }

            XCTAssertEqual(self.sut.nextRequest(for: apiVersion)?.path, expectedPath)
        }
    }

    // MARK: Response handling

    func testThatItResetsNeedsToVerifyLegalHoldFlag_WhenReceivingTheResponse() {
        var conversation: ZMConversation!
        syncMOC.performGroupedAndWait {
            // GIVEN
            conversation = self.createGroupConversation(with: self.otherUser)
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            let conversationSet: Set<NSManagedObject> = [conversation]
            self.sut.objectsDidChange(conversationSet)
            let request = self.sut.nextRequest(for: .v0)

            // WHEN
            request?.complete(with: ZMTransportResponse(
                payload: [:] as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedAndWait {
            XCTAssertFalse(conversation.needsToVerifyLegalHold)
        }
    }

    func testThatItRegistersMissingClients() {
        testThatItRegistersMissingClients(apiVersion: .v0)
        testThatItRegistersMissingClients(apiVersion: .v1)
    }

    func testThatItDeletesDeletedClients() {
        testThatItRegistersMissingClients(apiVersion: .v0)
        testThatItRegistersMissingClients(apiVersion: .v1)
    }

    func testThatItDeletesAllClients_WhenUserHasNoMissingClientEntry() {
        testThatItDeletesAllClients_WhenUserHasNoMissingClientEntry(apiVersion: .v0)
        testThatItDeletesAllClients_WhenUserHasNoMissingClientEntry(apiVersion: .v1)
    }

    func testThatItIgnoresMissingSelfClients() {
        testThatItIgnoresMissingSelfClients(apiVersion: .v0)
        testThatItIgnoresMissingSelfClients(apiVersion: .v1)
    }

    // MARK: Private

    private func testThatItRegistersMissingClients(apiVersion: APIVersion) {
        var conversation: ZMConversation!
        let clientID = "client123"

        syncMOC.performGroupedAndWait {
            // GIVEN
            conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> = [conversation]
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))

            self.sut.objectsDidChange(conversationSet)
            let request = self.sut.nextRequest(for: apiVersion)
            let clientListByUserID = [self.otherUser.remoteIdentifier.transportString(): [clientID]]

            var transportData: ZMTransportData =
                switch apiVersion {
                case .v0:
                    ClientUpdateResponse(missing: clientListByUserID).transportData
                case .v1,
                     .v2,
                     .v3:
                    Payload.MessageSendingStatusV1(missing: [self.otherUser.domain!: clientListByUserID]).transportData
                case .v4,
                     .v5,
                     .v6:
                    Payload.MessageSendingStatusV4(missing: [self.otherUser.domain!: clientListByUserID]).transportData
                }

            // WHEN
            request?.complete(with: ZMTransportResponse(
                payload: transportData,
                httpStatus: 412,
                transportSessionError: nil,
                apiVersion: apiVersion.rawValue
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedAndWait {
            guard let client = UserClient.fetchUserClient(
                withRemoteId: clientID,
                forUser: self.otherUser,
                createIfNeeded: false
            ) else {
                return XCTFail("Failed to fetch client")
            }

            XCTAssertEqual(client.remoteIdentifier, clientID)
        }
    }

    private func testThatItDeletesDeletedClients(apiVersion: APIVersion) {
        var conversation: ZMConversation!
        let deletedClientID = "client1"
        let existingClientID = "client2"
        syncMOC.performGroupedAndWait {
            // GIVEN
            XCTAssertNotNil(UserClient.fetchUserClient(
                withRemoteId: deletedClientID,
                forUser: self.otherUser,
                createIfNeeded: true
            ))
            XCTAssertNotNil(UserClient.fetchUserClient(
                withRemoteId: existingClientID,
                forUser: self.otherUser,
                createIfNeeded: true
            ))

            conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> = [conversation]
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            self.sut.objectsDidChange(conversationSet)

            let request = self.sut.nextRequest(for: apiVersion)
            let clientListByUserID = [self.otherUser.remoteIdentifier.transportString(): [existingClientID]]

            var transportData: ZMTransportData =
                switch apiVersion {
                case .v0:
                    ClientUpdateResponse(missing: clientListByUserID).transportData
                case .v1,
                     .v2,
                     .v3:
                    Payload.MessageSendingStatusV1(missing: [self.otherUser.domain!: clientListByUserID]).transportData
                case .v4,
                     .v5,
                     .v6:
                    Payload.MessageSendingStatusV4(missing: [self.otherUser.domain!: clientListByUserID]).transportData
                }

            // WHEN
            request?.complete(with: ZMTransportResponse(
                payload: transportData,
                httpStatus: 412,
                transportSessionError: nil,
                apiVersion: apiVersion.rawValue
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedAndWait {
            guard let existingClient = UserClient.fetchUserClient(
                withRemoteId: existingClientID,
                forUser: self.otherUser,
                createIfNeeded: false
            ) else {
                return XCTFail("Failed to fetch existing client")
            }

            XCTAssertNil(UserClient.fetchUserClient(
                withRemoteId: deletedClientID,
                forUser: self.otherUser,
                createIfNeeded: false
            ))
            XCTAssertEqual(existingClient.remoteIdentifier, existingClientID)
        }
    }

    private func testThatItDeletesAllClients_WhenUserHasNoMissingClientEntry(apiVersion: APIVersion) {
        var conversation: ZMConversation!
        let deletedClientID = "client1"
        syncMOC.performGroupedAndWait {
            // GIVEN
            XCTAssertNotNil(UserClient.fetchUserClient(
                withRemoteId: deletedClientID,
                forUser: self.otherUser,
                createIfNeeded: true
            ))

            conversation = self.createGroupConversation(with: self.otherUser)
            let conversationSet: Set<NSManagedObject> = [conversation]
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            self.sut.objectsDidChange(conversationSet)

            let request = self.sut.nextRequest(for: apiVersion)

            var transportData: ZMTransportData =
                switch apiVersion {
                case .v0:
                    ClientUpdateResponse(missing: ClientListByUser()).transportData
                case .v1,
                     .v2,
                     .v3:
                    Payload.MessageSendingStatusV1(missing: UserListByDomain()).transportData
                case .v4,
                     .v5,
                     .v6:
                    Payload.MessageSendingStatusV4(missing: UserListByDomain()).transportData
                }

            // WHEN
            request?.complete(with: ZMTransportResponse(
                payload: transportData,
                httpStatus: 412,
                transportSessionError: nil,
                apiVersion: apiVersion.rawValue
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedAndWait {
            XCTAssertNil(UserClient.fetchUserClient(
                withRemoteId: deletedClientID,
                forUser: self.otherUser,
                createIfNeeded: false
            ))
        }
    }

    private func testThatItIgnoresMissingSelfClients(apiVersion: APIVersion) {
        var conversation: ZMConversation!
        let selfClientID = "selfClient1"

        syncMOC.performGroupedAndWait {
            // GIVEN
            conversation = self.createGroupConversation(with: self.otherUser)
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            let clientSet: Set<NSManagedObject> = [conversation]
            self.sut.objectsDidChange(clientSet)

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.domain = "example.com"
            let request = self.sut.nextRequest(for: apiVersion)
            let clientListByUserID = [selfUser.remoteIdentifier.transportString(): [selfClientID]]

            var transportData: ZMTransportData =
                switch apiVersion {
                case .v0:
                    ClientUpdateResponse(missing: clientListByUserID).transportData
                case .v1,
                     .v2,
                     .v3:
                    Payload.MessageSendingStatusV1(missing: [selfUser.domain!: clientListByUserID]).transportData
                case .v4,
                     .v5,
                     .v6:
                    Payload.MessageSendingStatusV4(missing: [selfUser.domain!: clientListByUserID]).transportData
                }

            // WHEN
            request?.complete(with: ZMTransportResponse(
                payload: transportData,
                httpStatus: 412,
                transportSessionError: nil,
                apiVersion: apiVersion.rawValue
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedAndWait {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)

            XCTAssertNotNil(selfUser.selfClient())
        }
    }
}
