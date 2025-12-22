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

import WireDataModel
import WireDataModelSupport
import WireNetworkSupport
import XCTest

@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class CreateGroupConversationUseCaseTests: XCTestCase {

    private var sut: CreateGroupConversationUseCase!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var conversationsAPI: MockConversationsAPI!
    private var mlsService: MockMLSServiceInterface!

    private var coreDataStackHelper: CoreDataStackHelper!
    private var stack: CoreDataStack!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    // MARK: - Life cycle

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        conversationsAPI = MockConversationsAPI()
        conversationLocalStore = MockConversationLocalStoreProtocol()
        mlsService = MockMLSServiceInterface()

        sut = CreateGroupConversationUseCase(
            api: conversationsAPI,
            store: conversationLocalStore,
            mlsService: mlsService,
            context: context,
            localDomain: "wire.com",
            isFederationEnabled: true,
            isMLSEnabled: true
        )
    }

    override func tearDown() async throws {
        conversationsAPI = nil
        conversationLocalStore = nil
        mlsService = nil
        sut = nil
        stack = nil
        modelHelper = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Proteus group conversation

    func testInvoke_It_Succeeds_Returning_Created_Proteus_Conversation() async throws {
        // Mock

        let (proteusConversation, participant1, participant2) = await context.perform { [self] in
            modelHelper.createSelfClient(in: context)
            let participant1 = modelHelper.createUser(in: context)
            let participant2 = modelHelper.createUser(in: context)
            let proteusConversation = modelHelper.createGroupConversation(
                with: [participant1, participant2],
                in: context
            )

            return (proteusConversation, participant1, participant2)
        }

        conversationsAPI
            .createGroupConversationParameters_MockValue =
            Scaffolding.conversation

        conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }

        conversationLocalStore.fetchConversationIdDomain_MockValue = proteusConversation
        mlsService.addMembersToConversationWithFor_MockMethod = { _, _ in }
        mlsService.createGroupForRemovalKeys_MockValue = .MLS_128_DHKEMP256_AES128GCM_SHA256_P256

        // When

        let conversation = try await sut.invoke(
            teamID: .mockID1,
            messageProtocol: .proteus,
            name: "test",
            users: [participant1, participant2],
            accessMode: [.invite, .code],
            accessRoles: [.teamMember],
            enableReceipts: true,
            cells: true,
            isMLSEnabled: true
        )

        // Then

        XCTAssertEqual(conversation, proteusConversation)
        XCTAssertEqual(
            conversationsAPI
                .createGroupConversationParameters_Invocations
                .count,
            1
        )
        XCTAssertEqual(
            conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.count,
            1
        )
        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(
            mlsService.addMembersToConversationWithFor_Invocations.count,
            0
        ) // does not call mls service methods since this is a Proteus protocol
        XCTAssertEqual(
            mlsService.createGroupForRemovalKeys_Invocations.count,
            0
        ) // does not call mls service methods since this is a Proteus protocol
    }

    func testInvoke_When_Proteus_Protocol_And_API_Failure_It_Retries_Once_With_Federating_Domains() async throws {
        // Mock

        let (proteusConversation, participant1, participant2, nonFederatedParticipant3) = await context
            .perform { [self] in
                modelHelper.createSelfClient(in: context)
                let participant1 = modelHelper.createUser(id: .mockID1, domain: "federated1", in: context)
                let participant2 = modelHelper.createUser(id: .mockID2, domain: "federated2", in: context)
                let nonFederatedParticipant3 = modelHelper.createUser(id: .mockID3, domain: "nonfederated", in: context)
                let proteusConversation = modelHelper.createMLSConversation(
                    mlsGroupID: .random(),
                    with: [participant1, participant2, nonFederatedParticipant3],
                    in: context
                )

                return (proteusConversation, participant1, participant2, nonFederatedParticipant3)
            }

        var apiRetryCount = 0

        conversationsAPI
            .createGroupConversationParameters_MockMethod = { parameters in
                defer { apiRetryCount += 1 }
                if apiRetryCount == 0 {
                    // First, we try to create conversation with all users
                    XCTAssertEqual(
                        Set(parameters.qualifiedUserIDs.map(\.id)),
                        Set([UUID.mockID1, .mockID2, .mockID3])
                    )

                    throw ConversationsAPIError.nonFederatingBackends(["nonfederated"])
                } else {
                    // On retry, we only try to create conversation with federated domains
                    XCTAssertEqual(
                        Set(parameters.qualifiedUserIDs.map(\.id)),
                        Set([UUID.mockID1, .mockID2])
                    )
                    return Scaffolding.conversation
                }
            }

        conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }

        conversationLocalStore.fetchConversationIdDomain_MockValue = proteusConversation

        // When

        let conversation = try await sut.invoke(
            teamID: .mockID1,
            messageProtocol: .proteus,
            name: "test",
            users: [participant1, participant2, nonFederatedParticipant3],
            accessMode: [.invite, .code],
            accessRoles: [.teamMember],
            enableReceipts: true,
            cells: true,
            isMLSEnabled: true
        )

        // Then

        XCTAssertEqual(conversation, proteusConversation)
        XCTAssertEqual(
            conversationsAPI
                .createGroupConversationParameters_Invocations
                .count,
            2
        ) // called twice, first try then retry excluding non federated domains
        XCTAssertEqual(
            conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.count,
            1
        )
        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
    }

    // MARK: - MLS group conversation (for API version < v8)

    func testInvoke_It_Succeeds_Returning_Created_MLS_Conversation() async throws {
        // Mock

        let (mlsConversation, participant1, participant2) = await context.perform { [self] in
            modelHelper.createSelfClient(in: context)
            let participant1 = modelHelper.createUser(in: context)
            let participant2 = modelHelper.createUser(in: context)
            let mlsConversation = modelHelper.createMLSConversation(
                mlsGroupID: .random(),
                with: [participant1, participant2],
                in: context
            )

            return (mlsConversation, participant1, participant2)
        }

        conversationsAPI
            .createGroupConversationParameters_MockValue =
            Scaffolding.conversation

        conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }

        conversationLocalStore.fetchConversationIdDomain_MockValue = mlsConversation
        mlsService.addMembersToConversationWithFor_MockMethod = { _, _ in }
        mlsService.createGroupForRemovalKeys_MockValue = .MLS_128_DHKEMP256_AES128GCM_SHA256_P256

        // When

        let conversation = try await sut.invoke(
            teamID: .mockID1,
            messageProtocol: .mls,
            name: "test",
            users: [participant1, participant2],
            accessMode: [.invite, .code],
            accessRoles: [.teamMember],
            enableReceipts: true,
            cells: true,
            isMLSEnabled: true
        )

        // Then

        XCTAssertEqual(conversation, mlsConversation)
        XCTAssertEqual(
            conversationsAPI
                .createGroupConversationParameters_Invocations
                .count,
            1
        )
        XCTAssertEqual(
            conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.count,
            1
        )
        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(mlsService.addMembersToConversationWithFor_Invocations.count, 1)
        XCTAssertEqual(mlsService.createGroupForRemovalKeys_Invocations.count, 1)
    }

    func testInvoke_When_MLS_Protocol_And_API_Failure_It_Retries_Once_With_Federating_Domains() async throws {
        // Mock

        let (mlsConversation, participant1, participant2, nonFederatedParticipant3) = await context.perform { [self] in
            modelHelper.createSelfClient(in: context)
            let participant1 = modelHelper.createUser(id: .mockID1, domain: "federated1", in: context)
            let participant2 = modelHelper.createUser(id: .mockID2, domain: "federated2", in: context)
            let nonFederatedParticipant3 = modelHelper.createUser(id: .mockID3, domain: "nonfederated", in: context)
            let mlsConversation = modelHelper.createMLSConversation(
                mlsGroupID: .random(),
                with: [participant1, participant2, nonFederatedParticipant3],
                in: context
            )

            return (mlsConversation, participant1, participant2, nonFederatedParticipant3)
        }

        var apiRetryCount = 0

        conversationsAPI
            .createGroupConversationParameters_MockMethod = { parameters in
                defer { apiRetryCount += 1 }
                if apiRetryCount == 0 {
                    // First, we try to create conversation with all users
                    XCTAssertEqual(
                        Set(parameters.qualifiedUserIDs.map(\.id)),
                        Set([UUID.mockID1, .mockID2, .mockID3])
                    )

                    throw ConversationsAPIError.nonFederatingBackends(["nonfederated"])
                } else {
                    // On retry, we only try to create conversation with federated domains
                    XCTAssertEqual(
                        Set(parameters.qualifiedUserIDs.map(\.id)),
                        Set([UUID.mockID1, .mockID2])
                    )
                    return Scaffolding.conversation
                }
            }

        conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }

        conversationLocalStore.fetchConversationIdDomain_MockValue = mlsConversation
        mlsService.addMembersToConversationWithFor_MockMethod = { _, _ in }
        mlsService.createGroupForRemovalKeys_MockValue = .MLS_128_DHKEMP256_AES128GCM_SHA256_P256

        // When

        let conversation = try await sut.invoke(
            teamID: .mockID1,
            messageProtocol: .mls,
            name: "test",
            users: [participant1, participant2, nonFederatedParticipant3],
            accessMode: [.invite, .code],
            accessRoles: [.teamMember],
            enableReceipts: true,
            cells: true,
            isMLSEnabled: true
        )

        // Then

        XCTAssertEqual(conversation, mlsConversation)
        XCTAssertEqual(
            conversationsAPI
                .createGroupConversationParameters_Invocations
                .count,
            2
        ) // called twice, first try then retry excluding non federated domains
        XCTAssertEqual(
            conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.count,
            1
        )
        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(mlsService.addMembersToConversationWithFor_Invocations.count, 1)
        XCTAssertEqual(mlsService.createGroupForRemovalKeys_Invocations.count, 1)
    }

    func testInvoke_MLS_Claimed_Key_Packages_Failure_It_Retries_Once_With_Failed_Users() async throws {
        // Mock

        let (mlsConversation, participant1, participant2) = await context.perform { [self] in
            modelHelper.createSelfClient(in: context)
            let participant1 = modelHelper.createUser(id: .mockID1, domain: "federated1", in: context)
            let participant2 = modelHelper.createUser(id: .mockID2, domain: "federated1", in: context)

            let mlsConversation = modelHelper.createMLSConversation(
                mlsGroupID: .random(),
                with: [participant1, participant2],
                in: context
            )

            return (mlsConversation, participant1, participant2)
        }

        var apiRetryCount = 0

        conversationsAPI
            .createGroupConversationParameters_MockValue =
            Scaffolding.conversation

        conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }

        conversationLocalStore.fetchConversationIdDomain_MockValue = mlsConversation
        mlsService.addMembersToConversationWithFor_MockMethod = { [self] users, _ in
            defer { apiRetryCount += 1 }
            let usersIds = Set(await context.perform { users.map(\.id) })
            let successfulUserID = await context.perform { participant2.remoteIdentifier }!
            let failedUserID = await context.perform { participant1.remoteIdentifier }!

            if apiRetryCount == 0 {
                // First, we try to add all MLS participants
                XCTAssertEqual(
                    Set(usersIds),
                    Set([UUID.mockID1, .mockID2])
                )

                throw MLSService.MLSAddMembersError.failedToClaimKeyPackages(users: [.init(
                    id: failedUserID,
                    domain: "federated1"
                )])
            } else {
                // On retry, we only try adding MLS participants that have claimed packages.
                XCTAssertEqual(
                    Set(usersIds),
                    Set([successfulUserID])
                )
                return
            }
        }
        mlsService.createGroupForRemovalKeys_MockValue = .MLS_128_DHKEMP256_AES128GCM_SHA256_P256

        // When

        let conversation = try await sut.invoke(
            teamID: .mockID1,
            messageProtocol: .mls,
            name: "test",
            users: [participant1, participant2],
            accessMode: [.invite, .code],
            accessRoles: [.teamMember],
            enableReceipts: true,
            cells: true,
            isMLSEnabled: true
        )

        // Then

        XCTAssertEqual(conversation, mlsConversation)
        XCTAssertEqual(
            conversationsAPI
                .createGroupConversationParameters_Invocations
                .count,
            1
        )
        XCTAssertEqual(
            conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.count,
            1
        )
        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(
            mlsService.addMembersToConversationWithFor_Invocations.count,
            2
        ) // called twice, first try to add all MLS participants, on retry try to add only failed MLS participant
        XCTAssertEqual(mlsService.createGroupForRemovalKeys_Invocations.count, 1)

        // A system message should be added for the user(s) that failed.
        try await context.perform {
            let systemMessage = try XCTUnwrap(
                conversation.allMessages.compactMap { $0 as? ZMSystemMessage }.first
            )

            XCTAssertEqual(systemMessage.systemMessageType, .failedToAddParticipants)
            XCTAssertEqual(systemMessage.users, [participant1])
        }
    }

    func testInvoke_MLS_Non_Federating_Domains_Failure_It_Retries_Once_With_Federated_Users() async throws {
        // Mock

        let (mlsConversation, participant1, participant2) = await context.perform { [self] in
            modelHelper.createSelfClient(in: context)
            let participant1 = modelHelper.createUser(id: .mockID1, domain: "federated1", in: context)
            let participant2 = modelHelper.createUser(id: .mockID2, domain: "nonfederated2", in: context)

            let mlsConversation = modelHelper.createMLSConversation(
                mlsGroupID: .random(),
                with: [participant1, participant2],
                in: context
            )

            return (mlsConversation, participant1, participant2)
        }

        var apiRetryCount = 0

        conversationsAPI
            .createGroupConversationParameters_MockValue =
            Scaffolding.conversation

        conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }

        conversationLocalStore.fetchConversationIdDomain_MockValue = mlsConversation
        mlsService.addMembersToConversationWithFor_MockMethod = { [self] users, _ in
            defer { apiRetryCount += 1 }
            let usersIds = Set(await context.perform { users.map(\.id) })

            if apiRetryCount == 0 {
                // First, we try to add all MLS participants
                XCTAssertEqual(
                    Set(usersIds),
                    Set([UUID.mockID1, .mockID2])
                )

                throw SendMLSMessageFailure.nonFederatingDomains(Set(["nonfederated2"]))
            } else {
                // On retry, we only try to add MLS participants which are on a federated domain
                XCTAssertEqual(
                    Set(usersIds),
                    Set([.mockID1])
                )
                return
            }
        }
        mlsService.createGroupForRemovalKeys_MockValue = .MLS_128_DHKEMP256_AES128GCM_SHA256_P256

        // When

        let conversation = try await sut.invoke(
            teamID: .mockID1,
            messageProtocol: .mls,
            name: "test",
            users: [participant1, participant2],
            accessMode: [.invite, .code],
            accessRoles: [.teamMember],
            enableReceipts: true,
            cells: true,
            isMLSEnabled: true
        )

        // Then

        XCTAssertEqual(conversation, mlsConversation)
        XCTAssertEqual(
            conversationsAPI
                .createGroupConversationParameters_Invocations
                .count,
            1
        )
        XCTAssertEqual(
            conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.count,
            1
        )
        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(
            mlsService.addMembersToConversationWithFor_Invocations.count,
            2
        ) // called twice, first try to add all MLS participants, on retry try to add only MLS participants which are on
        // a federated domain
        XCTAssertEqual(mlsService.createGroupForRemovalKeys_Invocations.count, 1)
    }

    func testInvoke_MLS_Unreachable_Domains_Failure_It_Retries_Once_With_Unreachable_Users() async throws {
        // Mock

        let (mlsConversation, participant1, participant2) = await context.perform { [self] in
            modelHelper.createSelfClient(in: context)
            let participant1 = modelHelper.createUser(id: .mockID1, domain: "federated1", in: context)
            let participant2 = modelHelper.createUser(id: .mockID2, domain: "federated2", in: context)

            let mlsConversation = modelHelper.createMLSConversation(
                mlsGroupID: .random(),
                with: [participant1, participant2],
                in: context
            )

            return (mlsConversation, participant1, participant2)
        }

        var apiRetryCount = 0

        conversationsAPI
            .createGroupConversationParameters_MockValue =
            Scaffolding.conversation

        conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_MockMethod = { _, _, _, _ in }

        conversationLocalStore.fetchConversationIdDomain_MockValue = mlsConversation
        mlsService.addMembersToConversationWithFor_MockMethod = { [self] users, _ in
            defer { apiRetryCount += 1 }
            let usersIds = Set(await context.perform { users.map(\.id) })

            if apiRetryCount == 0 {
                // First, we try to add all MLS participants
                XCTAssertEqual(
                    Set(usersIds),
                    Set([UUID.mockID1, .mockID2])
                )

                throw SendMLSMessageFailure.unreachableDomains(Set(["federated2"]))
            } else {
                // On retry, we try to add all MLS participants that are on a reachable domain
                XCTAssertEqual(
                    Set(usersIds),
                    Set([.mockID1])
                )
                return
            }
        }
        mlsService.createGroupForRemovalKeys_MockValue = .MLS_128_DHKEMP256_AES128GCM_SHA256_P256

        // When

        let conversation = try await sut.invoke(
            teamID: .mockID1,
            messageProtocol: .mls,
            name: "test",
            users: [participant1, participant2],
            accessMode: [.invite, .code],
            accessRoles: [.teamMember],
            enableReceipts: true,
            cells: true,
            isMLSEnabled: true
        )

        // Then

        XCTAssertEqual(conversation, mlsConversation)
        XCTAssertEqual(
            conversationsAPI
                .createGroupConversationParameters_Invocations
                .count,
            1
        )
        XCTAssertEqual(
            conversationLocalStore.storeConversationTimestampIsFederationEnabledIsMLSEnabled_Invocations.count,
            1
        )
        XCTAssertEqual(conversationLocalStore.fetchConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(
            mlsService.addMembersToConversationWithFor_Invocations.count,
            2
        ) // called twice, first try to add all MLS participants, on retry try to add only participants that are on a
        // reachable domain
        XCTAssertEqual(mlsService.createGroupForRemovalKeys_Invocations.count, 1)
    }

    func testInvoke_API_Failure_It_Throws_Non_Federating_Domains() async throws {
        // Mock

        let nonFederatedParticipant3 = await context.perform { [self] in
            modelHelper.createSelfClient(in: context)
            return modelHelper.createUser(id: .mockID3, domain: "nonfederated", in: context)
        }

        conversationsAPI
            .createGroupConversationParameters_MockError = ConversationsAPIError.nonFederatingBackends(["nonfederated"])

        // Then

        await XCTAssertThrowsErrorAsync(
            CreateGroupConversationUseCase.Failure
                .nonFederatingDomains(Set(["nonfederated"]))
        ) { [self] in
            // When
            try await sut.invoke(
                teamID: .mockID1,
                messageProtocol: .mls,
                name: "test",
                users: [nonFederatedParticipant3],
                accessMode: [.invite, .code],
                accessRoles: [.teamMember],
                enableReceipts: true,
                cells: true,
                isMLSEnabled: true
            )
        }
    }

    func testInvoke_API_Failure_It_Throws_Not_Connected_Error() async throws {
        // Mock

        let (participant1, participant2) = await context.perform { [self] in
            modelHelper.createSelfClient(in: context)
            let participant1 = modelHelper.createUser(id: .mockID1, domain: "federated1", in: context)
            let participant2 = modelHelper.createUser(id: .mockID2, domain: "federated2", in: context)

            return (participant1, participant2)
        }

        conversationsAPI
            .createGroupConversationParameters_MockError =
            ConversationsAPIError.notConnected

        // Then

        await XCTAssertThrowsErrorAsync(CreateGroupConversationUseCase.Failure.notConnected) { [self] in
            // When
            try await sut.invoke(
                teamID: .mockID1,
                messageProtocol: .mls,
                name: "test",
                users: [participant1, participant2],
                accessMode: [.invite, .code],
                accessRoles: [.teamMember],
                enableReceipts: true,
                cells: true,
                isMLSEnabled: true
            )
        }

    }

    func testInvoke_API_Failure_It_Throws_Missing_Legalhold_Consent() async throws {
        // Mock

        let (participant1, participant2) = await context.perform { [self] in
            modelHelper.createSelfClient(in: context)
            let participant1 = modelHelper.createUser(id: .mockID1, domain: "federated1", in: context)
            let participant2 = modelHelper.createUser(id: .mockID2, domain: "federated2", in: context)

            return (participant1, participant2)
        }

        conversationsAPI
            .createGroupConversationParameters_MockError =
            ConversationsAPIError.missingLegalHoldConsent

        // Then

        await XCTAssertThrowsErrorAsync(CreateGroupConversationUseCase.Failure.missingLegalholdConsent) { [self] in
            // When
            try await sut.invoke(
                teamID: .mockID1,
                messageProtocol: .mls,
                name: "test",
                users: [participant1, participant2],
                accessMode: [.invite, .code],
                accessRoles: [.teamMember],
                enableReceipts: true,
                cells: true,
                isMLSEnabled: true
            )
        }

    }

    func testInvoke_API_Failure_It_Throws_Failed_To_Create_Group() async throws {
        // Mock

        let (participant1, participant2) = await context.perform { [self] in
            modelHelper.createSelfClient(in: context)
            let participant1 = modelHelper.createUser(id: .mockID1, domain: "federated1", in: context)
            let participant2 = modelHelper.createUser(id: .mockID2, domain: "federated2", in: context)

            return (participant1, participant2)
        }

        conversationsAPI
            .createGroupConversationParameters_MockError =
            ConversationsAPIError.nonEmptyMemberList

        struct MockError: Error {}

        // Then

        await XCTAssertThrowsErrorAsync(
            CreateGroupConversationUseCase.Failure
                .failedToCreateGroup(MockError())
        ) { [self] in
            // When
            _ = try await sut.invoke(
                teamID: .mockID1,
                messageProtocol: .mls,
                name: "test",
                users: [participant1, participant2],
                accessMode: [.invite, .code],
                accessRoles: [.teamMember],
                enableReceipts: true,
                cells: true,
                isMLSEnabled: true
            )
        }

    }

    private enum Scaffolding {
        static let conversationID = UUID.mockID1
        static let conversation = WireNetwork.Conversation(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!,
            qualifiedID: .init(id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!, domain: "example.com"),
            teamID: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!,
            type: .group,
            messageProtocol: .proteus,
            mlsGroupID: "",
            cipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
            epoch: 0,
            epochTimestamp: nil,
            creator: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ad")!,
            members: nil,
            name: nil,
            messageTimer: 0,
            readReceiptMode: 0,
            access: [.invite],
            accessRoles: [.teamMember],
            legacyAccessRole: .team,
            lastEvent: "",
            lastEventTime: nil
        )
    }
}

extension CreateGroupConversationUseCase.Failure: @retroactive Equatable {
    public static func == (
        lhs: WireDomain.CreateGroupConversationUseCase.Failure,
        rhs: WireDomain.CreateGroupConversationUseCase.Failure
    ) -> Bool {
        switch (lhs, rhs) {
        case (.notConnected, .notConnected):
            true
        case (.failedToCreateGroup, .failedToCreateGroup):
            true
        case (.conversationNotFound, .conversationNotFound):
            true
        case (.invalidOperation, .invalidOperation):
            true
        case (.missingConversationID, .missingConversationID):
            true
        case (.missingLegalholdConsent, .missingLegalholdConsent):
            true
        case (.missingSelfClientID, .missingSelfClientID):
            true
        case (.nonFederatingDomains, .nonFederatingDomains):
            true
        default:
            false
        }
    }

}
