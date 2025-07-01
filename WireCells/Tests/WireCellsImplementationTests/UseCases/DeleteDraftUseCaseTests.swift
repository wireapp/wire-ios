import Foundation
import Testing
import WireCellsAPI

@testable import WireCellsImplementation
@testable import WireCellsImplementationSupport

final class DeleteDraftUseCaseTests {

    private let draftsRepository = DraftsRepositoryProtocolMock()
    private let uploadManager = WireCellsNodeUploadManagerProtocolMock()
    private let nodesAPI = NodesAPIProtocolMock()
    private let fileURL: URL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    private lazy var sut: DeleteDraftUseCase = {
        DeleteDraftUseCase(
            cellName: "test-cell",
            draftRepository: draftsRepository,
            uploadManager: uploadManager,
            nodesAPI: nodesAPI
        )
    }()

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

        // When
        try await sut.invoke(nodeID: nonExistentNodeID)

        // Then
        #expect(uploadManager.cancelUploadNodeIDUUIDVoidCalled == false)
        #expect(nodesAPI.deleteVersionNodeIDUUIDVersionIDUUIDVoidCalled == false)
        #expect(draftsRepository.deleteDraftNodeIDUUIDCellNameStringVoidCalled == false)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test
    func invoke_whenUploading() async throws {
        // Given
        let nodeID = UUID()
        draftsRepository.fetchDraftNodeIDUUIDCellNameStringWireCellsDraftReturnValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            status: .uploading(progress: 0.5)
        )

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(uploadManager.cancelUploadNodeIDUUIDVoidReceivedInvocations == [nodeID])
        #expect(nodesAPI.deleteVersionNodeIDUUIDVersionIDUUIDVoidCalled == false)
    }

    @Test
    func invoke_whenUploaded() async throws {
        // Given
        let nodeID = UUID()
        let versionID = UUID()
        draftsRepository.fetchDraftNodeIDUUIDCellNameStringWireCellsDraftReturnValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            versionID: versionID,
            status: .uploaded(isDraft: true)
        )

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(uploadManager.cancelUploadNodeIDUUIDVoidCalled == false)
        #expect(nodesAPI.deleteVersionNodeIDUUIDVersionIDUUIDVoidReceivedInvocations == [(nodeID, versionID)])
    }

    @Test
    func invoke_whenCancelled() async throws {
        // Given
        let nodeID = UUID()
        draftsRepository.fetchDraftNodeIDUUIDCellNameStringWireCellsDraftReturnValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            status: .cancelled
        )

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(uploadManager.cancelUploadNodeIDUUIDVoidCalled == false)
        #expect(nodesAPI.deleteVersionNodeIDUUIDVersionIDUUIDVoidCalled == false)
    }

    @Test
    func invoke_whenFailed() async throws {
        // Given
        let nodeID = UUID()
        draftsRepository.fetchDraftNodeIDUUIDCellNameStringWireCellsDraftReturnValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            status: .failed(error: .fileNotFound)
        )

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(uploadManager.cancelUploadNodeIDUUIDVoidCalled == false)
        #expect(nodesAPI.deleteVersionNodeIDUUIDVersionIDUUIDVoidCalled == false)
    }

    @Test(arguments:
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
        draftsRepository.fetchDraftNodeIDUUIDCellNameStringWireCellsDraftReturnValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            status: status,
        )

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(draftsRepository.deleteDraftNodeIDUUIDCellNameStringVoidReceivedInvocations == [(nodeID, "test-cell")])
    }

    @Test(arguments:
        [
            WireCellsUploadStatus.uploading(progress: 0.5),
            WireCellsUploadStatus.uploaded(isDraft: true),
            WireCellsUploadStatus.cancelled,
            WireCellsUploadStatus.failed(error: .fileNotFound)
        ],
        [true, false]
    )
    func invoke_deletesFileIfNeeded(status: WireCellsUploadStatus, deleteAfterUpload: Bool) async throws {
        // Given
        let nodeID = UUID()
        draftsRepository.fetchDraftNodeIDUUIDCellNameStringWireCellsDraftReturnValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            assetURL: fileURL,
            status: status,
            deleteAfterUpload: deleteAfterUpload
        )

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(FileManager.default.fileExists(atPath: fileURL.path) != deleteAfterUpload)
    }
}

// MARK: - Helpers

/// Returns true if two arrays of tuples are equal.
private func ==<A: Equatable, B: Equatable>(lhs: [(A, B)], rhs: [(A, B)]) -> Bool {
    lhs.map {  $0.0 } == rhs.map { $0.0 } && rhs.map { $0.1 } == lhs.map { $0.1 }
}
