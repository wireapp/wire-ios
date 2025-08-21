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

struct WireCellsFetchNodesUseCaseTests {

    private let repository = MockWireCellsNodesRepositoryProtocol()
    private let sut: WireCellsFetchNodesUseCase

    init() {
        self.sut = WireCellsFetchNodesUseCase(
            configuration: .conversationFileView(root: WireCellsNodeLocator.path("some/path")),
            repository: repository
        )
        repository.getNodes_MockValue = (nodes: [WireCellsNode.fixture()], nextOffset: 30)
    }

    @Test
    func testInvoke_withConversationFileViewConfiguration() async throws {
        // Given
        let sut = WireCellsFetchNodesUseCase(
            configuration: .conversationFileView(root: WireCellsNodeLocator.path("some/path")),
            repository: repository
        )

        let someNode = WireCellsNode.fixture()
        repository.getNodes_MockValue = (nodes: [someNode], nextOffset: 30)

        // When
        let (nodes, token) = try await sut.invoke(searchTerm: nil, token: nil)

        // Then
        #expect(nodes == [someNode])
        #expect(token == WireCellsPageToken(offset: 30))
        #expect(
            repository.getNodes_Invocations == [
                WireCellsGetNodesRequest(
                    scope: .init(root: .path("some/path"), isRecursive: true),
                    filter: .init(deletionStatus: .notDeleted, text: nil, type: .leaf),
                    limit: 30,
                    offset: 0
                )
            ]
        )
    }

    @Test
    func testInvoke_pagination() async throws {
        // Given
        repository.getNodes_MockValue = (nodes: [WireCellsNode.fixture()], nextOffset: 30)

        // When
        let (_, token) = try await sut.invoke(searchTerm: nil, token: nil)

        // Then
        #expect(token?.offset == 30)
        #expect(repository.getNodes_Invocations.last?.offset == 0)

        // When
        let (_, _) = try await sut.invoke(searchTerm: nil, token: token)

        // Then
        #expect(repository.getNodes_Invocations.last?.offset == 30)
    }

    @Test
    func testInvoke_searchTerm() async throws {
        // When
        let (_, _) = try await sut.invoke(searchTerm: nil, token: nil)
        let (_, _) = try await sut.invoke(searchTerm: "foo", token: nil)

        // Then
        try #require(repository.getNodes_Invocations.count == 2)
        #expect(repository.getNodes_Invocations[0].filter.text == nil)
        #expect(repository.getNodes_Invocations[1].filter.text == "foo")
    }

}
