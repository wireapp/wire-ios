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

import Collections
import Foundation
import Testing
import WireMessagingDomain

@testable import WireMessagingData
@testable import WireMessagingDomainSupport

final class ClearPublishedDraftsUseCaseTests {

    private let nodesAPI = MockNodesAPIProtocol()
    private let assetAURL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    private let assetBURL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    private lazy var uploadManager = WireCellsNodeUploadManager(nodesAPI: nodesAPI)
    private lazy var draftsRepository = DraftsRepository(
        uploadManager: uploadManager,
        nodesAPI: nodesAPI,
        drafts: [
            "cell-A": [
                Scaffolding.cancelledDraft.nodeID: Scaffolding.cancelledDraft,
                Scaffolding.uploadingDraft.nodeID: Scaffolding.uploadingDraft,
                Scaffolding.uploadedDraft.nodeID: Scaffolding.uploadedDraft,
                Scaffolding.publishedDraft.nodeID: Scaffolding.publishedDraft,
                Scaffolding.failedDraft.nodeID: Scaffolding.failedDraft
            ],
            "cell-B": [
                Scaffolding.publishedDraft.nodeID: Scaffolding.publishedDraft
            ]
        ]
    )

    deinit {
        try? FileManager.default.removeItem(at: assetAURL)
        try? FileManager.default.removeItem(at: assetBURL)
    }

    @Test
    func invoke_clearsTheCorrectDrafts() async throws {
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

    @Test
    func invoke_deletesFilesIfNeeded() async throws {
        // Given
        try Data("Test data A".utf8).write(to: assetAURL)
        try Data("Test data B".utf8).write(to: assetBURL)

        let draftA = WireCellsDraft.fixture(
            assetURL: assetAURL,
            status: .uploaded(isDraft: false),
            requiresCleanup: false
        )
        let draftB = WireCellsDraft.fixture(
            assetURL: assetBURL,
            status: .uploaded(isDraft: false),
            requiresCleanup: true
        )

        let sut = ClearPublishedDraftsUseCase(
            cellName: "cell",
            draftRepository: DraftsRepository(
                uploadManager: uploadManager,
                nodesAPI: nodesAPI,
                drafts: ["cell": [draftA.nodeID: draftA, draftB.nodeID: draftB]]
            )
        )

        // When
        await sut.invoke()

        // Then
        #expect(FileManager.default.fileExists(atPath: assetAURL.path))
        #expect(!FileManager.default.fileExists(atPath: assetBURL.path))
    }
}

private enum Scaffolding {
    static let cancelledDraft = WireCellsDraft.fixture(status: .cancelled)
    static let uploadingDraft = WireCellsDraft.fixture(status: .uploading(progress: 0.5))
    static let uploadedDraft = WireCellsDraft.fixture(status: .uploaded(isDraft: true))
    static let publishedDraft = WireCellsDraft.fixture(status: .uploaded(isDraft: false))
    static let failedDraft = WireCellsDraft.fixture(status: .failed(error: .fileNotFound))
}
