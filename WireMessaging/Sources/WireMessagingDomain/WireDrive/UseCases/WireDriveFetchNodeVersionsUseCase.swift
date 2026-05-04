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
import WireLogging

package struct WireDriveFetchNodeVersionsUseCase: WireDriveFetchNodeVersionsUseCaseProtocol {

    enum Failure: Error {
        case unableToRetrieveNodeVersions
    }

    private let repository: any WireDriveNodesRepositoryProtocol

    package init(
        repository: any WireDriveNodesRepositoryProtocol
    ) {
        self.repository = repository
    }

    package func invoke(nodeID: UUID) async throws -> [WireDriveNodeVersion] {
        do {
            return try await repository.getVersions(nodeID: nodeID)
        } catch {
            WireLogger.wireDrive.error("Unable to retrieve node versions: \(error)")
            throw Failure.unableToRetrieveNodeVersions
        }
    }

}
