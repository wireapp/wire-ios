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
import WireData
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
@testable import WireDomain

@Suite("CommitPendingProposalsGenerator Tests", .timeLimit(.minutes(1)))
class CommitPendingProposalsGeneratorTests {

    var sut: CommitPendingProposalsGenerator!
    let repository: MockConversationRepositoryProtocol
    let modelHelper = ModelHelper()
    let coreDataStackHelper = CoreDataStackHelper()
    let coreDataStack: CoreDataStack
    var commitPendingProposalItemClosure: ((CommitPendingProposalItem) -> Void)?
    var mockMLSService: MockMLSServiceInterface
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

    deinit {
        sut = nil
        commitPendingProposalItemClosure = nil
    }

    @Test(
        "It generates an item when a conversation with commitPendingProposalDate set is found",
        arguments: [Date(), Date().addingTimeInterval(0.5), Date().addingTimeInterval(1)]
    )
    func startGeneratesItem(date: Date) async throws {
        // GIVEN
        let conversationID = QualifiedID.random()
        await createPendingMLSConversation(
            id: conversationID,
            proposalDate: date
        )

        let (stream, streamContinuation) = AsyncStream.makeStream(of: CommitPendingProposalItem.self)
        commitPendingProposalItemClosure = { item in
            streamContinuation.yield(item)
        }
        var iterator = stream.makeAsyncIterator()

        // WHEN
        await sut.start()

        // THEN — properly await the async delivery rather than checking immediately
        let firstItem = await withTaskCancellationHandler {
            await iterator.next()
        } onCancel: {
            streamContinuation.finish()
        }
        #expect(firstItem?.conversationID == conversationID)

        // WHEN
        let newConversationID = QualifiedID.random()
        await createPendingMLSConversation(
            id: newConversationID,
            proposalDate: date
        )

        // THEN — await the second delivery (handles future-dated proposals naturally)
        let secondItem = await withTaskCancellationHandler {
            await iterator.next()
        } onCancel: {
            streamContinuation.finish()
        }
        #expect(secondItem?.conversationID == newConversationID)
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

    @Test("It does not generate another item when an unrelated property of the conversation is saved")
    func unrelatedConversationSaveDoesNotGenerateItem() async throws {
        // GIVEN
        let conversationID = QualifiedID.random()
        await createPendingMLSConversation(id: conversationID, proposalDate: Date().addingTimeInterval(-10))

        let (stream, streamContinuation) = AsyncStream.makeStream(of: CommitPendingProposalItem.self)
        commitPendingProposalItemClosure = { streamContinuation.yield($0) }
        var iterator = stream.makeAsyncIterator()

        await sut.start()
        let firstItem = await iterator.next()
        #expect(firstItem?.conversationID == conversationID)

        // WHEN — only an unrelated property changes
        let context = coreDataStack.syncContext
        await context.perform {
            let conversation = ZMConversation.fetch(with: conversationID.uuid, domain: conversationID.domain, in: context)
            conversation?.userDefinedName = "renamed"
            context.saveOrRollback()
        }
        try await Task.sleep(for: .milliseconds(300))
        streamContinuation.finish()

        // THEN
        let secondItem = await iterator.next()
        #expect(secondItem == nil)
    }

    @Test("It generates another item when the timer is rescheduled")
    func rescheduledTimerGeneratesItem() async throws {
        // GIVEN
        let conversationID = QualifiedID.random()
        let groupID = await createPendingMLSConversation(id: conversationID, proposalDate: Date().addingTimeInterval(-10))

        let (stream, streamContinuation) = AsyncStream.makeStream(of: CommitPendingProposalItem.self)
        commitPendingProposalItemClosure = { streamContinuation.yield($0) }
        var iterator = stream.makeAsyncIterator()

        await sut.start()
        _ = await iterator.next()

        // WHEN
        let context = coreDataStack.syncContext
        await context.perform {
            PendingProposalTimer.schedule(
                mlsGroupID: groupID.data,
                conversationID: conversationID.uuid,
                conversationDomain: conversationID.domain,
                fireDate: Date().addingTimeInterval(-1),
                in: context
            )
            context.saveOrRollback()
        }

        // THEN
        let secondItem = await withTaskCancellationHandler {
            await iterator.next()
        } onCancel: {
            streamContinuation.finish()
        }
        #expect(secondItem?.conversationID == conversationID)
    }

    @Test("It moves a date stored on the conversation to a timer on start")
    func migratesLegacyDate() async throws {
        // GIVEN
        let conversationID = QualifiedID.random()
        let context = coreDataStack.syncContext
        await context.perform { [modelHelper] in
            let conversation = modelHelper.createMLSConversation(
                id: conversationID.uuid,
                domain: conversationID.domain,
                mlsGroupID: .random(),
                with: [ZMUser.selfUser(in: context)],
                in: context
            )
            conversation.commitPendingProposalDate = Date().addingTimeInterval(-10)
        }

        let (stream, streamContinuation) = AsyncStream.makeStream(of: CommitPendingProposalItem.self)
        commitPendingProposalItemClosure = { streamContinuation.yield($0) }
        var iterator = stream.makeAsyncIterator()

        // WHEN
        await sut.start()

        // THEN
        let item = await iterator.next()
        #expect(item?.conversationID == conversationID)
    }

    @discardableResult
    private func createPendingMLSConversation(id: QualifiedID, proposalDate: Date) async -> MLSGroupID {
        await coreDataStack.syncContext.perform { [context = coreDataStack.syncContext, modelHelper] in
            let selfUser = ZMUser.selfUser(in: context)
            let groupID = MLSGroupID.random()
            _ = modelHelper.createMLSConversation(
                id: id.uuid,
                domain: id.domain,
                mlsGroupID: groupID,
                with: [selfUser],
                in: context
            )
            PendingProposalTimer.schedule(
                mlsGroupID: groupID.data,
                conversationID: id.uuid,
                conversationDomain: id.domain,
                fireDate: proposalDate,
                in: context
            )
            return groupID
        }
    }
}
