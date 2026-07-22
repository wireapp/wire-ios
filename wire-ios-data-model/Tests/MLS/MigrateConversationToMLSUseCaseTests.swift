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

import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport

final class MigrateConversationToMLSUseCaseTests: ZMBaseManagedObjectTest {

    private enum TestFailure: Error, Equatable {
        case groupEstablishment
    }

    private var sut: MigrateConversationToMLSUseCase!
    private var actionsProvider: MockMLSActionsProviderProtocol!
    private var mlsService: MockMLSServiceInterface!

    override func setUp() {
        super.setUp()

        actionsProvider = MockMLSActionsProviderProtocol()
        mlsService = MockMLSServiceInterface()
        mlsService.underlyingLocalDomain = "example.com"
        mlsService.conversationExistsGroupID_MockValue = true
        mlsService.joinGroupWith_MockMethod = { _ in }
        mlsService.establishGroupForWithRemovalKeys_MockValue = .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519

        actionsProvider.updateConversationProtocolQualifiedIDMessageProtocolContext_MockMethod = { _, _, _ in }
        actionsProvider.syncConversationQualifiedIDContext_MockMethod = { _, _ in }

        syncMOC.performAndWait {
            syncMOC.mlsService = mlsService
        }

        sut = MigrateConversationToMLSUseCase(actionsProvider: actionsProvider)
    }

    override func tearDown() {
        sut = nil
        actionsProvider = nil
        mlsService = nil
        super.tearDown()
    }

    func testInvoke_MLSConversation_DoesNothing() async throws {
        let conversationID = await createConversation(messageProtocol: .mls)

        try await sut.invoke(conversationID: conversationID, syncContext: syncMOC)

        XCTAssertTrue(actionsProvider.updateConversationProtocolQualifiedIDMessageProtocolContext_Invocations.isEmpty)
        XCTAssertTrue(actionsProvider.syncConversationQualifiedIDContext_Invocations.isEmpty)
        XCTAssertTrue(mlsService.establishGroupForWithRemovalKeys_Invocations.isEmpty)
        XCTAssertTrue(mlsService.conversationExistsGroupID_Invocations.isEmpty)
    }

    func testInvoke_MixedConversation_FinalisesToMLS() async throws {
        let groupID = MLSGroupID.random()
        let conversationID = await createConversation(messageProtocol: .mixed, groupID: groupID)

        try await sut.invoke(conversationID: conversationID, syncContext: syncMOC)

        XCTAssertEqual(mlsService.conversationExistsGroupID_Invocations, [groupID])
        XCTAssertTrue(mlsService.joinGroupWith_Invocations.isEmpty)
        XCTAssertEqual(updatedProtocols, [.mls])
        XCTAssertEqual(actionsProvider.syncConversationQualifiedIDContext_Invocations.count, 1)
    }

    func testInvoke_MixedConversation_JoinsMissingGroupBeforeFinalising() async throws {
        let groupID = MLSGroupID.random()
        let conversationID = await createConversation(messageProtocol: .mixed, groupID: groupID)
        mlsService.conversationExistsGroupID_MockValue = false

        try await sut.invoke(conversationID: conversationID, syncContext: syncMOC)

        XCTAssertEqual(mlsService.joinGroupWith_Invocations, [groupID])
        XCTAssertEqual(updatedProtocols, [.mls])
    }

    func testInvoke_ProteusConversation_MigratesAndFinalisesToMLS() async throws {
        let groupID = MLSGroupID.random()
        let conversationID = await createConversation(messageProtocol: .proteus, groupID: groupID)

        try await sut.invoke(conversationID: conversationID, syncContext: syncMOC)

        XCTAssertEqual(updatedProtocols, [.mixed, .mls])
        XCTAssertEqual(actionsProvider.syncConversationQualifiedIDContext_Invocations.count, 2)
        XCTAssertEqual(mlsService.establishGroupForWithRemovalKeys_Invocations.count, 1)
        XCTAssertEqual(mlsService.establishGroupForWithRemovalKeys_Invocations.first?.groupID, groupID)
        XCTAssertEqual(mlsService.conversationExistsGroupID_Invocations, [groupID])
    }

    func testInvoke_ProteusConversation_WhenMigrationFails_DoesNotFinalise() async throws {
        let conversationID = await createConversation(messageProtocol: .proteus)
        mlsService.establishGroupForWithRemovalKeys_MockError = TestFailure.groupEstablishment

        await XCTAssertThrowsErrorAsync(
            TestFailure.groupEstablishment,
            when: {
                try await self.sut.invoke(
                    conversationID: conversationID,
                    syncContext: self.syncMOC
                )
            }
        )

        XCTAssertEqual(updatedProtocols, [.mixed])
        XCTAssertEqual(actionsProvider.syncConversationQualifiedIDContext_Invocations.count, 1)
        XCTAssertTrue(mlsService.conversationExistsGroupID_Invocations.isEmpty)
    }

    func testInvoke_OneOnOneConversation_ThrowsUnsupportedConversation() async throws {
        let conversationID = await createConversation(messageProtocol: .proteus, conversationType: .oneOnOne)

        await XCTAssertThrowsErrorAsync(
            MigrateConversationToMLSUseCase.Failure.unsupportedConversation,
            when: {
                try await self.sut.invoke(
                    conversationID: conversationID,
                    syncContext: self.syncMOC
                )
            }
        )
    }

    func testInvoke_MissingConversation_ThrowsConversationNotFound() async throws {
        await XCTAssertThrowsErrorAsync(
            MigrateConversationToMLSUseCase.Failure.conversationNotFound,
            when: {
                try await self.sut.invoke(
                    conversationID: .init(uuid: .create(), domain: "example.com"),
                    syncContext: self.syncMOC
                )
            }
        )
    }

    private var updatedProtocols: [MessageProtocol] {
        actionsProvider.updateConversationProtocolQualifiedIDMessageProtocolContext_Invocations.map(\.messageProtocol)
    }

    private func createConversation(
        messageProtocol: MessageProtocol,
        conversationType: ZMConversationType = .group,
        groupID: MLSGroupID = .random()
    ) async -> QualifiedID {
        await syncMOC.perform {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.teamIdentifier = .create()
            selfUser.domain = "example.com"

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = .create()
            conversation.domain = "example.com"
            conversation.teamRemoteIdentifier = selfUser.teamIdentifier
            conversation.conversationType = conversationType
            conversation.messageProtocol = messageProtocol
            conversation.mlsGroupID = groupID

            return conversation.qualifiedID!
        }
    }

}
