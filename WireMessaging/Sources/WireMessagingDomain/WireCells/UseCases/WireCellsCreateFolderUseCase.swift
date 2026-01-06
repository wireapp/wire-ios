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

package enum WireCellsCreateFolderUseCaseError: Error {
    case serverFailedToCreateFolder
    case folderAlreadyExists
}

/// Creates a folder on the server.
package struct WireCellsCreateFolderUseCase: WireCellsCreateFolderUseCaseProtocol {

    private let nodesRepository: any WireCellsNodesRepositoryProtocol

    package init(
        nodesRepository: any WireCellsNodesRepositoryProtocol
    ) {
        self.nodesRepository = nodesRepository
    }

    package func invoke(
        folderPath: String,
        folderName: String
    ) async throws {
        let targetPath = folderPath + "/" + folderName

        // Checks whether the path doesn't already exist.
        let preCheckResult = try await nodesRepository.preCheck(
            nodePath: targetPath,
            findAvailablePath: false
        )

        guard preCheckResult == .success else {
            throw WireCellsCreateFolderUseCaseError.folderAlreadyExists
        }

        // Creates folder on the server.
        do {
            try await nodesRepository.createFolder(at: targetPath)
        } catch {
            throw WireCellsCreateFolderUseCaseError.serverFailedToCreateFolder
        }
    }

}
