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

final class WireDriveNodeUploadManagerTests {

    private let nodesAPI = MockNodesAPIProtocol()
    private lazy var sut = WireDriveNodeUploadManager(nodesAPI: nodesAPI)

    private let assetPath = URL(fileURLWithPath: "/tmp/\(UUID())/some-file.txt")

    init() {
        nodesAPI.preCheckNodePathFindAvailablePath_MockValue = .success
        nodesAPI.uploadFilePathNodeVersionID_MockValue = AsyncThrowingStream { $0.finish() }
    }

    // MARK: - upload

    @Test
    func upload_whenPathIsAvailable_usesRequestedPath() async throws {
        // Given
        let nodeID = UUID()
        let versionID = UUID()

        // When
        let (node, _) = try await sut.upload(
            nodeID: nodeID,
            versionID: versionID,
            assetPath: assetPath,
            assetSize: 100,
            destNodePath: "folder/file.txt"
        )

        // Then
        #expect(node.id == nodeID)
        #expect(node.path == "folder/file.txt")
        #expect(node.size == 100)
        #expect(node.isDraft == true)

        let preCheckArguments = try #require(nodesAPI.preCheckNodePathFindAvailablePath_Invocations.first)
        #expect(preCheckArguments.nodePath == "folder/file.txt")
        #expect(preCheckArguments.findAvailablePath == true)
    }

    @Test
    func upload_whenPathAlreadyExists_usesResolvedPath() async throws {
        // Given
        nodesAPI.preCheckNodePathFindAvailablePath_MockValue = .fileExists(nextPath: "folder/file (1).txt")

        // When
        let (node, _) = try await sut.upload(
            nodeID: UUID(),
            versionID: UUID(),
            assetPath: assetPath,
            assetSize: 100,
            destNodePath: "folder/file.txt"
        )

        // Then
        #expect(node.path == "folder/file (1).txt")
    }

    @Test
    func upload_whenPreCheckFails_propagatesError() async throws {
        // Given
        nodesAPI.preCheckNodePathFindAvailablePath_MockError = URLError(.notConnectedToInternet)

        // When, Then
        let sut = sut
        let assetPath = assetPath
        await #expect(throws: URLError.self) {
            try await sut.upload(
                nodeID: UUID(),
                versionID: UUID(),
                assetPath: assetPath,
                assetSize: 100,
                destNodePath: "folder/file.txt"
            )
        }

