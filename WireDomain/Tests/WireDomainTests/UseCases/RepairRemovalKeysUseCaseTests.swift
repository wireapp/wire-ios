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

import Foundation
import Testing
import WireDataModel
import WireDataModelSupport
import WireFoundation
import WireNetwork

@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetworkSupport

struct RepairRemovalKeysUseCaseTests {

    let sut: RepairRemovalKeysUseCase
    let coreDataStack: CoreDataStack
    let mlsService = MockMLSServiceInterface()
    let conversationsAPI = MockConversationsAPIProtocol()
    let conversationLocalStore: ConversationLocalStore
    let initiateResetUseCase = MockInitiateResetMLSConversationUseCaseProtocol()

    let validKey = Data([4, 5, 6])
    let faultyKey = Data([1, 2, 3])
    let affectedDomain = "apple.com"

    let affectedGroupMLSGroupID = MLSGroupID.random()
    let affectedOneOnOneMLSGroupID = MLSGroupID.random()
    let nonAffectedGroupMLSGroupID = MLSGroupID.random()
    let otherDomainMLSGroupID = MLSGroupID.random()

    init() async throws {
        let coreDataStackHelper = CoreDataStackHelper(localDomain: affectedDomain)
        self.coreDataStack = try await coreDataStackHelper.createStack()
        let context = coreDataStack.syncContext
        let messageLocalStore = MessageLocalStore(context: context)
        self.conversationLocalStore = ConversationLocalStore(
            context: context,
            mlsService: mlsService,
            messageLocalStore: messageLocalStore,
            localDomain: affectedDomain,
            isFederationEnabled: true
        )
        self.sut = RepairRemovalKeysUseCase(
            faultyMLSRemovalKeysByDomain: [affectedDomain: [Data([1, 2, 3]).zmHexEncodedString()]],
            context: context,
            mlsService: mlsService,
            conversationsAPI: conversationsAPI,
            conversationLocalStore: conversationLocalStore,
            initiateResetUseCase: initiateResetUseCase
        )

        await context.perform { [self] in
            let modelHelper = ModelHelper()
            let selfUser = modelHelper.createSelfUser(
                id: UUID(),
                domain: affectedDomain,
                in: context
            )
            let otherUser = modelHelper.createUser(
                id: UUID(),
                domain: affectedDomain,
                supportedProtocols: [.mls],
                in: context
            )
            modelHelper.createMLSConversation(
                id: UUID(),
                domain: affectedDomain,
                mlsGroupID: affectedGroupMLSGroupID,
                mlsStatus: .ready,
                conversationType: .group,
                epoch: 0,
                with: [selfUser, otherUser],
                in: context
            )
            modelHelper.createMLSConversation(
                id: UUID(),
                domain: "banana.com",
                mlsGroupID: otherDomainMLSGroupID,
                mlsStatus: .ready,
                conversationType: .group,
                epoch: 0,
                with: [selfUser, otherUser],
                in: context
            )
            modelHelper.createMLSConversation(
                id: UUID(),
                domain: affectedDomain,
                mlsGroupID: affectedOneOnOneMLSGroupID,
                mlsStatus: .ready,
                conversationType: .oneOnOne,
                epoch: 0,
                with: [selfUser, otherUser],
                in: context
            )
            modelHelper.createMLSConversation(
                id: UUID(),
                domain: affectedDomain,
                mlsGroupID: nonAffectedGroupMLSGroupID,
                mlsStatus: .pendingJoin,
                conversationType: .group,
                epoch: 0,
                with: [selfUser, otherUser],
                in: context
            )
        }

        initiateResetUseCase.invokeGroupIDEpoch_MockMethod = { _, _ in }
    }

    // MARK: - Tests

