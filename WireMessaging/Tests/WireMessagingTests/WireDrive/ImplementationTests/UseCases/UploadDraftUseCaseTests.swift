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
import UniformTypeIdentifiers

@testable import WireMessagingData
@testable import WireMessagingDomain
@testable import WireMessagingDomainSupport

final class UploadDraftUseCaseTests {

    private let intermediaryFilesDirectory: URL
    private let fileURL: URL
    private let draftsRepository = MockDraftsRepositoryProtocol()
    private let uploadManager = MockWireDriveNodeUploadManagerProtocol()
    private let nodesAPI = MockNodesAPIProtocol()
    private let metadataRepository = MockWireDriveDraftMetadataRepositoryProtocol()
    private lazy var sut = UploadDraftUseCase(
        cellName: "cell-name",
        draftRepository: draftsRepository,
        uploadManager: uploadManager,
        nodesAPI: nodesAPI,
        metadataRepository: metadataRepository,
        intermediaryFilesDirectory: intermediaryFilesDirectory,
        filenameGenerator: FilenameGenerator(date: { try! Date("2023-10-01T12:10:05Z", strategy: .iso8601) })
    )

    init() throws {
        self.intermediaryFilesDirectory = URL.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: intermediaryFilesDirectory, withIntermediateDirectories: true)
        self.fileURL = intermediaryFilesDirectory.appendingPathComponent("\(UUID().uuidString).txt")