        #expect(nodesAPI.uploadFilePathNodeVersionID_Invocations.isEmpty)
    }

    @Test
    func upload_whenUploadSucceeds_streamsProgressThenUploaded() async throws {
        // Given
        nodesAPI.uploadFilePathNodeVersionID_MockValue = AsyncThrowingStream { continuation in
            continuation.yield(50)
            continuation.yield(100)
            continuation.finish()
        }

        // When
        let (node, stream) = try await sut.upload(
            nodeID: UUID(),
            versionID: UUID(),
            assetPath: assetPath,
            assetSize: 100,
            destNodePath: "folder/file.txt"
        )
        let statuses = try await stream.collect()

        // Then
        #expect(
            statuses == [
                .uploading(progress: 0.5),
                .uploading(progress: 1.0),
                .uploaded(isDraft: true)
            ]
        )
        #expect(await sut.isUploading(nodeID: node.id) == false)
        #expect(await sut.getUploadInfo(nodeID: node.id) == nil)
    }

    @Test
    func upload_whenUploadThrows_streamsFailedStatus() async throws {
        // Given
        nodesAPI.uploadFilePathNodeVersionID_MockValue = AsyncThrowingStream { continuation in
            continuation.finish(throwing: URLError(.notConnectedToInternet))
        }

        // When
        let (node, stream) = try await sut.upload(
            nodeID: UUID(),
            versionID: UUID(),
            assetPath: assetPath,
            assetSize: 100,
            destNodePath: "folder/file.txt"
        )
        let statuses = try await stream.collect()

        // Then
        #expect(statuses == [.failed(error: .urlError(error: URLError(.notConnectedToInternet)))])
        #expect(await sut.isUploading(nodeID: node.id) == false)
    }

    // MARK: - getUploadInfo / isUploading

    @Test
    func getUploadInfo_reflectsProgressAsUploadAdvances() async throws {
        // Given
        let (uploadStream, uploadContinuation) = AsyncThrowingStream<Int, any Error>.makeStream()
        nodesAPI.uploadFilePathNodeVersionID_MockValue = uploadStream

        let (node, stream) = try await sut.upload(
            nodeID: UUID(),
            versionID: UUID(),
            assetPath: assetPath,
            assetSize: 200,
            destNodePath: "folder/file.txt"
        )
        var iterator = stream.makeAsyncIterator()

        // Then: freshly started upload has zero progress
        #expect(await sut.isUploading(nodeID: node.id) == true)
        #expect(await sut.getUploadInfo(nodeID: node.id) == WireDriveNodeUploadInfo(progress: 0))

        // When: some progress is reported
        uploadContinuation.yield(100)
        let firstStatus = await iterator.next()

        // Then
        #expect(firstStatus == .uploading(progress: 0.5))
        #expect(await sut.getUploadInfo(nodeID: node.id) == WireDriveNodeUploadInfo(progress: 0.5))

        // When: upload completes
        uploadContinuation.finish()
        let finalStatus = await iterator.next()

        // Then
        #expect(finalStatus == .uploaded(isDraft: true))
        #expect(await sut.getUploadInfo(nodeID: node.id) == nil)
        #expect(await sut.isUploading(nodeID: node.id) == false)
    }

    @Test
    func getUploadInfo_returnsNilForUnknownNode() async {
        #expect(await sut.getUploadInfo(nodeID: UUID()) == nil)
    }

    @Test
    func isUploading_returnsFalseForUnknownNode() async {
        #expect(await sut.isUploading(nodeID: UUID()) == false)
    }

    // MARK: - observeUpload

    @Test
    func observeUpload_returnsNilWhenNoActiveUpload() async {
        #expect(await sut.observeUpload(nodeID: UUID()) == nil)
    }

    @Test
    func observeUpload_returnsStreamWhileUploading() async throws {
        // Given
        let (uploadStream, uploadContinuation) = AsyncThrowingStream<Int, any Error>.makeStream()
        nodesAPI.uploadFilePathNodeVersionID_MockValue = uploadStream

        let (node, _) = try await sut.upload(
            nodeID: UUID(),
            versionID: UUID(),
            assetPath: assetPath,
            assetSize: 100,
            destNodePath: "folder/file.txt"
        )

        // Then
        #expect(await sut.observeUpload(nodeID: node.id) != nil)

        uploadContinuation.finish()
    }

    // MARK: - cancelUpload

    @Test
    func cancelUpload_stopsUploadAndClearsUploadInfo() async throws {
        // Given
        let (uploadStream, uploadContinuation) = AsyncThrowingStream<Int, any Error>.makeStream()
        nodesAPI.uploadFilePathNodeVersionID_MockValue = uploadStream

        let (node, stream) = try await sut.upload(
            nodeID: UUID(),
            versionID: UUID(),
            assetPath: assetPath,
            assetSize: 100,
            destNodePath: "folder/file.txt"
        )
        #expect(await sut.isUploading(nodeID: node.id) == true)

        // When
        await sut.cancelUpload(nodeID: node.id)
        let statuses = try await stream.collect()

        // Then
        #expect(statuses == [.cancelled])
        #expect(await sut.isUploading(nodeID: node.id) == false)
        #expect(await sut.observeUpload(nodeID: node.id) == nil)
        #expect(await sut.getUploadInfo(nodeID: node.id) == nil)

        uploadContinuation.finish()
    }

    @Test
    func cancelUpload_whenNoActiveUpload_doesNothing() async {
        await sut.cancelUpload(nodeID: UUID())
    }

}
