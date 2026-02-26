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

final class FilesFilterByTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var fetchTagsUseCase: (any WireDriveGetTagSuggestionsUseCaseProtocol)!
    private var nodesAPI: MockNodesAPIProtocol!

    @MainActor
    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)

        nodesAPI = MockNodesAPIProtocol()
        nodesAPI.getAllTags_MockMethod = { ["Lorem", "ipsum", "dolor", "sit", "amet"] }

        fetchTagsUseCase = WireDriveGetTagSuggestionsUseCase(nodesAPI: nodesAPI)
    }

    @MainActor
    override func tearDown() async throws {
        snapshotHelper = nil
    }

    @MainActor
    func testFilterByTags() async {
        let view = FilesFilterBy.TagsView(
            fetchTagsUseCase: fetchTagsUseCase,
            selectedItems: ["sit"],
            onApply: { _ in }
        )
        .frame(width: 375, height: 667)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilterByTypes() async {
        let view = FilesFilterBy.TypeView(
            includeFolders: false,
            selectedItems: [.audio, .video],
            onApply: { _ in }
        )
        .frame(width: 375, height: 667)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilterByConversations() async {
        let mockedItems = [WireDriveConversation].mocked()

        let view = FilesFilterBy.ConversationView(
            availableItems: mockedItems,
            selectedItems: [mockedItems.first!, mockedItems.last!],
            onApply: { _ in }
        )
        .frame(width: 375, height: 667)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilterByOwners() async {
        let mockedItems = [WireDriveConversation.Participant].mocked()

        let view = FilesFilterBy.OwnerView(
            availableItems: mockedItems,
            selectedItems: [mockedItems.first!, mockedItems.last!],
            onApply: { _ in }
        )
        .frame(width: 375, height: 667)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    func testFilterBySharedLink() async {
        let view = FilesFilterBy.SharedLinkView(
            selected: true,
            onApply: { _ in }
        )
        .frame(width: 375, height: 667)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }
}
