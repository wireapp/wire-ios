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

package import Foundation
package import UniformTypeIdentifiers
import WireLogging

enum UploadDraftUseCaseError: Error {

    /// The draft was not found in the draft repository.

    case draftNotFound

}

package struct UploadDraftUseCase: WireCellsUploadDraftUseCaseProtocol, WireCellsRetryUploadDraftUseCaseProtocol {

    private let cellName: String
    private let draftRepository: any DraftsRepositoryProtocol
    private let uploadManager: any WireCellsNodeUploadManagerProtocol
    private let nodesAPI: any NodesAPIProtocol
    private let metadataRepository: any WireCellsDraftMetadataRepositoryProtocol
    private let intermediaryFilesDirectory: URL
    private let fileManager: @Sendable () -> FileManager // Closure to allow for non-sendable

    package init(
        cellName: String,
        draftRepository: any DraftsRepositoryProtocol,
        uploadManager: any WireCellsNodeUploadManagerProtocol,
        nodesAPI: any NodesAPIProtocol,
        metadataRepository: any WireCellsDraftMetadataRepositoryProtocol,
        tempDirectory: URL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
        intermediaryFilesDirectory: URL = Self.intermediaryFilesDirectory(),
        fileManager: @escaping @Sendable () -> FileManager = { .default }
    ) {
        self.cellName = cellName
        self.draftRepository = draftRepository
        self.uploadManager = uploadManager
        self.nodesAPI = nodesAPI
        self.metadataRepository = metadataRepository
        self.intermediaryFilesDirectory = intermediaryFilesDirectory
        self.fileManager = fileManager
    }

    package func invoke(fileURL: URL) async throws {
        try await invoke(fileURL: fileURL, requiresCleanup: false)
    }

    /// Uploads a file using an existing draft's nodeID.
    ///
    /// - throws: `UploadDraftUseCaseError.draftNotFound` if the draft does not exist in the draft repository.

    package func invoke(nodeID: UUID) async throws {
        guard var draft = await draftRepository.fetchDraft(nodeID: nodeID, cellName: cellName) else {
            throw UploadDraftUseCaseError.draftNotFound
        }

        draft.status = .uploading(progress: 0)
        await draftRepository.updateDraft(draft, for: cellName)

        do {
            let (node, stream) = try await uploadManager.upload(
                nodeID: draft.nodeID,
                versionID: draft.versionID,
                assetPath: draft.assetURL,
                assetSize: UInt64(draft.bytes),
                destNodePath: "\(cellName)/\(draft.name)"
            )

            // Update draft name if changed
            if let updatedName = URL(string: node.path)?.lastPathComponent {
                draft.name = updatedName
                await draftRepository.updateDraft(draft, for: cellName)
            }

            for await status in stream {
                draft.status = status
                await draftRepository.updateDraft(draft, for: cellName)
            }

            // Set post upload values
            let latestNode = try await nodesAPI.getNode(nodeID: draft.nodeID)
            if let mimeTime = latestNode.mimeType {
                draft.mimeType = mimeTime
                await draftRepository.updateDraft(draft, for: cellName)
            }

        } catch {
            draft.status = .failed(error: WireCellsUploadError(error))
            await draftRepository.updateDraft(draft, for: cellName)
        }
    }

    package func invoke(data: Data, type: UTType) async throws {
        let fileName = randomString(length: 6)
        let container = intermediaryFilesDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

        var url = container.appendingPathComponent(fileName)
        if let fileExtension = type.preferredFilenameExtension {
            url.appendPathExtension(fileExtension)
        }

        let fileManager = fileManager()
        try fileManager.createDirectory(at: container, withIntermediateDirectories: true)

        try data.write(to: url)
        try await invoke(fileURL: url, requiresCleanup: true)
    }

    // MARK: - Private Methods

    private func invoke(fileURL: URL, requiresCleanup: Bool) async throws {
        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
        guard let fileSize = resourceValues.fileSize, fileSize > 0 else {
            throw WireCellsUploadDraftUseCaseError.missingFileSize
        }

        let draft = WireCellsDraft(
            nodeID: UUID(),
            versionID: UUID(),
            assetURL: fileURL,
            fileType: resourceValues.contentType,
            status: .uploading(progress: 0),
            name: fileURL.lastPathComponent,
            bytes: fileSize,
            mimeType: nil,
            requiresCleanup: requiresCleanup,
            metadata: try? await metadata(for: fileURL, fileType: resourceValues.contentType)
        )

        await draftRepository.addDraft(draft, for: cellName)
        try await invoke(nodeID: draft.nodeID)
    }

    private func metadata(for fileURL: URL, fileType: UTType?) async throws -> WireCellsDraft.Metadata? {
        guard let fileType else { return nil }

        if fileType.conforms(to: .image) {
            return try await metadataRepository.imageMetadata(fileURL: fileURL)
        } else if fileType.conforms(to: .audio) { // `audio` must come before `.audiovisualContent`
            return try await metadataRepository.audioMetadata(fileURL: fileURL)
        } else if fileType.conforms(to: .audiovisualContent) {
            return try await metadataRepository.videoMetadata(fileURL: fileURL)
        } else {
            return nil
        }
    }

    private func randomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }

    private static func intermediaryFilesDirectory() -> URL {
        URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

}
