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

package enum CreationTarget: Equatable {
    case folder
    case file(WireDriveTemplate)
}

package enum WireDriveCreateUseCaseError: Error {
    case serverFailedToCreate
    case alreadyExists
    case invalidPath
}

/// Creates a file or a folder on the server.
package struct WireDriveCreateUseCase: WireDriveCreateUseCaseProtocol {

    private let nodesRepository: any WireDriveNodesRepositoryProtocol

    package init(
        nodesRepository: any WireDriveNodesRepositoryProtocol
    ) {
        self.nodesRepository = nodesRepository
    }

    package func invoke(
        creationTarget: CreationTarget,
        path: String,
        name: String
    ) async throws -> WireDriveNode {
        guard let url = URL(string: path) else {
            throw WireDriveCreateUseCaseError.invalidPath
        }

        let targetPath = switch creationTarget {
        case .folder:
            url.appendingPathComponent(name)
        case let .file(template):
            url.appendingPathComponent("\(name).\(URL(fileURLWithPath: template.UUID).pathExtension)")
        }

        let path = targetPath.absoluteString

        // Checks whether the path doesn't already exist.
        let preCheckResult = try await nodesRepository.preCheck(
            nodePath: path,
            findAvailablePath: false
        )

        guard preCheckResult == .success else {
            throw WireDriveCreateUseCaseError.alreadyExists
        }

        do {
            return switch creationTarget {
            case .folder:
                // Creates folder on the server.
                try await nodesRepository.createFolder(at: path)
            case let .file(template):
                // Creates a file from a template UUID on the server.
                try await nodesRepository.createFile(at: path, templateUuid: template.UUID)
            }

        } catch {
            throw WireDriveCreateUseCaseError.serverFailedToCreate
        }
    }

}
