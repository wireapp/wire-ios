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

import CellsSDK
import Foundation
import WireLogging
import WireMessagingDomain

enum WireCellsNodesAPIError: Error {
    case failedToDecodeNode
    case failedToDecodeNodeVersions
    case missingData(String)
    case invalidParameters(String)
}

final class RestAPI: Sendable {

    private enum Constants {
        static let deleteBackgroundActionName = "delete"
        static let restoreBackgroundActionName = "restore"
        static let renameBackgroundActionName = "move"
    }

    private let serverURL: URL
    private let accessTokenProvider: any AccessTokenProvider

    init(serverURL: URL, accessToken: any AccessTokenProvider) {
        self.serverURL = serverURL
        self.accessTokenProvider = accessToken
    }

    func getNode(uuid: UUID) async throws -> WireCellsNodeNetworkModel {
        let response = try await NodeServiceAPI.getByUuid(
            uuid: uuid.transportString(),
            apiConfiguration: makeConfiguration()
        )
        guard let dto = response.toDTO() else {
            throw WireCellsNodesAPIError.failedToDecodeNode
        }
        return dto
    }

    func getNodes(
        _ request: WireCellsGetNodesRequest
    ) async throws -> (nodes: [WireCellsNodeNetworkModel], nextOffset: Int?) {
        do {
            let collection = try await NodeServiceAPI.lookup(
                body: request.lookupRequest,
                apiConfiguration: makeConfiguration()
            )
            let nodes = collection.nodes?.compactMap { $0.toDTO() } ?? []
            let nextOffset = collection.pagination?.nextOffset

            return (nodes: nodes, nextOffset: nextOffset)
        } catch let sdkError as CellsSDK.ErrorResponse {
            switch sdkError {
            case let .error(_, _, _, error):
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    throw CancellationError()
                } else {
                    throw sdkError.underlyingError
                }
            }
        }
    }

    func getEditorURL(id: UUID) async throws -> (url: URL, date: Date)? {
        do {
            let response = try await NodeServiceAPI.getByUuid(
                uuid: id.transportString(),
                flags: [.withEditorURLs],
                apiConfiguration: makeConfiguration()
            )
            return response.editorURLs?["collabora"]?.info
        } catch let error as ErrorResponse {
            throw error.underlyingError
        }
    }

    /// Renames a node.
    ///
    /// - Parameters:
    ///  - nodeID: The `UUID`s of the node to rename.
    ///  - targetPath: The new path for the node.
    ///  - targetIsParent: Whether the `targetPath` is the parent folder of the node.
    /// - Returns: Whether the renaming was successful.

    func renameNode(nodeID: UUID, targetPath: String, targetIsParent: Bool) async throws -> Bool {
        let node = RestNodeLocator(uuid: nodeID.uuidString)

        let parameters = RestActionParameters(
            awaitStatus: .finished,
            awaitTimeout: "5s",
            copyMoveOptions: RestActionOptionsCopyMove(
                targetIsParent: targetIsParent,
                targetPath: targetPath
            ),
            nodes: [node],
        )

        do {
            let response = try await NodeServiceAPI.performAction(
                name: .move,
                parameters: parameters,
                apiConfiguration: makeConfiguration()
            )

            guard
                let actions = response.backgroundActions,
                let renameAction = actions.first(where: { $0.name == Constants.renameBackgroundActionName }) else {
                return false
            }
            return renameAction.status == .finished
        } catch let error as ErrorResponse {
            throw error.underlyingError
        }
    }

    /// Deletes nodes by their `UUID`s.
    ///
    /// - Parameters:
    ///  - nodeIDs: The `UUID`s of the nodes to delete.
    ///  - permanently: Whether to permanently delete the nodes or move them to the recycle bin.
    /// - Returns: Whether the deletion was successful.
    func deleteNodes(nodeIDs: [UUID], permanently: Bool) async throws -> Bool {
        let nodes = nodeIDs.map { RestNodeLocator(uuid: $0.transportString()) }
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
            let actions = response.backgroundActions,
            let deleteAction = actions.first(where: { $0.name == Constants.deleteBackgroundActionName }) else {
            return false
        }
        return deleteAction.status == .finished
    }

    /// Restores nodes from the recycle bin by their `UUID`s.
    func restoreNodes(nodeIDs: [UUID]) async throws -> Bool {
        let nodes = nodeIDs.map { RestNodeLocator(uuid: $0.transportString()) }
        let parameters = RestActionParameters(
            awaitStatus: .finished,
            awaitTimeout: "60s",
            nodes: nodes
        )
        let response = try await NodeServiceAPI.performAction(
            name: .restore,
            parameters: parameters,
            apiConfiguration: makeConfiguration()
        )
        guard
            let actions = response.backgroundActions,
            let restoreAction = actions.first(where: { $0.name == Constants.restoreBackgroundActionName }) else {
            return false
        }
        return restoreAction.status == .finished
    }

    func publishDraft(uuid: UUID, versionID: UUID) async throws {
        let parameters = RestPromoteParameters(publish: true)
        _ = try await NodeServiceAPI.promoteVersion(
            uuid: uuid.transportString(),
            versionId: versionID.transportString(),
            parameters: parameters,
            apiConfiguration: makeConfiguration()
        )
    }

    func deleteVersion(uuid: UUID, versionID: UUID) async throws {
        _ = try await NodeServiceAPI.deleteVersion(
            uuid: uuid.transportString(),
            versionId: versionID.transportString(),
            apiConfiguration: makeConfiguration()
        )
    }

    func getVersions(uuid: UUID) async throws -> WireCellsNodeVersionsNetworkModel {
        let query = RestNodeVersionsFilter(
            filterBy: .versionsAll,
            flags: [.withPreSignedURLs],
            limit: nil,
            offset: nil,
            sortDirDesc: true,
            sortField: nil
        )

        let response = try await NodeServiceAPI.nodeVersions(
            uuid: uuid.transportString(),
            query: query,
            apiConfiguration: makeConfiguration()
        )

        guard let dto = response.toDTO() else {
            throw WireCellsNodesAPIError.failedToDecodeNodeVersions
        }

        return dto
    }

    func restoreVersion(uuid: UUID, versionID: UUID) async throws {
        let parameters = RestPromoteParameters(publish: false)
        _ = try await NodeServiceAPI.promoteVersion(
            uuid: uuid.transportString(),
            versionId: versionID.transportString(),
            parameters: parameters,
            apiConfiguration: makeConfiguration()
        )
    }

    /// Creates a new folder at the specified path.
    ///
    /// - Parameters:
    ///  - path: The path of the new folder.
    func createFolder(at path: String) async throws {
        let request = RestCreateRequest(inputs: [
            RestIncomingNode(
                locator: RestNodeLocator(
                    path: path
                ),
                resourceUuid: UUID().transportString(),
                type: .collection,
            )
        ])

        _ = try await NodeServiceAPI.create(
            body: request,
            apiConfiguration: makeConfiguration()
        )
    }

    func preCheck(path: String, findAvailablePath: Bool = true) async throws -> WireCellsPreCheckResultDTO {
        let request = RestCreateCheckRequest(
            findAvailablePath: findAvailablePath,
            inputs: [RestIncomingNode(
                locator: RestNodeLocator(path: path),
                type: .unknown
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

    func getPublicLink(linkID: String) async throws -> WireCellsPublicLink {
        let response = try await NodeServiceAPI.getPublicLink(
            linkUuid: linkID,
            apiConfiguration: makeConfiguration()
        )

        return try WireCellsPublicLink(response, serverURL: serverURL)
    }

    func createPublicLink(uuid: UUID, label: String) async throws -> WireCellsPublicLink {
        let request = RestPublicLinkRequest(
            link: RestShareLink(label: label, permissions: [.preview, .download])
        )

        let response = try await NodeServiceAPI.createPublicLink(
            uuid: uuid.transportString(),
            publicLinkRequest: request,
            apiConfiguration: makeConfiguration()
        )

        return try WireCellsPublicLink(response, serverURL: serverURL)
    }

    func deletePublicLink(linkID: String) async throws {
        _ = try await NodeServiceAPI.deletePublicLink(
            linkUuid: linkID,
            apiConfiguration: makeConfiguration()
        )
    }

    func updatePublicLinkExpiration(linkID: String, expiration: Date?) async throws -> WireCellsPublicLink {
        var currentLink = try await NodeServiceAPI.getPublicLink(
            linkUuid: linkID,
            apiConfiguration: makeConfiguration()
        )
        currentLink.accessEnd = expiration.map { String(Int($0.timeIntervalSince1970)) }

        let updatedLink = try await NodeServiceAPI.updatePublicLink(
            linkUuid: linkID,
            publicLinkRequest: RestPublicLinkRequest(
                link: currentLink,
                passwordEnabled: currentLink.passwordRequired
            ),
            apiConfiguration: makeConfiguration()
        )

        return try WireCellsPublicLink(updatedLink, serverURL: serverURL)
    }

    func updatePublicLinkPassword(
        linkID: String,
        password: String?
    ) async throws -> WireCellsPublicLink {
        var currentLink = try await NodeServiceAPI.getPublicLink(
            linkUuid: linkID,
            apiConfiguration: makeConfiguration()
        )

        let hasExistingPassword = currentLink.passwordRequired == true
        currentLink.passwordRequired = password != nil

        let updatedLink = try await NodeServiceAPI.updatePublicLink(
            linkUuid: linkID,
            publicLinkRequest: RestPublicLinkRequest(
                createPassword: !hasExistingPassword ? password : nil,
                link: currentLink,
                passwordEnabled: password != nil,
                updatePassword: hasExistingPassword ? password : nil,
            ),
            apiConfiguration: makeConfiguration()
        )

        return try WireCellsPublicLink(updatedLink, serverURL: serverURL)
    }

    func updateTags(uuid: UUID, tags: [String]) async throws {
        let update = RestMetaUpdate(
            operation: .put,
            userMeta: .init(jsonValue: "\"\(tags.joined(separator: ","))\"", namespace: "usermeta-tags")
        )

        _ = try await NodeServiceAPI.patchNode(
            uuid: uuid.uuidString.lowercased(),
            nodeUpdates: .init(metaUpdates: [update]),
            apiConfiguration: makeConfiguration()
        )
    }

    func getAllTags() async throws -> [String] {
        let response = try await NodeServiceAPI.listNamespaceValues(
            namespace: "usermeta-tags",
            apiConfiguration: makeConfiguration()
        )
        return response.values ?? []
    }

    private var apiURL: URL {
        serverURL.appendingPathComponent("/v2")
    }

    private func makeConfiguration() async throws -> CellsSDKAPIConfiguration {
        let config = CellsSDKAPIConfiguration()
        config.basePath = apiURL.absoluteString
        config.customHeaders = ["Authorization": "Bearer \(try await accessTokenProvider.accessToken().token)"]
        config.interceptor = LoggingIntercepter()

        return config
    }
}

// MARK: - Helpers

private extension RestNodeLocator {

    init(_ value: WireCellsNodeLocator) {
        switch value {
        case let .path(path):
            self.init(path: path)
        case let .id(uuid):
            self.init(uuid: uuid.transportString())
        }
    }

}

private struct LoggingIntercepter: OpenAPIInterceptor {

    let interceptor = DefaultOpenAPIInterceptor()

    func intercept(
        urlRequest: URLRequest,
        urlSession: any URLSessionProtocol,
        requestBuilder: RequestBuilder<some Any>,
        completion: @escaping (Result<URLRequest, any Error>) -> Void
    ) {
        WireLogger.wireCells.log(urlRequest)

        interceptor.intercept(
            urlRequest: urlRequest,
            urlSession: urlSession,
            requestBuilder: requestBuilder,
            completion: completion
        )
    }

    func retry(
        urlRequest: URLRequest,
        urlSession: any URLSessionProtocol,
        requestBuilder: RequestBuilder<some Any>,
        data: Data?,
        response: URLResponse?,
        error: any Error,
        completion: @escaping (OpenAPIInterceptorRetry) -> Void
    ) {
        WireLogger.wireCells.warn("Wire cells node API request failed: \(error)")
        if let response = response as? HTTPURLResponse {
            WireLogger.wireCells.log(response: response)
        }

        interceptor.retry(
            urlRequest: urlRequest,
            urlSession: urlSession,
            requestBuilder: requestBuilder,
            data: data,
            response: response,
            error: error,
            completion: completion
        )
    }
}

private extension WireCellsGetNodesRequest {

    var lookupRequest: RestLookupRequest {
        var request = RestLookupRequest(
            flags: [.withPreSignedURLs, .withEditorURLs],
            limit: "\(limit)",
            offset: "\(offset)",
        )

        switch configuration {
        case let .conversationFileView(root, isFoldersEnabled):
            request.filters = RestLookupFilter(
                status: LookupFilterStatusFilter(
                    deleted: .not,
                    isDraft: false
                ),
                type: isFoldersEnabled ? .unknown : .leaf // .unknown includes files (leafs) & folders (collections)
            )
            request.scope = RestLookupScope(
                recursive: isFoldersEnabled ? false : true,
                root: RestNodeLocator(root)
            )
        case let .recycleBinView(root: root, isFoldersEnabled):
            request.filters = RestLookupFilter(
                status: LookupFilterStatusFilter(
                    deleted: .only,
                    isDraft: false
                ),
                type: isFoldersEnabled ? .unknown : .leaf // .unknown includes files (leafs) & folders (collections)
            )
            request.scope = RestLookupScope(
                recursive: !isFoldersEnabled,
                root: RestNodeLocator(root)
            )
        case .filesBrowserView:
            request.filters = RestLookupFilter(
                metadata: tags.isEmpty ? [] : [LookupFilterMetaFilter(
                    namespace: "usermeta-tags",
                    term: tags.joined(separator: ",")
                )], status: LookupFilterStatusFilter(
                    deleted: .not,
                    isDraft: false
                ),
                text: LookupFilterTextSearch(searchIn: .baseName, term: searchTerm ?? "*"),
                type: .leaf
            )
            request.scope = RestLookupScope(
                recursive: true,
                root: nil
            )
            request.sortDirDesc = true
            request.sortField = "mtime"
        case let .moveToFolder(root):
            request.filters = RestLookupFilter(
                status: LookupFilterStatusFilter(
                    deleted: .not,
                    isDraft: false
                ),
                type: .collection
            )
            request.scope = RestLookupScope(
                recursive: false,
                root: RestNodeLocator(path: root)
            )
        }
        return request
    }

}

private extension ErrorResponse {

    var underlyingError: any Error {
        switch self {
        case let .error(_, _, _, error):
            error
        }
    }
}

private extension RestPreSignedURL {

    var info: (url: URL, date: Date)? {
        guard
            let urlString = url,
            let url = URL(string: urlString),
            let expiresAtString = expiresAt,
            let expiresAtTimeInterval = TimeInterval(expiresAtString)
        else {
            return nil
        }
        return (url: url, date: Date(timeIntervalSinceNow: expiresAtTimeInterval))
    }

}

private extension WireCellsPublicLink {

    init(_ value: RestShareLink, serverURL: URL) throws {
        guard let linkID = value.uuid, let url = value.linkUrl else {
            throw WireCellsNodesAPIError.missingData("Missing link ID or URL")
        }

        self.init(
            linkID: linkID,
            url: serverURL.appendingPathComponent(url),
            requiresPassword: value.passwordRequired ?? false,
            expirationDate: value.accessEnd.flatMap { TimeInterval($0) }.map { Date(timeIntervalSince1970: $0) }
        )
    }

}
