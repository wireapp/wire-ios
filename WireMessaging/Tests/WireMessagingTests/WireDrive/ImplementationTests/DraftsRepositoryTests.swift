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

@testable import WireMessagingData
@testable import WireMessagingDomain
@testable import WireMessagingDomainSupport

final class DraftsRepositoryTests {

    private let cellName = "cell-name"

    private let uploadManager = MockWireDriveNodeUploadManagerProtocol()
    private let nodesAPI = MockNodesAPIProtocol()
    private lazy var sut = DraftsRepository(uploadManager: uploadManager, nodesAPI: nodesAPI)

    // MARK: - addDraft / fetchDraft

    @Test
    func fetchDraft_whenNoDraftWasAdded_returnsNil() async {
        #expect(await sut.fetchDraft(nodeID: UUID(), cellName: cellName) == nil)
    }

    @Test
    func addDraft_thenFetchDraft_returnsSameDraft() async {
        // Given
        let draft = WireDriveDraft.fixture()

        // When
        await sut.addDraft(draft, for: cellName)

        // Then
        #expect(await sut.fetchDraft(nodeID: draft.nodeID, cellName: cellName) == draft)
    }

    @Test
    func fetchDraft_whenAddedUnderDifferentCellName_returnsNil() async {
        // Given
        let draft = WireDriveDraft.fixture()

        // When
        await sut.addDraft(draft, for: cellName)

        // Then
        #expect(await sut.fetchDraft(nodeID: draft.nodeID, cellName: "other-cell") == nil)
    }

    // MARK: - deleteDraft

    @Test
    func deleteDraft_removesPreviouslyAddedDraft() async {
        // Given
        let draft = WireDriveDraft.fixture()
        await sut.addDraft(draft, for: cellName)

        // When
        await sut.deleteDraft(nodeID: draft.nodeID, cellName: cellName)

        // Then
        #expect(await sut.fetchDraft(nodeID: draft.nodeID, cellName: cellName) == nil)
    }

    @Test
    func deleteDraft_whenDraftDoesNotExist_doesNothing() async {
        await sut.deleteDraft(nodeID: UUID(), cellName: cellName)
    }

    // MARK: - updateDraft

    @Test
    func updateDraft_whenDraftExists_updatesIt() async {
        // Given
        let draft = WireDriveDraft.fixture(status: .uploading(progress: 0.5))
        await sut.addDraft(draft, for: cellName)

        let updated = WireDriveDraft.fixture(nodeID: draft.nodeID, status: .uploaded(isDraft: true))

        // When
        await sut.updateDraft(updated, for: cellName)

        // Then
        #expect(await sut.fetchDraft(nodeID: draft.nodeID, cellName: cellName) == updated)
    }

    @Test
    func updateDraft_whenDraftDoesNotExist_doesNothing() async {
        // Given
        let unknown = WireDriveDraft.fixture()

        // When
        await sut.updateDraft(unknown, for: cellName)

        // Then
        #expect(await sut.fetchDraft(nodeID: unknown.nodeID, cellName: cellName) == nil)
    }

    // MARK: - drafts(for:)

    @Test
    func draftsForCellName_emitsCurrentStateThenUpdates() async {
        // Given
        let stream = await sut.drafts(for: cellName)
        var iterator = stream.makeAsyncIterator()

        // Then: subscribing yields the current (empty) state
        #expect(await iterator.next() == [])

        // When: a draft is added
        let draft = WireDriveDraft.fixture()
        await sut.addDraft(draft, for: cellName)

        // Then: the new state is emitted
        #expect(await iterator.next() == [draft])

        // When: the draft is removed
        await sut.deleteDraft(nodeID: draft.nodeID, cellName: cellName)

        // Then: the empty state is emitted again
        #expect(await iterator.next() == [])
    }

    // MARK: - publishAll

    @Test
    func publishAll_whenNoDraftsForCellName_returnsEmpty() async throws {
        #expect(try await sut.publishAll(for: cellName) == [])
    }

