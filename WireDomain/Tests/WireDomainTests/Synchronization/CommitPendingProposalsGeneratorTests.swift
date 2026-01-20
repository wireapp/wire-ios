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

import Testing
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
@testable import WireDomain

class CommitPendingProposalsGeneratorTests {

    var sut: CommitPendingProposalsGenerator!
    let repository: MockConversationRepositoryProtocol
    let modelHelper = ModelHelper()
    let coreDataStackHelper = CoreDataStackHelper()
    let coreDataStack: CoreDataStack
    var commitPendingProposalItemClosure: ((CommitPendingProposalItem) -> Void)?
    var mockMLSService: MockMLSServiceInterface!
    var isMLSGroupBroken: (MLSGroupID) -> Bool = { _ in false }

    init() async throws {
        self.repository = MockConversationRepositoryProtocol()
        repository.isSelfAnActiveMemberIn_MockValue = true

        self.mockMLSService = MockMLSServiceInterface()
        mockMLSService.conferenceSubconversationParentGroupID_MockMethod = { _ in nil }

        self.coreDataStack = try await coreDataStackHelper.createStack()

        self.sut = CommitPendingProposalsGenerator(
            repository: repository,
            mlsService: mockMLSService,
            context: coreDataStack.syncContext,
            isMLSGroupBroken: {
                self.isMLSGroupBroken($0)
            },
            onCommitPendingProposals: { item in
                self.commitPendingProposalItemClosure?(item)
            }
        )
    }

    @Test(
        "It generates an item when a conversation with commitPendingProposalDate set is found",
        arguments: [Date(), Date().addingTimeInterval(0.5)]
    )
    func startGeneratesItem(date: Date) async throws {
        // GIVEN
        let conversationID = QualifiedID.random()
        await createPendingMLSConversation(
            id: conversationID,
            proposalDate: date
        )

        var items = [CommitPendingProposalItem]()
        commitPendingProposalItemClosure = { item in
            items.append(item)
        }
        // WHEN
        await sut.start()

        // THEN
        #expect(items.count == 1)
        #expect(items.first?.conversationID == conversationID)

        // WHEN
        let newConversationID = QualifiedID.random()
        try await confirmation("generator delivers an update for a new conversation") { confirm in
            self.commitPendingProposalItemClosure = {  item in
                items.append(item)
                confirm()
            }

            await self.createPendingMLSConversation(
                id: newConversationID,
                proposalDate: date
            )

            try await Task.sleep(for: .seconds(0.5))
        }

        // THEN
        #expect(items.count == 2)
        #expect(items.last?.conversationID == newConversationID)
    }

    @Test("It does not generate an item on conversation insertion")
    func startDoesNotGenerateItem() async throws {
        // GIVEN
        var items = [CommitPendingProposalItem]()
        commitPendingProposalItemClosure = { item in
            items.append(item)
        }
        let conversationID = QualifiedID.random()
        _ = await coreDataStack.syncContext.perform { [modelHelper, context = coreDataStack.syncContext] in
            modelHelper.createMLSConversation(
                id: conversationID.uuid,
                domain: conversationID.domain,
                in: context
            )
        }

        // WHEN
        await sut.start()

        // THEN
        #expect(items.isEmpty)
    }

    @Test("It does not generate an item when mls group is broken")
    func startDoesNotGenerateItemWhenBrokenMLSGroup() async throws {
        // GIVEN
        var items = [CommitPendingProposalItem]()
        commitPendingProposalItemClosure = { item in
            items.append(item)
        }
        isMLSGroupBroken = { _ in

            true
        }

        let conversationID = QualifiedID.random()
        await createPendingMLSConversation(
            id: conversationID,
            proposalDate: Date()
        )

        // WHEN
        await sut.start()

        // THEN
        #expect(items.isEmpty)
    }

    private func createPendingMLSConversation(id: QualifiedID, proposalDate: Date) async {
        _ = await coreDataStack.syncContext.perform { [context = coreDataStack.syncContext, modelHelper] in
            let selfUser = ZMUser.selfUser(in: context)
            let conversation = modelHelper.createMLSConversation(
                id: id.uuid,
                domain: id.domain,
                mlsGroupID: .random(),
                with: [selfUser],
                in: context
            )
            conversation.commitPendingProposalDate = Date()
        }
    }
}
