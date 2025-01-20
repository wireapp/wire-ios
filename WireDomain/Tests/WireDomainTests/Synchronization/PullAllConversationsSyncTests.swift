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

import WireAPISupport
import XCTest
@testable import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class PullAllConversationsSyncTests: XCTestCase {

    private var sut: PullAllConversationsSync!
    private var api: MockConversationsAPI!
    private var store: MockConversationLocalStoreProtocol!

    override func setUp() async throws {
        api = MockConversationsAPI()
        store = MockConversationLocalStoreProtocol()
        sut = PullAllConversationsSync(
            localDomain: Scaffolding.localDomain,
            isFederationEnabled: Scaffolding.isFederationEnabled,
            isMLSEnabled: Scaffolding.isMLSEnabled,
            api: api,
            store: store
        )
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        sut = nil
    }

    func testPull() async throws {
        // Mock
        api.getConversationIdentifiers_MockValue = .init(fetchPage: { _ in
            .init(
                element: Scaffolding.conversationIDs,
                hasMore: false,
                nextStart: .init()
            )
        })

        api.getConversationsFor_MockValue = .init(
            found: [Scaffolding.remoteConversation1],
            notFound: [Scaffolding.conversationID2],
            failed: [Scaffolding.conversationID3]
        )

        store.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }
        store.storeConversationNeedsBackendUpdateConversationIDConversationDomain_MockMethod = { _, _, _ in }
        store.storeFailedConversationConversationIDConversationDomain_MockMethod = { _, _ in }

        // When
        try await sut.pull()

        // Then
        XCTAssertEqual(api.getConversationIdentifiers_Invocations.count, 1)

        try XCTAssertCount(api.getConversationsFor_Invocations, count: 1)
        XCTAssertEqual(api.getConversationsFor_Invocations[0], Scaffolding.conversationIDs)

        let storeFoundInvocations = store.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations
        try XCTAssertCount(storeFoundInvocations, count: 1)
        XCTAssertEqual(storeFoundInvocations[0].conversation, Scaffolding.localConversation1)
        XCTAssertEqual(storeFoundInvocations[0].isFederationEnabled, Scaffolding.isFederationEnabled)
        XCTAssertEqual(storeFoundInvocations[0].isMLSEnabled, Scaffolding.isMLSEnabled)

        let storeNotFoundInvocations = store
            .storeConversationNeedsBackendUpdateConversationIDConversationDomain_Invocations
        try XCTAssertCount(storeNotFoundInvocations, count: 1)
        XCTAssertEqual(storeNotFoundInvocations[0].needsBackendUpdate, true)
        XCTAssertEqual(storeNotFoundInvocations[0].conversationID, Scaffolding.conversationID2.uuid)
        XCTAssertEqual(storeNotFoundInvocations[0].conversationDomain, Scaffolding.conversationID2.domain)

        let storeFailedInvocations = store.storeFailedConversationConversationIDConversationDomain_Invocations
        try XCTAssertCount(storeFailedInvocations, count: 1)
        XCTAssertEqual(storeFailedInvocations[0].conversationID, Scaffolding.conversationID3.uuid)
        XCTAssertEqual(storeFailedInvocations[0].conversationDomain, Scaffolding.conversationID3.domain)
    }

    // TODO: [WPB-15185] Re-enable
    func testPull_LegacyIdentifiers() async throws {
        // Mock
        api.getConversationIdentifiers_MockError = ConversationsAPIError.notImplemented
        api.getLegacyConversationIdentifiers_MockValue = .init(fetchPage: { _ in
            .init(
                element: Scaffolding.conversationIDs.map(\.uuid),
                hasMore: false,
                nextStart: .init()
            )
        })

        api.getConversationsFor_MockValue = .init(
            found: [Scaffolding.remoteConversation1],
            notFound: [Scaffolding.conversationID2],
            failed: [Scaffolding.conversationID3]
        )

        store.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }
        store.storeConversationNeedsBackendUpdateConversationIDConversationDomain_MockMethod = { _, _, _ in }
        store.storeFailedConversationConversationIDConversationDomain_MockMethod = { _, _ in }

        // When
        try await sut.pull()

        // Then
        XCTAssertEqual(api.getConversationsFor_Invocations.count, 1)
        XCTAssertEqual(
            store.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.count,
            1
        )

        // Then
        XCTAssertEqual(api.getConversationIdentifiers_Invocations.count, 1)

        try XCTAssertCount(api.getConversationsFor_Invocations, count: 1)
        XCTAssertEqual(api.getConversationsFor_Invocations[0], Scaffolding.conversationIDs)

        let storeFoundInvocations = store.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations
        try XCTAssertCount(storeFoundInvocations, count: 1)
        XCTAssertEqual(storeFoundInvocations[0].conversation, Scaffolding.localConversation1)
        XCTAssertEqual(storeFoundInvocations[0].isFederationEnabled, Scaffolding.isFederationEnabled)
        XCTAssertEqual(storeFoundInvocations[0].isMLSEnabled, Scaffolding.isMLSEnabled)

        let storeNotFoundInvocations = store
            .storeConversationNeedsBackendUpdateConversationIDConversationDomain_Invocations
        try XCTAssertCount(storeNotFoundInvocations, count: 1)
        XCTAssertEqual(storeNotFoundInvocations[0].needsBackendUpdate, true)
        XCTAssertEqual(storeNotFoundInvocations[0].conversationID, Scaffolding.conversationID2.uuid)
        XCTAssertEqual(storeNotFoundInvocations[0].conversationDomain, Scaffolding.conversationID2.domain)

        let storeFailedInvocations = store.storeFailedConversationConversationIDConversationDomain_Invocations
        try XCTAssertCount(storeFailedInvocations, count: 1)
        XCTAssertEqual(storeFailedInvocations[0].conversationID, Scaffolding.conversationID3.uuid)
        XCTAssertEqual(storeFailedInvocations[0].conversationDomain, Scaffolding.conversationID3.domain)
    }

}

private enum Scaffolding {

    static let localDomain = "wire.com"
    static let isFederationEnabled = false
    static let isMLSEnabled = false

    static let conversationID1 = QualifiedID(uuid: UUID(), domain: localDomain)
    static let conversationID2 = QualifiedID(uuid: UUID(), domain: localDomain)
    static let conversationID3 = QualifiedID(uuid: UUID(), domain: localDomain)

    static var conversationIDs: [QualifiedID] {
        [
            conversationID1,
            conversationID2,
            conversationID3
        ]
    }

    static let remoteConversation1 = WireAPI.Conversation(
        id: conversationID1.uuid,
        qualifiedID: conversationID1,
        teamID: UUID(),
        type: .group,
        messageProtocol: .proteus,
        mlsGroupID: nil,
        cipherSuite: nil,
        epoch: nil,
        epochTimestamp: nil,
        creator: UUID(),
        members: nil,
        name: "conversation 1",
        messageTimer: nil,
        readReceiptMode: nil,
        access: nil,
        accessRoles: nil,
        legacyAccessRole: nil,
        lastEvent: nil,
        lastEventTime: nil
    )

    static var localConversation1: WireDomain.Conversation {
        remoteConversation1.toDomainModel()
    }

}