    @Test
    func publishAll_whenNotAllFilesAreUploaded_throwsAndDoesNotPublish() async throws {
        // Given
        let draft = WireDriveDraft.fixture(status: .uploading(progress: 0.5))
        await sut.addDraft(draft, for: cellName)

        // When, Then
        let sut = sut
        let cellName = cellName
        await #expect(throws: DraftsRepositoryError.notAllFilesAreUploaded) {
            try await sut.publishAll(for: cellName)
        }
        #expect(nodesAPI.publishDraftNodeIDVersionID_Invocations.isEmpty)
    }

    @Test
    func publishAll_publishesOnlyDraftsPendingPublication() async throws {
        // Given
        let alreadyPublished = WireDriveDraft.fixture(status: .uploaded(isDraft: false))
        let pendingPublish = WireDriveDraft.fixture(status: .uploaded(isDraft: true))
        await sut.addDraft(alreadyPublished, for: cellName)
        await sut.addDraft(pendingPublish, for: cellName)

        nodesAPI.publishDraftNodeIDVersionID_MockMethod = { _, _ in }

        // When
        let result = try await sut.publishAll(for: cellName)

        // Then
        #expect(nodesAPI.publishDraftNodeIDVersionID_Invocations.map(\.nodeID) == [pendingPublish.nodeID])

        // The returned drafts reflect the state before publishing, not after.
        #expect(result == [alreadyPublished, pendingPublish])

        // ...but the repository's own state is updated correctly.
        #expect(
            await sut.fetchDraft(nodeID: pendingPublish.nodeID, cellName: cellName)?.status
                == .uploaded(isDraft: false)
        )
    }

    @Test
    func publishAll_whenPublishingFails_keepsSuccessfulPublicationsAndThrows() async throws {
        // Given
        let succeeding = WireDriveDraft.fixture(status: .uploaded(isDraft: true))
        let failing = WireDriveDraft.fixture(status: .uploaded(isDraft: true))
        await sut.addDraft(succeeding, for: cellName)
        await sut.addDraft(failing, for: cellName)

        nodesAPI.publishDraftNodeIDVersionID_MockMethod = { nodeID, _ in
            if nodeID == failing.nodeID {
                throw URLError(.notConnectedToInternet)
            }
        }

        // When, Then
        let sut = sut
        let cellName = cellName
        await #expect(throws: DraftsRepositoryError.notAllFilesArePublished) {
            try await sut.publishAll(for: cellName)
        }

        // Then: the successful publication was still persisted
        #expect(
            await sut.fetchDraft(nodeID: succeeding.nodeID, cellName: cellName)?.status
                == .uploaded(isDraft: false)
        )
        #expect(
            await sut.fetchDraft(nodeID: failing.nodeID, cellName: cellName)?.status
                == .uploaded(isDraft: true)
        )
    }

    // MARK: - clearPublishedDrafts

    @Test
    func clearPublishedDrafts_whenNoDraftsForCellName_returnsEmpty() async {
        #expect(await sut.clearPublishedDrafts(for: cellName) == [])
    }

    @Test
    func clearPublishedDrafts_removesOnlyPublishedDrafts() async {
        // Given
        let published = WireDriveDraft.fixture(status: .uploaded(isDraft: false))
        let draft = WireDriveDraft.fixture(status: .uploaded(isDraft: true))
        let uploading = WireDriveDraft.fixture(status: .uploading(progress: 0.5))
        await sut.addDraft(published, for: cellName)
        await sut.addDraft(draft, for: cellName)
        await sut.addDraft(uploading, for: cellName)

        // When
        let result = await sut.clearPublishedDrafts(for: cellName)

        // Then
        #expect(result == [published])
        #expect(await sut.fetchDraft(nodeID: published.nodeID, cellName: cellName) == nil)
        #expect(await sut.fetchDraft(nodeID: draft.nodeID, cellName: cellName) == draft)
        #expect(await sut.fetchDraft(nodeID: uploading.nodeID, cellName: cellName) == uploading)
    }

}
