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

import Combine
import Foundation
import Testing
import WireMessagingDomain

@testable import WireMessagingDomainSupport
@testable import WireMessagingUI

@MainActor
final class FilesViewModelTests {

    private let nodesRepository = MockWireCellsNodesRepositoryProtocol()
    private let sut: FilesViewModel
    private var itemsUpdates: [[FilesViewItem]] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.sut = FilesViewModel(
            fetchNodesUseCase: WireCellsFetchNodesUseCase(
                configuration: .conversationFileView(root: .path("some-cell")),
                repository: nodesRepository
            )
        )

        sut.$items.dropFirst().sink { [weak self] items in
            self?.itemsUpdates.append(items)
        }.store(in: &cancellables)
    }

    @Test func isLoading() async throws {
        // given
        nodesRepository.getNodes_MockMethod = { [sut] request in
            // Here we assert that loading is true when the methods under test are called.
            #expect(sut.isLoading == true)

            let page1 = (nodes: [WireCellsNode.fixture()], nextOffset: 1)
            let page2 = (nodes: [WireCellsNode.fixture()], nextOffset: Optional<Int>.none)
            return request.offset == 0 ? page1 : page2
        }
        #expect(sut.isLoading == false)

        // when
        await sut.reload()

        // then
        #expect(sut.isLoading == false)

        // when
        await sut.loadMoreIfNeeded(index: 0)

        // then
        #expect(sut.isLoading == false)
    }

}
