//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireDataModelSupport
import XCTest

@preconcurrency @testable import WireDataModel

@preconcurrency
class ZMUserLegalHoldTests: ModelObjectsTests {

    override func setUp() {
        DeveloperFlag.storage = .temporary()
        var flag = DeveloperFlag.proteusViaCoreCrypto
        flag.isOn = false
        super.setUp()
    }

    override func tearDown() {
        DeveloperFlag.storage = .standard
        super.tearDown()
    }

    func testThatLegalHoldStatusIsDisabled_ByDefault() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .disabled)
    }

    func testThatLegalHoldStatusIsDisabled_AfterCancelingRequest() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let request = LegalHoldRequest.mockRequest(for: selfUser)
        selfUser.userDidReceiveLegalHoldRequest(request)

        // WHEN
        selfUser.legalHoldRequestWasCancelled()

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .disabled)
        XCTAssertFalse(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatLegalHoldStatusIsDisabled_AfterReceivingRequestTargetingAnotherUser() {
        // GIVEN
        let otherUser = createUser(in: uiMOC)
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // WHEN
        let request = LegalHoldRequest.mockRequest(for: otherUser)
        selfUser.userDidReceiveLegalHoldRequest(request)

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .disabled)
        XCTAssertFalse(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatLegalHoldStatusIsPending_AfterReceivingRequest() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // WHEN
        let request = LegalHoldRequest.mockRequest(for: selfUser)
        selfUser.userDidReceiveLegalHoldRequest(request)

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .pending(request))
        XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatLegalHoldStatusIsEnabled_AfterAcceptingRequest() async throws {
        // GIVEN

        let (legalHoldRequest, selfUser, conversationOID) = await syncMOC.perform { [self, syncMOC] in

            let mockProteusService = MockProteusServiceInterface()
            mockProteusService.establishSessionIdFromPrekey_MockMethod = { _, _ in }
            syncMOC.proteusService = mockProteusService

            let selfUser = ZMUser.selfUser(in: syncMOC)
            createSelfClient(onMOC: syncMOC)

            let conversation = createConversation(in: syncMOC)
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

            let legalHoldRequest = LegalHoldRequest.mockRequest(for: selfUser)
            selfUser.userDidReceiveLegalHoldRequest(legalHoldRequest)

            return (legalHoldRequest, selfUser, conversation.objectID)
        }

        // WHEN
        _ = await selfUser.addLegalHoldClient(from: legalHoldRequest)

        try await syncMOC.perform { [selfUserOID = selfUser.objectID, syncMOC] in
            let selfUser = try syncMOC.existingObject(with: selfUserOID) as! ZMUser
            let conversation = try syncMOC.existingObject(with: conversationOID) as! ZMConversation

            selfUser.userDidAcceptLegalHoldRequest(legalHoldRequest)

            // THEN
            XCTAssertEqual(selfUser.legalHoldStatus, .enabled)
            XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
            XCTAssertTrue(
                conversation.allMessages
                    .contains { ($0 as? ZMSystemMessage)?.systemMessageType == .legalHoldEnabled }
            )
            XCTAssertTrue(conversation.isUnderLegalHold)
        }
    }

    func testThatLegalHoldStatusIsEnabled_AfterAddingClient() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // WHEN
        UserClient.createMockLegalHoldSelfUserClient(in: uiMOC)

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .enabled)
        XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatItDoesntClearNotificationFlag_AfterAddingNormalClient() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // WHEN
        UserClient.createMockLegalHoldSelfUserClient(in: uiMOC)
        UserClient.createMockPhoneUserClient(in: uiMOC)

        // THEN
        XCTAssertEqual(selfUser.legalHoldStatus, .enabled)
        XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
    }

    func testThatLegalHoldStatusIsDisabled_AfterRemovingClient() async {
        // GIVEN
        var selfUser: ZMUser!
        var legalHoldClient: UserClient!

        await syncMOC.perform { [syncMOC] in
            selfUser = ZMUser.selfUser(in: syncMOC)
            legalHoldClient = UserClient.createMockLegalHoldSelfUserClient(in: syncMOC)
            XCTAssertEqual(selfUser.legalHoldStatus, .enabled)

            selfUser.acknowledgeLegalHoldStatus()
            XCTAssertFalse(selfUser.needsToAcknowledgeLegalHoldStatus)
        }

        // WHEN
        await legalHoldClient.deleteClientAndEndSession()

        // THEN
        await syncMOC.perform {
            XCTAssertEqual(selfUser.legalHoldStatus, .disabled)
            XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
        }
    }

    func testThatItDoesntClearNotificationFlag_AfterRemovingNormalClient() async {
        // GIVEN
        var selfUser: ZMUser!
        var normalClient: UserClient!

        await syncMOC.perform { [syncMOC] in
            selfUser = ZMUser.selfUser(in: syncMOC)
            normalClient = UserClient.createMockPhoneUserClient(in: syncMOC)
            UserClient.createMockLegalHoldSelfUserClient(in: syncMOC)
            XCTAssertEqual(selfUser.legalHoldStatus, .enabled)
        }

        // WHEN
        await normalClient.deleteClientAndEndSession()

        // THEN
        await syncMOC.perform {
            XCTAssertEqual(selfUser.legalHoldStatus, .enabled)
            XCTAssertTrue(selfUser.needsToAcknowledgeLegalHoldStatus)
        }
    }

}

extension LegalHoldRequest {

    static func mockRequest(for user: ZMUser) -> LegalHoldRequest {
        let prekey = LegalHoldRequest.Prekey(
            id: 65_535,
            key: Data(
                base64Encoded: "pQABARn//wKhAFggHsa0CszLXYLFcOzg8AA//E1+Dl1rDHQ5iuk44X0/PNYDoQChAFgg309rkhG6SglemG6kWae81P1HtQPx9lyb6wExTovhU4cE9g=="
            )!
        )
        return LegalHoldRequest(
            target: user.remoteIdentifier!,
            requester: UUID(),
            clientIdentifier: "eca3c87cfe28be49",
            lastPrekey: prekey
        )
    }

}

extension UserClient {

    @discardableResult
    static func createMockLegalHoldSelfUserClient(in moc: NSManagedObjectContext) -> UserClient {
        let payload: [String: AnyObject] = [
            "id": UUID().transportString() as NSString,
            "type": DeviceType.legalHold.rawValue as NSString,
            "class": DeviceClass.legalHold.rawValue as NSString,
            "time": NSDate()
        ]

        return createOrUpdateSelfUserClient(payload, context: moc)!
    }

    @discardableResult
    static func createMockPhoneUserClient(in moc: NSManagedObjectContext) -> UserClient {
        let payload: [String: AnyObject] = [
            "id": UUID().transportString() as NSString,
            "type": DeviceType.permanent.rawValue as NSString,
            "class": DeviceClass.phone.rawValue as NSString,
            "time": NSDate()
        ]

        return createOrUpdateSelfUserClient(payload, context: moc)!
    }

}
