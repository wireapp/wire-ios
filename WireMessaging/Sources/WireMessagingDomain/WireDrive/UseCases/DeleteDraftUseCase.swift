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

package import Foundation

package struct DeleteDraftUseCase: WireDriveDeleteDraftUseCaseProtocol {

    private let cellName: String
    private let draftRepository: any DraftsRepositoryProtocol
    private let uploadManager: any WireDriveNodeUploadManagerProtocol
    private let nodesAPI: any NodesAPIProtocol
    private let fileManager: FileManager

    package init(
        cellName: String,
        draftRepository: any DraftsRepositoryProtocol,
        uploadManager: any WireDriveNodeUploadManagerProtocol,
        nodesAPI: any NodesAPIProtocol,
        fileManager: FileManager = .default
    ) {
        self.cellName = cellName
        self.draftRepository = draftRepository
        self.uploadManager = uploadManager
        self.nodesAPI = nodesAPI
        self.fileManager = fileManager
    }

    package func invoke(nodeID: UUID) async throws {
        guard let draft = await draftRepository.fetchDraft(nodeID: nodeID, cellName: cellName) else { return }

        switch draft.status {
        case .uploading:
            await uploadManager.cancelUpload(nodeID: nodeID)
        case .uploaded:
            try await nodesAPI.deleteVersion(nodeID: nodeID, versionID: draft.versionID)
        case .failed, .cancelled:
            break // no op
        }
        await draftRepository.deleteDraft(nodeID: nodeID, cellName: cellName)

        if draft.requiresCleanup {
            try fileManager.removeItem(at: draft.assetURL)
        }
    }

}
