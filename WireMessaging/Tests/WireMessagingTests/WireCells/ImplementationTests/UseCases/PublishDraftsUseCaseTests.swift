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
import WireMessagingDomain

@testable import WireMessagingData
@testable import WireMessagingDomainSupport

final class PublishDraftsUseCaseTests {

    private let nodesAPI = MockNodesAPIProtocol()
    private lazy var uploadManager = WireCellsNodeUploadManager(nodesAPI: nodesAPI)
    private lazy var draftsRepository = DraftsRepository(
        uploadManager: uploadManager,
        nodesAPI: nodesAPI,
        drafts: [
            "cell-1": [
                UUID(): WireCellsDraft.fixture(status: .cancelled),
                UUID(): WireCellsDraft.fixture(status: .uploaded(isDraft: true))
            ],
            "cell-2": [
                UUID(): WireCellsDraft.fixture(status: .failed(error: .fileNotFound)),
                UUID(): WireCellsDraft.fixture(status: .uploaded(isDraft: true))
            ],
            "cell-3": [
                UUID(): WireCellsDraft.fixture(status: .uploading(progress: 0.5)),
                UUID(): WireCellsDraft.fixture(status: .uploaded(isDraft: true))
            ],
            "cell-4": [
                UUID(): WireCellsDraft.fixture(status: .uploaded(isDraft: false)),
                UUID(): WireCellsDraft.fixture(status: .uploaded(isDraft: true))
            ],
            "cell-5": [:] // Empty cell
        ]
    )
    private lazy var sut = PublishDraftsUseCase(cellName: "cell-name", draftRepository: draftsRepository)

    @Test(arguments: ["cell-1", "cell-2", "cell-3"])
    func invoke_whenNotAllFilesUploaded(cellName: String) async {
        // Given
        let sut = PublishDraftsUseCase(cellName: cellName, draftRepository: draftsRepository)

        // When, Then
        await #expect(throws: (any Error).self) {
            try await sut.invoke()
        }
    }

    @Test
    func invoke_whenNoFilesInCell() async {
        // Given
        let sut = PublishDraftsUseCase(cellName: "cell-5", draftRepository: draftsRepository)

        // When, Then
        await #expect(throws: Never.self) {
            try await sut.invoke()
        }
    }

    @Test
    func invoke_whenNonExistentCell() async throws {
        // Given
        let sut = PublishDraftsUseCase(cellName: "non-existent-cell", draftRepository: draftsRepository)

        // When, Then
        await #expect(throws: Never.self) {
            try await sut.invoke()
        }
    }

    @Test
    func invoke_whenPublishingFails() async {
        // Given
        let sut = PublishDraftsUseCase(cellName: "cell-4", draftRepository: draftsRepository)
        nodesAPI.publishDraftNodeIDVersionID_MockError = URLError(.notConnectedToInternet)

        // When, Then
        await #expect(throws: DraftsRepositoryError.notAllFilesArePublished) {
            try await sut.invoke()
        }
    }

    @Test
    func invoke_whenPublishingSucceeds() async throws {
        // Given
        let sut = PublishDraftsUseCase(cellName: "cell-4", draftRepository: draftsRepository)
        nodesAPI.publishDraftNodeIDVersionID_MockMethod = { _, _ in }

        // When
        try await sut.invoke()

        // Then
        let drafts = try await #require(draftsRepository.getDraftsForTesting["cell-4"]).values
        #expect(drafts.count == 2)
        #expect(drafts.allSatisfy { $0.status == .uploaded(isDraft: false) })
        #expect(nodesAPI.publishDraftNodeIDVersionID_Invocations.count == 1)
    }

    @Test
    func invoke_whenNewDraftAddedConcurrently() async throws {
        // Given
        let sut = PublishDraftsUseCase(cellName: "cell-4", draftRepository: draftsRepository)
        nodesAPI.publishDraftNodeIDVersionID_MockMethod = { [draftsRepository] _, _ in
            // Add a new draft while invoke is running
            var drafts = await draftsRepository.getDraftsForTesting
            drafts["cell-4"]?[UUID()] = WireCellsDraft.fixture(status: .uploading(progress: 0.5))
            await draftsRepository.setDraftsForTesting(drafts)
        }

        // When, Then
        await #expect(throws: DraftsRepositoryError.notAllFilesArePublished) {
            try await sut.invoke()
        }
    }
}
