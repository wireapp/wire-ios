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

import Combine
import Foundation
import Testing
import WireMessagingDomain

@testable import WireMessagingDomainSupport
@testable import WireMessagingUI

@MainActor
final class FilesFiltersViewModelTests {

    private let nodesRepository = MockWireDriveNodesRepositoryProtocol()
    private let sut: FilesFilterBy.TagsView.ViewModel!

    init() {
        let nodesApi = MockNodesAPIProtocol()
        nodesApi.getAllTags_MockMethod = { mockTags }
        self.sut = FilesFilterBy.TagsView.ViewModel(
            fetchTagsUseCase: WireDriveGetTagSuggestionsUseCase(nodesAPI: nodesApi),
            selectedTags: [Scaffolding.savedTag]
        )
    }

    @Test
    func presentedTags() async throws {
        // when
        await sut.fetch()

        // then
        #expect(sut.presentedTags == Scaffolding.expectedTags)
    }

    @Test
    func savedTags() async throws {
        // when
        await sut.fetch()

        // then
        let presentedTag = sut.presentedTags[0]
        #expect(sut.selectedTags == [presentedTag])
    }

    @Test
    func selectTag() async throws {
        // given
        await sut.fetch()

        // when
        sut.toggleTag(sut.presentedTags[1])

        // then
        let presentedTags = [sut.presentedTags[0], sut.presentedTags[1]]
        #expect(sut.selectedTags == Set(presentedTags))
    }

    @Test
    func clearAll() async throws {
        // given
        await sut.fetch()
        sut.toggleTag(sut.presentedTags[1])
        sut.toggleTag(sut.presentedTags[2])
        #expect(sut.selectedTags.count == 3)

        // when
        sut.clearAll()

        // then
        #expect(sut.selectedTags.isEmpty)
    }

    private enum Scaffolding {
        static let savedTag = "Urgent"
        static let selectedTag = "Marketing"
        
        static let expectedTags = Array(
            mockTags.filter { !$0.isEmpty }
                .sorted { lhs, rhs in lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending } //order alphabetically
                .sorted { lhs, _ in lhs.localizedCaseInsensitiveCompare(savedTag) == .orderedSame } //but initially selected tags should be the first in the list
        )
    }

}
