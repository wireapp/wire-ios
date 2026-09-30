//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireCallingDomain
import WireDataModel
import WireDataModelSupport
import WireDomain
import WireDomainSupport
import WireFoundation
import WireNetworkSupport
import WireRequestStrategy
import XCTest

@testable import Wire

final class MeetingConversationRepositoryBridgeTests: XCTestCase {

    func testDeleteConversation_DeletesAndSavesMeetingConversation() async throws {
        try await checkDeleteConversation(groupType: .meeting, expectedDeletion: true)
    }

    func testDeleteConversation_PreservesLinkedGroupConversation() async throws {
        try await checkDeleteConversation(groupType: .group, expectedDeletion: false)
    }

    private func checkDeleteConversation(
        groupType: ConversationGroupType,
        expectedDeletion: Bool
    ) async throws {
        let stackHelper = CoreDataStackHelper()
        let stack = try await stackHelper.createStack()
        addTeardownBlock { try stackHelper.cleanupDirectory() }
        let syncContext = stack.syncContext
        let conversationID = WireCallingDomain.QualifiedID(id: UUID(), domain: "wire.com")
        let groupID = MLSGroupID(Data([1, 2, 3]))

        try await syncContext.perform {
            let conversation = ModelHelper().createMLSConversation(
                id: conversationID.id,
                domain: conversationID.domain,
                mlsGroupID: groupID,
                in: syncContext
            )
            conversation.groupType = groupType
            try syncContext.save()
        }

        let mlsService = MockMLSServiceInterface()
        mlsService.wipeGroup_MockMethod = { _ in }
        let localStore = ConversationLocalStore(
            context: syncContext,
            mlsService: mlsService,
            messageLocalStore: MockMessageLocalStoreProtocol(),
            localDomain: conversationID.domain,
            isFederationEnabled: false
        )
        let repository = ConversationRepository(
            conversationsAPI: MockConversationsAPI(),
            conversationsLocalStore: localStore,
            userLocalStore: MockUserLocalStoreProtocol(),
            teamRepository: MockTeamRepositoryProtocol(),
            messageRepository: MockMessageRepositoryProtocol(),
            localDomain: conversationID.domain,
            isFederationEnabled: false,
            isMLSEnabled: true,
            mlsProvider: MLSProvider(service: mlsService, isMLSEnabled: true)
        )
        let sut = MeetingConversationRepositoryBridge(
            conversationRepository: repository,
            contextProvider: stack,
            participantsService: ConversationParticipantsService(
                context: syncContext,
                localDomain: conversationID.domain
            ),
            isNetworkAvailable: { true }
        )

        try await sut.deleteConversation(id: conversationID)

        XCTAssertEqual(mlsService.wipeGroup_Invocations, expectedDeletion ? [groupID] : [])
        let persistedContext = stack.newBackgroundContext()
        let isDeleted = try await persistedContext.perform {
            let conversation = try XCTUnwrap(ZMConversation.fetch(
                with: conversationID.id,
                domain: conversationID.domain,
                in: persistedContext
            ))
            return conversation.isDeletedRemotely
        }
        XCTAssertEqual(isDeleted, expectedDeletion)
    }

}
