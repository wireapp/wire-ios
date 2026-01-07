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

final class DeleteDraftUseCaseTests {

    private let draftsRepository = MockDraftsRepositoryProtocol()
    private let uploadManager = MockWireCellsNodeUploadManagerProtocol()
    private let nodesAPI = MockNodesAPIProtocol()
    private let fileURL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    private lazy var sut = DeleteDraftUseCase(
        cellName: "test-cell",
        draftRepository: draftsRepository,
        uploadManager: uploadManager,
        nodesAPI: nodesAPI
    )

    init() throws {
        let data = Data(repeating: 0, count: 5)
        try data.write(to: fileURL)
    }

    deinit {
        try? FileManager.default.removeItem(at: fileURL)
    }

    @Test
    func invoke_whenNoDraft() async throws {
        // Given
        let nonExistentNodeID = UUID()
        draftsRepository.fetchDraftNodeIDCellName_MockMethod = { _, _ in nil }

        // When
        try await sut.invoke(nodeID: nonExistentNodeID)

        // Then
        #expect(uploadManager.cancelUploadNodeID_Invocations.isEmpty)
        #expect(nodesAPI.deleteVersionNodeIDVersionID_Invocations.isEmpty)
        #expect(draftsRepository.deleteDraftNodeIDCellName_Invocations.isEmpty)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test
    func invoke_whenUploading() async throws {
        // Given
        let nodeID = UUID()
        draftsRepository.fetchDraftNodeIDCellName_MockValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            status: .uploading(progress: 0.5)
        )
        uploadManager.cancelUploadNodeID_MockMethod = { _ in }
        draftsRepository.deleteDraftNodeIDCellName_MockMethod = { _, _ in }

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(uploadManager.cancelUploadNodeID_Invocations == [nodeID])
        #expect(nodesAPI.deleteVersionNodeIDVersionID_Invocations.isEmpty)
    }

    @Test
    func invoke_whenUploaded() async throws {
        // Given
        let nodeID = UUID()
        let versionID = UUID()
        draftsRepository.fetchDraftNodeIDCellName_MockValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            versionID: versionID,
            status: .uploaded(isDraft: true)
        )
        nodesAPI.deleteVersionNodeIDVersionID_MockMethod = { _, _ in }
        draftsRepository.deleteDraftNodeIDCellName_MockMethod = { _, _ in }

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(uploadManager.cancelUploadNodeID_Invocations.isEmpty)
        #expect(nodesAPI.deleteVersionNodeIDVersionID_Invocations == [(nodeID, versionID)])
    }

    @Test
    func invoke_whenCancelled() async throws {
        // Given
        let nodeID = UUID()
        draftsRepository.fetchDraftNodeIDCellName_MockValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            status: .cancelled
        )
        draftsRepository.deleteDraftNodeIDCellName_MockMethod = { _, _ in }
        nodesAPI.deleteVersionNodeIDVersionID_MockMethod = { _, _ in }

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(uploadManager.cancelUploadNodeID_Invocations.isEmpty)
        #expect(nodesAPI.deleteVersionNodeIDVersionID_Invocations.isEmpty)
    }

    @Test
    func invoke_whenFailed() async throws {
        // Given
        let nodeID = UUID()
        draftsRepository.fetchDraftNodeIDCellName_MockValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            status: .failed(error: .fileNotFound)
        )
        draftsRepository.deleteDraftNodeIDCellName_MockMethod = { _, _ in }

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(uploadManager.cancelUploadNodeID_Invocations.isEmpty)
        #expect(nodesAPI.deleteVersionNodeIDVersionID_Invocations.isEmpty)
    }

    @Test(
        arguments:
        [
            WireCellsUploadStatus.uploading(progress: 0.5),
            WireCellsUploadStatus.uploaded(isDraft: true),
            WireCellsUploadStatus.cancelled,
            WireCellsUploadStatus.failed(error: .fileNotFound)
        ]
    )
    func invoke_deletesDraftFromRepository(status: WireCellsUploadStatus) async throws {
        // Given
        let nodeID = UUID()
        draftsRepository.fetchDraftNodeIDCellName_MockValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            status: status,
        )
        draftsRepository.deleteDraftNodeIDCellName_MockMethod = { _, _ in }
        uploadManager.cancelUploadNodeID_MockMethod = { _ in }
        nodesAPI.deleteVersionNodeIDVersionID_MockMethod = { _, _ in }

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(draftsRepository.deleteDraftNodeIDCellName_Invocations == [(nodeID, "test-cell")])
    }

    @Test(
        arguments:
        [
            WireCellsUploadStatus.uploading(progress: 0.5),
            WireCellsUploadStatus.uploaded(isDraft: true),
            WireCellsUploadStatus.cancelled,
            WireCellsUploadStatus.failed(error: .fileNotFound)
        ],
        [true, false]
    )
    func invoke_deletesFileIfNeeded(status: WireCellsUploadStatus, requiresCleanup: Bool) async throws {
        // Given
        let nodeID = UUID()
        draftsRepository.fetchDraftNodeIDCellName_MockValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            assetURL: fileURL,
            status: status,
            requiresCleanup: requiresCleanup
        )
        draftsRepository.deleteDraftNodeIDCellName_MockMethod = { _, _ in }
        uploadManager.cancelUploadNodeID_MockMethod = { _ in }
        nodesAPI.deleteVersionNodeIDVersionID_MockMethod = { _, _ in }

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(FileManager.default.fileExists(atPath: fileURL.path) != requiresCleanup)
    }
}

// MARK: - Helpers

/// Returns true if two arrays of tuples are equal.
private func == <A: Equatable, B: Equatable>(lhs: [(A, B)], rhs: [(A, B)]) -> Bool {
    lhs.map(\.0) == rhs.map(\.0) && rhs.map(\.1) == lhs.map(\.1)
}