        // Set mock defaults
        draftsRepository.fetchDraftNodeIDCellName_MockValue = WireDriveDraft.fixture()
        uploadManager.uploadNodeIDVersionIDAssetPathAssetSizeDestNodePath_MockValue =
            (.fixture(), AsyncStream.make([]))
        nodesAPI.getNodeNodeID_MockValue = .fixture()
        draftsRepository.addDraftFor_MockMethod = { _, _ in }
        draftsRepository.updateDraftFor_MockMethod = { _, _ in }
    }

    deinit {
        try? FileManager.default.removeItem(at: intermediaryFilesDirectory)
    }

    // MARK: - invoke(nodeID:)

    @Test
    func invokeWithNodeID_whenUnknownDraft() async {
        // Given
        let nodeID = UUID()
        draftsRepository.fetchDraftNodeIDCellName_MockValue = .some(nil)

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

        draftsRepository.fetchDraftNodeIDCellName_MockValue = WireDriveDraft.fixture(
            nodeID: nodeID,
            status: .uploading(progress: 0.5),
            name: "original.txt"
        )

        uploadManager
            .uploadNodeIDVersionIDAssetPathAssetSizeDestNodePath_MockValue
            = (
                WireDriveNode(uuid: nodeID, path: "something/new.txt"),
                AsyncStream.make(
                    [
                        .uploading(progress: 0.5),
                        .uploading(progress: 1.0),
                        .uploaded(isDraft: true)
                    ]
                )
            )

        nodesAPI.getNodeNodeID_MockValue = WireDriveNode(
            uuid: nodeID,
            path: "something/new.txt",
            mimeType: "some-mime-type"
        )

        draftsRepository.updateDraftFor_MockMethod = { _, _ in }

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        let updatesParams = draftsRepository.updateDraftFor_Invocations
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

        draftsRepository.fetchDraftNodeIDCellName_MockValue = WireDriveDraft.fixture(
            nodeID: nodeID,
            status: .uploading(progress: 0.5),
        )

        uploadManager
            .uploadNodeIDVersionIDAssetPathAssetSizeDestNodePath_MockError =
            URLError(.notConnectedToInternet)
        draftsRepository.updateDraftFor_MockMethod = { _, _ in }

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then
        let updatesParams = draftsRepository.updateDraftFor_Invocations
        #expect(updatesParams.count == 2)
        #expect(
            updatesParams.map(\.draft) == [
                .fixture(nodeID: nodeID, status: .uploading(progress: 0.0)),
                .fixture(nodeID: nodeID, status: .failed(error: .urlError(error: URLError(.notConnectedToInternet))))
            ]
        )
        #expect(updatesParams.map(\.cellName).allSatisfy { $0 == "cell-name" })
    }

    @Test
    func invokeWithNodeID_whenUploadCancelled() async throws {
        // Given
        let nodeID = UUID()

        draftsRepository.fetchDraftNodeIDCellName_MockValue = WireCellsDraft.fixture(
            nodeID: nodeID,
            status: .uploading(progress: 0.5)
        )

        uploadManager
            .uploadNodeIDVersionIDAssetPathAssetSizeDestNodePath_MockValue
            = (
                WireCellsNode(uuid: nodeID, path: "foo.txt"),
                AsyncStream.make(
                    [
                        .uploading(progress: 0.5),
                        .cancelled
                    ]
                )
            )

        draftsRepository.updateDraftFor_MockMethod = { _, _ in }

        // When
        try await sut.invoke(nodeID: nodeID)

        // Then if has the correct draft statuses
        let statuses = draftsRepository.updateDraftFor_Invocations.map(\.draft.status)
        #expect(
            statuses == [
                .uploading(progress: 0.0),
                .uploading(progress: 0.0),
                .uploading(progress: 0.5),
                .cancelled
            ]
        )

        // Then it doesn't try to fetch latest node info after uploading
        #expect(nodesAPI.getNodeNodeID_Invocations.isEmpty)
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

        // When
        try await sut.invoke(fileURL: fileURL)

        // Then
        let arguments = try #require(draftsRepository.addDraftFor_Invocations.first)
        #expect(arguments.cellName == "cell-name")
        #expect(arguments.draft.assetURL == fileURL)
        #expect(arguments.draft.fileType == UTType.plainText)
        #expect(arguments.draft.status == .uploading(progress: 0))
        #expect(arguments.draft.name == fileURL.lastPathComponent)
        #expect(arguments.draft.bytes == data.count)
        #expect(arguments.draft.mimeType == nil)
        #expect(arguments.draft.requiresCleanup == false)
    }

    @Test(arguments: [(fileName: String, expectedMetadata: WireDriveDraft.Metadata?)]([
        (fileName: "animated.gif", expectedMetadata: .image(width: 5, height: 5)),
        (fileName: "video.mp4", expectedMetadata: .video(width: 10, height: 10, duration: 10)),
        (fileName: "audio.m4a", expectedMetadata: .audio(duration: 15)),
        (fileName: "text.md", expectedMetadata: nil)
    ]))
    func invokeWithFileURL_addsCorrectDraftMetadata(
        fileName: String,
        expectedMetadata: WireDriveDraft.Metadata?
    ) async throws {
        // Given
        let fileURL = try #require(Bundle.module.url(forResource: fileName, withExtension: nil))
        metadataRepository.imageMetadataFileURL_MockValue = .image(width: 5, height: 5)
        metadataRepository.audioMetadataFileURL_MockValue = .audio(duration: 15)
        metadataRepository.videoMetadataFileURL_MockValue = .video(width: 10, height: 10, duration: 10)

        // When
        try await sut.invoke(fileURL: fileURL)

        // Then
        let arguments = try #require(draftsRepository.addDraftFor_Invocations.first)
        #expect(arguments.draft.metadata == expectedMetadata)
    }

    @Test
    func invokeWithFileURL_doesNotFailIfGeneratingMetadataFails() async throws {
        // Given
        let fileURL = try #require(Bundle.module.url(forResource: "animated", withExtension: "gif"))
        metadataRepository.imageMetadataFileURL_MockError = NSError(domain: "something", code: 10)

        // When
        try await sut.invoke(fileURL: fileURL)

        // Then
        #expect(draftsRepository.addDraftFor_Invocations.count == 1)
    }

    // MARK: - UploadDraftUseCase.invoke(data:type:)

    @Test(arguments: [
        (type: UTType.plainText, expectedFileName: "FILE_20231001_121005.txt"),
        (type: UTType.data, expectedFileName: "FILE_20231001_121005")
    ])
    func invokeWithData_addsCorrectDraft(type: UTType, expectedFileName: String) async throws {
        // Given
        let data = Data("This is a test file content.".utf8)

        // When
        try await sut.invoke(data: data, type: type)

        // Then
        let arguments = try #require(draftsRepository.addDraftFor_Invocations.first)
        #expect(arguments.cellName == "cell-name")
        #expect(arguments.draft.assetURL.lastPathComponent == expectedFileName)
        #expect(arguments.draft.fileType == type)
        #expect(arguments.draft.status == .uploading(progress: 0))
        #expect(arguments.draft.name == expectedFileName)
        #expect(arguments.draft.bytes == data.count)
        #expect(arguments.draft.mimeType == nil)
        #expect(arguments.draft.requiresCleanup == true)
    }

    @Test
    func invokeWithData_writesDataToDisk() async throws {
        // Given
        let data = Data("This is a test file content.".utf8)

        // When
        try await sut.invoke(data: data, type: .plainText)

        // Then
        let arguments = try #require(draftsRepository.addDraftFor_Invocations.first)
        let writtenData = try Data(contentsOf: arguments.draft.assetURL)
        #expect(writtenData == data)
    }

}
