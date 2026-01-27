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

/// Fetches nodes for a particular configuration, and mutating the injected WireCellsNodesCollection.
package final class WireCellsFetchNodesUseCase: Sendable {

    /// The type of request.
    package enum Request {

        /// Reloads the nodes with an optional search term.
        case reload(searchTerm: String?)

        /// Loads more nodes.
        case loadMore

    }

    private let configuration: WireCellsGetNodesRequest.Configuration
    private let repository: any WireCellsNodesRepositoryProtocol
    private let state: WireCellsNodesCollection

    @MainActor private var searchTerm: String?

    @MainActor private var currentTask: Task<(nodes: [WireCellsNode], nextOffset: Int?), any Error>?

    /// Initializes the use case with the required parameters.
    /// - Parameters:
    ///   - configuration: The configuration for the use case.
    ///   - repository: The repository to use for fetching nodes.
    package init(
        state: WireCellsNodesCollection,
        configuration: WireCellsGetNodesRequest.Configuration,
        repository: any WireCellsNodesRepositoryProtocol
    ) {
        self.state = state
        self.configuration = configuration
        self.repository = repository
    }

    /// Invokes the use case with the given `request` mutating the injected WireCellsNodesCollection.
    package func invoke(
        request: Request
    ) async throws -> (nodes: [WireCellsNode], hasMore: Bool) {
        switch request {
        case let .reload(searchTerm):
            await setSearchTerm(searchTerm)
            await cancelCurrentTask()
            await state.setNodes([])
        case .loadMore:
            break
        }

        let task = await loadMoreTask()
        let (newNodes, nextOffset) = try await task.value
        let allNodes = await appendNodes(newNodes)

        return (allNodes, nextOffset != nil)
    }

    @MainActor
    private func loadMoreTask() -> Task<(nodes: [WireCellsNode], nextOffset: Int?), any Error> {
        if let task = currentTask {
            return task
        }

        let request = WireCellsGetNodesRequest(
            searchTerm: searchTerm,
            limit: 30,
            offset: state.nodes.count,
            configuration: configuration
        )

        let task = Task {
            var (nodes, nextOffset) = try await repository.getNodes(request)
            nodes = nodes.filter { !$0.isDraft }
            return (nodes: nodes, nextOffset: nextOffset)
        }
        currentTask = task

        return task
    }

    @MainActor
    private func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }

    @MainActor
    private func setSearchTerm(_ searchTerm: String?) {
        self.searchTerm = searchTerm
    }

    @MainActor
    private func appendNodes(_ nodes: [WireCellsNode]) -> [WireCellsNode] {
        let newNodes = Self.processItems(state.nodes + nodes)
        state.setNodes(newNodes)
        return nodes
    }

    /// Removes items with duplicate IDs keeping the latest modified if known, otherwise the first.
    private static func processItems(_ items: [WireCellsNode]) -> [WireCellsNode] {
        var latestByID: [UUID: WireCellsNode] = [:]
        for item in items {
            if let existing = latestByID[item.id] {
                let existingDate = existing.modified ?? .distantPast
                let newDate = item.modified ?? .distantPast
                if newDate > existingDate {
                    latestByID[item.id] = item
                }
            } else {
                latestByID[item.id] = item
            }
        }

        var results: [WireCellsNode] = []
        for item in items where item == latestByID[item.id] {
            results.append(item)
        }

        return results
    }

}
