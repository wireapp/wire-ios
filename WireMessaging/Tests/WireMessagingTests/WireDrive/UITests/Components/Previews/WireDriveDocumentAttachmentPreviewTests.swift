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
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireTestingPackage
import XCTest

@testable import WireMessagingUI

final class WireDriveDocumentAttachmentPreviewTests: XCTestCase {

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
        let testCases: [(headerIcon: Image, headerText: String, labelText: String, state: WireDriveFileUITracker.State)] =
            [
                (
                    headerIcon: Image(WireDriveFileType.pdf.imageResource),
                    headerText: "PDF (336 KB)",
                    labelText: "short file name",
                    state: .notLoaded
                ),
                (
                    headerIcon: Image(WireDriveFileType.pdf.imageResource),
                    headerText: "PDF (336 KB)",
                    labelText: "this is a file with a medium name that wraps",
                    state: .loading(progress: 0.5, isLargeFile: true)
                ),
                (
                    headerIcon: Image(WireDriveFileType.pdf.imageResource),
                    headerText: "PDF (336 KB)",
                    labelText: "this is a file with a long name that wraps and doesn't fit into the two lines of text",
                    state: .loaded(showReadyToOpen: false)
                ),
                (
                    headerIcon: Image(WireDriveFileType.pdf.imageResource),
                    headerText: "PDF (336 KB)",
                    labelText: "short file name",
                    state: .loaded(showReadyToOpen: true)
                ),
                (
                    headerIcon: Image(WireDriveFileType.pdf.imageResource),
                    headerText: "PDF (336 KB)",
                    labelText: "short file name",
                    state: .failed
                )
            ]

        for (index, testCase) in testCases.enumerated() {
            let view = WireDriveDocumentAttachmentPreview(
                headerIcon: testCase.headerIcon,
                headerText: testCase.headerText,
                labelText: testCase.labelText,
                state: testCase.state,
                isDraftPreview: false
            )
            .frame(width: 222, height: 74)
            snapshotHelper
                .withUserInterfaceStyle(.light)
                .verify(matching: view, named: "\(index).light")
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: view, named: "\(index).dark")
        }
    }

}
