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

final class WireDriveVideoAttachmentPreviewTests: XCTestCase {

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
        let testCases: [(thumbnail: Image?, state: WireDriveFileUITracker.State, canPlay: Bool)] = [
            (thumbnail: nil, state: .loaded(showReadyToOpen: false), canPlay: true),
            (thumbnail: nil, state: .loaded(showReadyToOpen: false), canPlay: false),
            (thumbnail: nil, state: .loaded(showReadyToOpen: true), canPlay: true),
            (
                thumbnail: Image(.rectangularPlaceholder),
                state: .loading(progress: 0.5, isLargeFile: true),
                canPlay: true
            ),
            (
                thumbnail: Image(.rectangularPlaceholder),
                state: .loading(progress: 0.5, isLargeFile: true),
                canPlay: false
            ),
            (thumbnail: Image(.rectangularPlaceholder), state: .failed, canPlay: true)
        ]

        for (index, testCase) in testCases.enumerated() {
            let view = WireDriveVideoAttachmentPreview(
                thumbnail: testCase.thumbnail,
                state: testCase.state,
                canPlay: testCase.canPlay
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
