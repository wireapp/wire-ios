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
import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class FilesFilterViewTests: XCTestCase {
    
    private var snapshotHelper: SnapshotHelper!
    private var fetchTagsUseCase: (any WireCellsGetTagSuggestionsUseCaseProtocol)!
    private var nodesAPI: MockNodesAPIProtocol!

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        nodesApi = MockNodesAPIProtocol()
        getTagSuggestionsUseCase = WireCellsGetTagSuggestionsUseCase(nodesAPI: nodesApi)
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
        fetchTagsUseCase = nil
        nodesAPI = nil
    }
    
    @MainActor
    func testFilterTagsLimitedItems() {
        let viewModel = makeViewModel(tags: mockTags.prefix(7))
        let view = FilesFilterView(viewModel: viewModel)
            .frame(width: 390)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }
    
    @MainActor
    func testFilterTagsManyItems() {
        let viewModel = makeViewModel(tags: mockTags)
        let view = FilesFilterView(viewModel: viewModel)
            .frame(width: 390)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }
    
    @MainActor
    func testFilterTagsAppliedTags() {
        let viewModel = makeViewModel(
            tags: mockTags,
            appliedTags: [mockTags[2], mockTags[4], mockTags[6]]
        )
        
        let view = FilesFilterView(viewModel: viewModel)
            .frame(width: 390)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }
    
    @MainActor
    func testFilterTagsAppliedTags() {
        let viewModel = makeViewModel(
            tags: mockTags
        )
        
        let view = FilesFilterView(viewModel: viewModel)
            .frame(width: 390)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }
    
    @MainActor
    func testFilterTagsExpandedTags() {
        let viewModel = makeViewModel(
            tags: mockTags
        )
        
        let view = FilesFilterView(viewModel: viewModel)
            .frame(width: 390)
            .environment(\.wireTextStyleMapping, WireTextStyleMapping())
        
        viewModel.toggleTagsVisibility()

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light", record: record)
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark", record: record)
    }
    
    @MainActor
    private func makeViewModel(
        tags: [String],
        appliedTags: [String] = []
    ) -> FilesFiltersViewModel {
        nodesApi.getAllTags_MockMethod = { tags }
        
        return FilesFiltersViewModel(
            fetchTagsUseCase: fetchTagsUseCase,
            appliedTags: appliedTags
        )
    }
    
}
