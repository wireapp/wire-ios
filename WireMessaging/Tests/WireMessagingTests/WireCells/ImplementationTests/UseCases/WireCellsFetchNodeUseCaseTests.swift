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
    func invoke_whenNodeNoteFound() async throws {
        // Given
        let nodeID = UUID()

        repository.getNodeId_MockMethod = { _ in nil }

        // When
        let node = try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(node == nil)
        #expect(cache.setItemFor_Invocations.map(\.value) == [WireCellsNodeCacheItem(node: nil)])
        #expect(cache.setItemFor_Invocations.map(\.nodeID) == [nodeID])
    }

    @Test
    func invoke_whenNodeFound() async throws {
        // Given
        let nodeID = UUID()
        let remoteNode = WireCellsNode.fixture(uuid: nodeID)

        repository.getNodeId_MockValue = remoteNode

        // When
        let node = try await sut.invoke(nodeID: nodeID)

        // Then
        #expect(node == remoteNode)
        #expect(cache.setItemFor_Invocations.map(\.value) == [WireCellsNodeCacheItem(node: remoteNode)])
        #expect(cache.setItemFor_Invocations.map(\.nodeID) == [nodeID])
    }

}
