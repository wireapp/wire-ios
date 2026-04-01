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
import WireMessagingDomain
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class WireDriveImageAttachmentPreviewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    @MainActor
    func testConfigurationVariations() async throws {
        let testCases: [(thumbnail: Image?, state: WireDriveFileUITracker.State)] = [
            (thumbnail: nil, state: .notLoaded),
            (thumbnail: nil, state: .loading(progress: 0.5, isLargeFile: true)),
            (thumbnail: nil, state: .loaded(showReadyToOpen: true)),
            (thumbnail: nil, state: .loaded(showReadyToOpen: false)),
            (thumbnail: nil, state: .failed),
            (thumbnail: Image(.rectangularPlaceholder), state: .notLoaded),
            (thumbnail: Image(.rectangularPlaceholder), state: .loading(progress: 0.5, isLargeFile: true)),
            (thumbnail: Image(.rectangularPlaceholder), state: .loaded(showReadyToOpen: true)),
            (thumbnail: Image(.rectangularPlaceholder), state: .loaded(showReadyToOpen: false)),
            (thumbnail: Image(.rectangularPlaceholder), state: .failed)
        ]

        for (index, testCase) in testCases.enumerated() {
            let view = WireDriveImageAttachmentPreview(
                thumbnail: testCase.thumbnail,
                state: testCase.state
            )
            .frame(width: 74, height: 74)

            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(index).light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(index).dark")
        }
    }

}
