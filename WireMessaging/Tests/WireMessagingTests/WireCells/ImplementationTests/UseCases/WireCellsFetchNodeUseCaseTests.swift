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

import WireMessagingDomainSupport
@testable import WireMessagingDomain

final class WireCellsFetchNodeUseCaseTests {

    private let repository = MockWireCellsNodesRepositoryProtocol()
    private let cache = MockWireCellsNodeCacheProtocol()
    private let sut: WireCellsFetchNodeUseCase

    init() {
        self.sut = WireCellsFetchNodeUseCase(repository: repository, cache: cache)

        cache.setItemFor_MockMethod = { _, _ in }
    }

    @Test
    func invoke_whenNothingCached() async throws {
        // Given
        let nodeID = UUID()
        let remoteNode = WireCellsNode.fixture(uuid: nodeID)

        cache.itemFor_MockMethod = { _ in nil }
        repository.getNodeId_MockValue = remoteNode

        // When
        let stream = sut.invoke(nodeID: nodeID)

        // Then
        let nodes = try await stream.collect()
        #expect(nodes == [remoteNode])
    }

    @Test
    func invoke_whenSomethingCached() async throws {
        // Given
        let nodeID = UUID()
        let cachedNode = WireCellsNode.fixture(uuid: nodeID, path: "foo/version 1.png")
        let remoteNode = WireCellsNode.fixture(uuid: nodeID, path: "foo/version 2.png")

        cache.itemFor_MockMethod = { _ in WireCellsNodeCacheItem(node: cachedNode) }
        repository.getNodeId_MockValue = remoteNode

        // When
        let stream = sut.invoke(nodeID: nodeID)

        // Then
        let nodes = try await stream.collect()
        #expect(nodes == [cachedNode, remoteNode])
    }

    @Test
    func invoke_whenNodeUnavailable() async throws {
        // Given
        let nodeID = UUID()

        cache.itemFor_MockMethod = { _ in WireCellsNodeCacheItem(node: nil) }
        repository.getNodeId_MockMethod = { _ in nil }

        // When
        let stream = sut.invoke(nodeID: nodeID)

        // Then
        let nodes = try await stream.collect()
        #expect(nodes == [nil, nil])
    }

}
