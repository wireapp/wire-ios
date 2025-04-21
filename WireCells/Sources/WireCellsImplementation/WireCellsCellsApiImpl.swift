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

import CellsSDK
import Foundation
import WireCellsAPI

final class WireCellsCellsApiImpl: WireCellsCellsAPI, Sendable {

    private enum Constants {
        static let sortedBy = "mtime"

    }

    func getNode(uuid: UUID) async throws -> WireCellsCellNodeDTO {
        let response = try await NodeServiceAPI.getByUuid(uuid: uuid.uuidString)
        guard let dto = response.toDto() else {
            throw WireCellsCellsAPIError.failedToDecodeNode
        }
        return dto
    }

    func getFiles(query: String, limit: Int, offset: Int) async throws -> WireCellsGetFilesResponseDTO {
        let request = RestLookupRequest(
            flags: [.withPreSignedURLs],
            limit: "\(limit)",
            offset: "\(offset)",
            query: TreeQuery(fileName: query, type: .leaf),
            sortField: Constants.sortedBy
        )

        return try await NodeServiceAPI.lookup(body: request).toDto()
    }

    func getFilesForPath(path: String, limit: Int, offset: Int) async throws -> WireCellsGetFilesResponseDTO {
        let request = RestLookupRequest(
            flags: [.withPreSignedURLs],
            limit: "\(limit)",
            locators: RestNodeLocators(many: [
                RestNodeLocator(path: "\(path)/*")
            ]),
            offset: "\(offset)",
            sortField: Constants.sortedBy
        )

        return try await NodeServiceAPI.lookup(body: request).toDto()
    }

    func delete(uuid: UUID) async throws {
        let parameters = RestActionParameters(nodes: [RestNodeLocator(uuid: uuid.uuidString)])
        _ = try await NodeServiceAPI.performAction(name: .delete, parameters: parameters)
    }

    func delete(paths: [String]) async throws {
        let nodes = paths.map { RestNodeLocator(path: $0) }
        let parameters = RestActionParameters(nodes: nodes)
        _ = try await NodeServiceAPI.performAction(name: .delete, parameters: parameters)
    }

    func publishDraft(uuid: UUID, versionID: UUID) async throws {
        let parameters = RestPromoteParameters(publish: true)
        _ = try await NodeServiceAPI.promoteVersion(
            uuid: uuid.uuidString,
            versionId: versionID.uuidString,
            parameters: parameters
        )
    }

    func cancelDraft(uuid: UUID, versionID: UUID) async throws {
        _ = try await NodeServiceAPI.deleteVersion(uuid: uuid.uuidString, versionId: versionID.uuidString)
    }

    func preCheck(path: String) async throws -> WireCellsPreCheckResultDTO {
        let request = RestCreateCheckRequest(
            findAvailablePath: true,
            inputs: [RestIncomingNode(
                locator: RestNodeLocator(path: path),
                type: .leaf
            )]
        )

        let response = try await NodeServiceAPI.createCheck(body: request)

        if let result = response.results?.first {
            return WireCellsPreCheckResultDTO(
                fileExists: result.exists ?? false,
                nextPath: result.nextPath
            )
        } else {
            return WireCellsPreCheckResultDTO()
        }
    }

    func getPublicLink(uuid: UUID) async throws -> URL {
        let response = try await NodeServiceAPI.getPublicLink(linkUuid: uuid.uuidString)

        guard let urlString = response.linkUrl else {
            throw WireCellsCellsAPIError.missingData("Link URL not found")
        }
        guard let url = URL(string: urlString) else {
            throw WireCellsCellsAPIError.missingData("Link URL is invalid")
        }

        return url
    }

    func createPublicLink(uuid: UUID, fileName: String) async throws -> WireCellsPublicLink {
        let request = RestPublicLinkRequest(
            link: RestShareLink(
                label: fileName,
                permissions: [.preview, .download]
            )
        )

        let response = try await NodeServiceAPI.createPublicLink(uuid: uuid.uuidString, publicLinkRequest: request)

        guard let idString = response.uuid else {
            throw WireCellsCellsAPIError.missingData("UUID is null")
        }
        guard let id = UUID(uuidString: idString) else {
            throw WireCellsCellsAPIError.missingData("UUID is invalid")
        }

        guard let urlString = response.linkUrl else {
            throw WireCellsCellsAPIError.missingData("Link URL not found")
        }
        guard let url = URL(string: urlString) else {
            throw WireCellsCellsAPIError.missingData("Link URL is invalid")
        }

        return WireCellsPublicLink(uuid: id, url: url)
    }

    func deletePublicLink(uuid: UUID) async throws {
        _ = try await NodeServiceAPI.deletePublicLink(linkUuid: uuid.uuidString)
    }
}
