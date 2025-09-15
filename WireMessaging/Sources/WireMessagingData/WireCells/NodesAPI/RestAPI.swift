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
import WireMessagingDomain

enum WireCellsNodesAPIError: Error {
    case failedToDecodeNode
    case missingData(String)
}

final class RestAPI: Sendable {

    private enum Constants {
        static let sortedBy = "mtime"

    }

    private let serverURL: URL
    private let accessTokenProvider: any AccessTokenProvider

    init(serverURL: URL, accessToken: any AccessTokenProvider) {
        self.serverURL = serverURL
        self.accessTokenProvider = accessToken
    }

    func getNode(uuid: UUID) async throws -> WireCellsNodeNetworkModel {
        let response = try await NodeServiceAPI.getByUuid(uuid: uuid.uuidString, apiConfiguration: makeConfiguration())
        guard let dto = response.toDTO() else {
            throw WireCellsNodesAPIError.failedToDecodeNode
        }
        return dto
    }

    func getNodes(
        _ request: WireCellsGetNodesRequest
    ) async throws -> (nodes: [WireCellsNodeNetworkModel], nextOffset: Int?) {
        let request = RestLookupRequest(
            filters: RestLookupFilter(
                status: LookupFilterStatusFilter(
                    deleted: StatusFilterDeletedStatus(request.filter.deletionStatus),
                    isDraft: false
                ),
                text: request.filter.text.map { LookupFilterTextSearch(searchIn: .baseName, term: $0) },
                type: TreeNodeType(request.filter.type)
            ),
            flags: [.withPreSignedURLs],
            limit: "\(request.limit)",
            offset: "\(request.offset)",
            scope: RestLookupScope(
                recursive: request.scope.isRecursive,
                root: request.scope.root.map { RestNodeLocator($0) }
            ),
            sortDirDesc: true,
            sortField: Constants.sortedBy
        )

        let collection = try await NodeServiceAPI.lookup(body: request, apiConfiguration: makeConfiguration())
        let nodes = collection.nodes?.compactMap { $0.toDTO() } ?? []
        let nextOffset = collection.pagination?.nextOffset

        return (nodes: nodes, nextOffset: nextOffset)
    }

    /// Deletes nodes by their `UUID`s.
    ///
    /// - Parameters:
    ///  - nodeIDs: The `UUID`s of the nodes to delete.
    ///  - permanently: Whether to permanently delete the nodes or move them to the recycle bin.
    /// - Returns: Whether the deletion was successful.
    func deleteNodes(nodeIDs: [UUID], permanently: Bool) async throws -> Bool {
        let nodes = nodeIDs.map { RestNodeLocator(uuid: $0.uuidString) }
        let parameters = RestActionParameters(
            awaitStatus: .finished,
            awaitTimeout: "60s",
            deleteOptions: RestActionOptionsDelete(permanentDelete: permanently),
            nodes: nodes
        )
        let response = try await NodeServiceAPI.performAction(
            name: .delete,
            parameters: parameters,
            apiConfiguration: makeConfiguration()
        )
        guard
            let backgroundActions = response.backgroundActions,
            let backgroundAction = backgroundActions.first(where: { $0.name == "delete" }) else {
            return false
        }
        return backgroundAction.status == .finished
    }

    func publishDraft(uuid: UUID, versionID: UUID) async throws {
        let parameters = RestPromoteParameters(publish: true)
        _ = try await NodeServiceAPI.promoteVersion(
            uuid: uuid.uuidString,
            versionId: versionID.uuidString,
            parameters: parameters,
            apiConfiguration: makeConfiguration()
        )
    }

    func deleteVersion(uuid: UUID, versionID: UUID) async throws {
        _ = try await NodeServiceAPI.deleteVersion(
            uuid: uuid.uuidString,
            versionId: versionID.uuidString,
            apiConfiguration: makeConfiguration()
        )
    }

    func preCheck(path: String) async throws -> WireCellsPreCheckResultDTO {
        let request = RestCreateCheckRequest(
            findAvailablePath: true,
            inputs: [RestIncomingNode(
                locator: RestNodeLocator(path: path),
                type: .leaf
            )]
        )

        let response = try await NodeServiceAPI.createCheck(body: request, apiConfiguration: makeConfiguration())

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
        let response = try await NodeServiceAPI.getPublicLink(
            linkUuid: uuid.uuidString,
            apiConfiguration: makeConfiguration()
        )

        guard let urlString = response.linkUrl else {
            throw WireCellsNodesAPIError.missingData("Link URL not found")
        }
        guard let url = URL(string: urlString) else {
            throw WireCellsNodesAPIError.missingData("Link URL is invalid")
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

        let response = try await NodeServiceAPI.createPublicLink(
            uuid: uuid.uuidString,
            publicLinkRequest: request,
            apiConfiguration: makeConfiguration()
        )

        guard let idString = response.uuid else {
            throw WireCellsNodesAPIError.missingData("UUID is null")
        }
        guard let id = UUID(uuidString: idString) else {
            throw WireCellsNodesAPIError.missingData("UUID is invalid")
        }

        guard let urlString = response.linkUrl else {
            throw WireCellsNodesAPIError.missingData("Link URL not found")
        }
        guard let url = URL(string: urlString) else {
            throw WireCellsNodesAPIError.missingData("Link URL is invalid")
        }

        return WireCellsPublicLink(uuid: id, url: url)
    }

    func deletePublicLink(uuid: UUID) async throws {
        _ = try await NodeServiceAPI.deletePublicLink(linkUuid: uuid.uuidString, apiConfiguration: makeConfiguration())
    }

    private func makeConfiguration() async throws -> CellsSDKAPIConfiguration {
        let config = CellsSDKAPIConfiguration()
        config.basePath = serverURL.absoluteString
        config.customHeaders = ["Authorization": "Bearer \(try await accessTokenProvider.accessToken().token)"]

        return config
    }
}

// MARK: - Helpers

private extension StatusFilterDeletedStatus {

    init(_ value: WireCellsNodeDeletionStatus) {
        switch value {
        case .deleted:
            self = .only
        case .notDeleted:
            self = .not
        case .any:
            self = .any
        }
    }
}

private extension RestNodeLocator {

    init(_ value: WireCellsNodeLocator) {
        switch value {
        case let .path(path):
            self.init(path: path)
        case let .id(uuid):
            self.init(uuid: uuid.uuidString.lowercased())
        }
    }

}

private extension TreeNodeType {

    init(_ value: WireCellsNodeType) {
        switch value {
        case .leaf:
            self = .leaf
        case .collection:
            self = .collection
        case .any:
            self = .unknown
        }
    }
}
