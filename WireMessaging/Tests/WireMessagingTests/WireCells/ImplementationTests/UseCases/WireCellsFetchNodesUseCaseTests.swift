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

import Testing

@testable import WireMessagingDomain
@testable import WireMessagingDomainSupport

@MainActor
struct WireCellsFetchNodesUseCaseTests {

    private let repository = MockWireCellsNodesRepositoryProtocol()
    private let localAssetRepository = MockWireCellsLocalAssetRepositoryProtocol()
    private let sut: WireCellsFetchNodesUseCase

    init() {
        self.sut = WireCellsFetchNodesUseCase(
            configuration: .conversationFileView(root: WireCellsNodeLocator.path("some/path"), isFoldersEnabled: false),
            repository: repository,
            localAssetRepository: localAssetRepository
        )
        repository.getNodes_MockValue = (nodes: [WireCellsNode.fixture()], nextOffset: 30)
        localAssetRepository.assetNodeID_MockValue = WireCellsLocalAsset.fixture()
        localAssetRepository.deleteAssetsNodeIDs_MockMethod = { _ in }
    }

    @Test
    func testInvoke_withConversationFileViewConfiguration() async throws {
        // Given
        let sut = WireCellsFetchNodesUseCase(
            configuration: .conversationFileView(root: WireCellsNodeLocator.path("some/path"), isFoldersEnabled: false),
            repository: repository,
            localAssetRepository: localAssetRepository
        )

        let someNode = WireCellsNode.fixture()
        repository.getNodes_MockValue = (nodes: [someNode], nextOffset: 30)

        // When
        let (nodes, isLastPage) = try await sut.invoke(searchTerm: nil, tags: [], offset: 0)

        // Then
        #expect(nodes == [someNode])
        #expect(isLastPage == false)
        #expect(
            repository.getNodes_Invocations == [
                WireCellsGetNodesRequest(
                    searchTerm: nil,
                    limit: 30,
                    offset: 0,
                    configuration: .conversationFileView(root: .path("some/path"), isFoldersEnabled: false)
                )
            ]
        )
    }

    @Test
    func testInvoke_pagination() async throws {
        // Given
        repository.getNodes_MockValue = (nodes: [WireCellsNode.fixture()], nextOffset: 30)

        // When
        let (_, isLastPage) = try await sut.invoke(searchTerm: nil, tags: [], offset: 0)

        // Then
        #expect(isLastPage == false)
        #expect(repository.getNodes_Invocations.last?.offset == 0)

        // When
        let (_, _) = try await sut.invoke(searchTerm: nil, tags: [], offset: 30)

        // Then
        #expect(repository.getNodes_Invocations.last?.offset == 30)
    }

    @Test
    func testInvoke_searchTerm() async throws {
        // When
        let (_, _) = try await sut.invoke(searchTerm: nil, tags: [], offset: 0)
        let (_, _) = try await sut.invoke(searchTerm: "foo", tags: [], offset: 0)

        // Then
        try #require(repository.getNodes_Invocations.count == 2)
        #expect(repository.getNodes_Invocations[0].searchTerm == nil)
        #expect(repository.getNodes_Invocations[1].searchTerm == "foo")
    }

}