    @Test("It resets groups with faulty keys")
    func itResetsGroupsWithFaultyKeys() async throws {
        // Given
        // MLS group and 1-1 have faulty keys
        mlsService.externalSenderKeyGroupID_MockMethod = { groupID in
            switch groupID {
            case affectedGroupMLSGroupID, affectedOneOnOneMLSGroupID:
                faultyKey
            default:
                validKey
            }
        }

        // When
        try await sut.invoke()

        // Then
        // The reset is initated for those conversations.
        let invocations = initiateResetUseCase.invokeGroupIDEpoch_Invocations
        #expect(Set(invocations.map(\.groupID)) == [affectedGroupMLSGroupID, affectedOneOnOneMLSGroupID])
        #expect(Set(invocations.map(\.epoch)) == [5, 5])
    }

    @Test("It does not reset groups with valid keys")
    func itDoesNotResetGroupsWithValidKeys() async throws {
        // Given
        // All groups have valid keys
        mlsService.externalSenderKeyGroupID_MockMethod = { _ in
            validKey
        }

        // When
        try await sut.invoke()

        // Then
        // No group reset has been initiated
        let invocations = initiateResetUseCase.invokeGroupIDEpoch_Invocations
        #expect(invocations.isEmpty)
    }

    @Test("It does not reset groups that are not MLS ready")
    func itDoesNotResetGroupsThatAreNotMLSReady() async throws {
        // Given
        // MLS group that is not ready
        mlsService.externalSenderKeyGroupID_MockMethod = { groupID in
            switch groupID {
            case nonAffectedGroupMLSGroupID:
                faultyKey
            default:
                validKey
            }
        }

        // When
        try await sut.invoke()

        // Then
        // No group reset has been initiated
        let invocations = initiateResetUseCase.invokeGroupIDEpoch_Invocations
        #expect(invocations.isEmpty)
    }

    @Test("It does not reset groups from other domains")
    func itDoesNotResetGroupsFromOtherDomains() async throws {
        // Given
        // MLS group from another domain
        mlsService.externalSenderKeyGroupID_MockMethod = { groupID in
            switch groupID {
            case otherDomainMLSGroupID:
                faultyKey
            default:
                validKey
            }
        }

        // When
        try await sut.invoke()

        // Then
        // No group reset has been initiated
        let invocations = initiateResetUseCase.invokeGroupIDEpoch_Invocations
        #expect(invocations.isEmpty)
    }

}

// MARK: - Mock ConversationsAPI

// TODO: [WPB-22478] Remove this mock when we generate it in WireNetwork
final class MockConversationsAPIProtocol: ConversationsAPI {

    func getLegacyConversationIdentifiers() throws -> WireNetwork.PayloadPager<[UUID]> {
        fatalError("not implemented")
    }

    func getConversationIdentifiers() throws -> WireNetwork.PayloadPager<[WireNetwork.QualifiedID]> {
        fatalError("not implemented")
    }

    func getConversations(
        for identifiers: [WireNetwork.QualifiedID]
    ) async throws -> WireNetwork.ConversationList {
        let conversation = WireNetwork.Conversation(epoch: 5)
        return .init(found: [conversation], notFound: [], failed: [])
    }

    func getMLSOneToOneConversation(
        userID: String,
        in domain: String
    ) async throws -> (
        WireNetwork.Conversation,
        WireNetwork.MLSPublicKeys?
    ) {
        fatalError("not implemented")
    }

    func getConversationGuestLink(
        conversationID: String
    ) async throws -> String? {
        fatalError("not implemented")
    }

    func createGroupConversation(
        parameters: WireNetwork.CreateGroupConversationParameters
    ) async throws -> WireNetwork.Conversation {
        fatalError("not implemented")
    }

    func addChannelPermission(
        conversationID: String,
        conversationDomain: String,
        permission: WireNetwork.ChannelPermission
    ) async throws -> WireNetwork.ChannelPermission {
        fatalError("not implemented")
    }

    func updateConversationAccess(
        conversationID: WireFoundation.QualifiedID,
        allowGuests: Bool,
        allowApps: Bool
    ) async throws {
        fatalError("not implemented")
    }

}
