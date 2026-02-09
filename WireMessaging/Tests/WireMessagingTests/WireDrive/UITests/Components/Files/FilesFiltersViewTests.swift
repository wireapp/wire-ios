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
import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class FilesFiltersViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var fetchTagsUseCase: (any WireDriveGetTagSuggestionsUseCaseProtocol)!
    private var nodesAPI: MockNodesAPIProtocol!

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        nodesAPI = MockNodesAPIProtocol()
        fetchTagsUseCase = WireDriveGetTagSuggestionsUseCase(nodesAPI: nodesAPI)
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        fetchTagsUseCase = nil
        nodesAPI = nil
    }

    @MainActor
    func testFilterTagsEmptyTags() async {
        let viewModel = await makeViewModel(tags: [])
        let view = FilterByTagsView(viewModel: viewModel) { tags in }
            .frame(width: 375, height: 667)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilterTagsLimitedItems() async {
        let viewModel = await makeViewModel(tags: Array(mockTags.prefix(7)))
        let view = FilterByTagsView(viewModel: viewModel) { tags in }
            .frame(width: 375, height: 667)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilterTagsSavedTags() async {
        let viewModel = await makeViewModel(
            tags: mockTags,
            savedTags: [mockTags[2], mockTags[4], mockTags[6]]
        )

        let view = FilterByTagsView(viewModel: viewModel) { tags in }
            .frame(width: 375, height: 667)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    private func makeViewModel(
        tags: [String],
        savedTags: [String] = []
    ) async -> FilterByTagsView.ViewModel {
        nodesAPI.getAllTags_MockMethod = { tags }

        let viewModel = FilterByTagsView.ViewModel(
            fetchTagsUseCase: fetchTagsUseCase,
            selectedTags: savedTags
        )

        await viewModel.fetch()

        return viewModel
    }

}
