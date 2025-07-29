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
import UniformTypeIdentifiers

@testable import WireMessagingData
@testable import WireMessagingDomain
@testable import WireMessagingDomainSupport

final class UploadDraftUseCaseTests {

    private let fileURL = URL.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
    private let draftsRepository = DraftsRepositoryProtocolMock()
    private let uploadManager = WireCellsNodeUploadManagerProtocolMock()
    private let nodesAPI = NodesAPIProtocolMock()
    private lazy var sut = UploadDraftUseCase(
        cellName: "cell-name",
        draftRepository: draftsRepository,
        uploadManager: uploadManager,
        nodesAPI: nodesAPI
    )

    deinit {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - invoke(nodeID:)

    @Test
    func invokeWithNodeID_whenUnknownDraft() async {
        // Given
        let nodeID = UUID()

        // When, Then
        let sut = sut
        await #expect(throws: UploadDraftUseCaseError.draftNotFound) {
            try await sut.invoke(nodeID: nodeID)
        }
    }

    @Test
    func invokeWithNodeID_whenUploadSucceeds() async throws {
        // Given
        let nodeID = UUID()

        draftsRepository.fetchDraftNodeIDUUIDCellNameStringWireCellsDraftReturnValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            status: .uploading(progress: 0.5),
            name: "original.txt"
        )

        uploadManager
            .uploadNodeIDUUIDVersionIDUUIDAssetPathURLAssetSizeUInt64DestNodePathString_NodeWireCellsNodeStreamAsyncStreamWireCellsUploadStatusReturnValue
            = (
                WireCellsNode(uuid: nodeID, path: "something/new.txt"),
                AsyncStream.make(
                    [
                        .uploading(progress: 0.5),
                        .uploading(progress: 1.0),
                        .uploaded(isDraft: true)
                    ]
                )
            )

        nodesAPI.getNodeNodeIDUUIDWireCellsNodeReturnValue = WireCellsNode(
            uuid: nodeID,
            path: "something/new.txt",
            mimeType: "some-mime-type"
        )

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        let updatesParams = draftsRepository.updateDraftDraftWireCellsDraftForCellNameStringVoidReceivedInvocations
        #expect(updatesParams.count == 6)
        #expect(
            updatesParams.map(\.draft) == [
                .fixture(nodeID: nodeID, status: .uploading(progress: 0.0), name: "original.txt", mimeType: nil),
                .fixture(nodeID: nodeID, status: .uploading(progress: 0.0), name: "new.txt", mimeType: nil),
                .fixture(nodeID: nodeID, status: .uploading(progress: 0.5), name: "new.txt", mimeType: nil),
                .fixture(nodeID: nodeID, status: .uploading(progress: 1.0), name: "new.txt", mimeType: nil),
                .fixture(nodeID: nodeID, status: .uploaded(isDraft: true), name: "new.txt", mimeType: nil),
                .fixture(nodeID: nodeID, status: .uploaded(isDraft: true), name: "new.txt", mimeType: "some-mime-type")
            ]
        )
        #expect(updatesParams.map(\.cellName).allSatisfy { $0 == "cell-name" })
    }

    @Test
    func invokeWithNodeID_whenUploadFails() async throws {
        // Given
        let nodeID = UUID()

        draftsRepository.fetchDraftNodeIDUUIDCellNameStringWireCellsDraftReturnValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            status: .uploading(progress: 0.5),
        )

        uploadManager
            .uploadNodeIDUUIDVersionIDUUIDAssetPathURLAssetSizeUInt64DestNodePathString_NodeWireCellsNodeStreamAsyncStreamWireCellsUploadStatusThrowableError =
            URLError(.notConnectedToInternet)

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        let updatesParams = draftsRepository.updateDraftDraftWireCellsDraftForCellNameStringVoidReceivedInvocations
        #expect(updatesParams.count == 2)
        #expect(
            updatesParams.map(\.draft) == [
                .fixture(nodeID: nodeID, status: .uploading(progress: 0.0)),
                .fixture(nodeID: nodeID, status: .failed(error: .urlError(error: URLError(.notConnectedToInternet))))
            ]
        )
        #expect(updatesParams.map(\.cellName).allSatisfy { $0 == "cell-name" })
    }

    // MARK: - invoke(fileURL:)

    @Test
    func invokeWithFileURL_whenFileMissing() async {
        // Given
        let url = URL.temporaryDirectory.appendingPathComponent("some-missing-file.txt")

        // When, Then
        let sut = sut
        await #expect(throws: (any Error).self) {
            try await sut.invoke(fileURL: url)
        }
    }

    @Test
    func invokeWithFileURL_addsCorrectDraft() async throws {
        // Given
        let fileContent = "This is a test file content."
        let data = Data(fileContent.utf8)
        try data.write(to: fileURL)

        // The following mocked values are not important.
        draftsRepository.fetchDraftNodeIDUUIDCellNameStringWireCellsDraftReturnValue = WireCellsDraft.fixture()
        uploadManager
            .uploadNodeIDUUIDVersionIDUUIDAssetPathURLAssetSizeUInt64DestNodePathString_NodeWireCellsNodeStreamAsyncStreamWireCellsUploadStatusReturnValue =
            (
                .fixture(),
                AsyncStream.make([])
            )
        nodesAPI.getNodeNodeIDUUIDWireCellsNodeReturnValue = .fixture()

        // When
        try await sut.invoke(fileURL: fileURL)

        // Then
        let arguments = try #require(draftsRepository.addDraftDraftWireCellsDraftForCellNameStringVoidReceivedArguments)
        #expect(arguments.cellName == "cell-name")
        #expect(arguments.draft.assetURL == fileURL)
        #expect(arguments.draft.fileType == UTType.plainText)
        #expect(arguments.draft.status == .uploading(progress: 0))
        #expect(arguments.draft.name == fileURL.lastPathComponent)
        #expect(arguments.draft.bytes == data.count)
        #expect(arguments.draft.mimeType == nil)
        #expect(arguments.draft.deleteAfterUpload == false)
    }

}
