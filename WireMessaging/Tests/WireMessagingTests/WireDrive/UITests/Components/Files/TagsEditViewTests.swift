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

import SwiftUI
import Testing
import WireDesign
import WireMessagingDomain
import WireMessagingDomainSupport
import WireTestingPackage

@testable import WireMessagingUI

final class TagsEditViewTests {

    private var snapshotHelper: SnapshotHelper!
    private var updateTagsUseCase = MockWireDriveUpdateTagsUseCaseProtocol()
    private var getTagSuggestionsUseCase = MockWireDriveGetTagSuggestionsUseCaseProtocol()

    init() {
        self.snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        getTagSuggestionsUseCase.invoke_MockValue = ["tag1, tag2, tag3"]
    }

    @MainActor @Test
    func testTagsEditView() async {
        let view = makeView()
            .frame(width: 375, height: 667)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: view, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: view, named: "dark")
    }

    @MainActor
    private func makeView() -> TagsEditView {
        TagsEditView(
            fileItem: .fixture(),
            useCases: .init(
                updateTags: updateTagsUseCase,
                getSuggestions: getTagSuggestionsUseCase
            )
        ) {}
    }

}
