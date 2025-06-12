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

import Foundation
import Testing
import WireCellsAPI
import Collections

@testable import WireCellsImplementation
@testable import WireCellsImplementationSupport

final class ClearPublishedDraftsUseCaseTests {

    private let nodesAPI = NodesAPIProtocolMock()
    private lazy var uploadManager = WireCellsNodeUploadManager(nodesAPI: nodesAPI)
    private lazy var draftsRepository = DraftsRepository(
        uploadManager: uploadManager,
        nodesAPI: nodesAPI,
        drafts: [
            "cell-A": [
                Scaffolding.cancelledDraft.id: Scaffolding.cancelledDraft,
                Scaffolding.uploadingDraft.id: Scaffolding.uploadingDraft,
                Scaffolding.uploadedDraft.id: Scaffolding.uploadedDraft,
                Scaffolding.publishedDraft.id: Scaffolding.publishedDraft,
                Scaffolding.failedDraft.id: Scaffolding.failedDraft
            ],
            "cell-B": [
                Scaffolding.publishedDraft.id: Scaffolding.publishedDraft
            ]
        ]
    )

    @Test
    func invoke() async throws {
        // Given
        let sut = ClearPublishedDraftsUseCase(cellName: "cell-A", draftRepository: draftsRepository)

        // When
        await sut.invoke()

        // Then
        let cellADrafts = try await #require(draftsRepository.getDraftsForTesting["cell-A"]).values.elements
        #expect(
            Set(cellADrafts) == Set([
                Scaffolding.cancelledDraft,
                Scaffolding.uploadedDraft,
                Scaffolding.uploadingDraft,
                Scaffolding.failedDraft
            ])
        )

        let cellBDrafts = try await #require(draftsRepository.getDraftsForTesting["cell-B"]).values.elements
        #expect(
            Set(cellBDrafts) == Set([
                Scaffolding.publishedDraft
            ])
        )
    }
}

private enum Scaffolding {
    static let cancelledDraft = WireCellsDraft.fixture(status: .cancelled)
    static let uploadingDraft = WireCellsDraft.fixture(status: .uploading(progress: 0.5))
    static let uploadedDraft = WireCellsDraft.fixture(status: .uploaded(isDraft: true))
    static let publishedDraft = WireCellsDraft.fixture(status: .uploaded(isDraft: false))
    static let failedDraft = WireCellsDraft.fixture(status: .failed(error: .fileNotFound))
}
