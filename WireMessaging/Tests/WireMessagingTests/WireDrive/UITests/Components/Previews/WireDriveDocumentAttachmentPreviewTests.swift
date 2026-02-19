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
import WireTestingPackage
import XCTest
import WireMessagingDomain

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
        let testCases: [(headerIcon: Image, headerText: String, labelText: String, progress: Double?, isError: Bool)] =
            [
                (
                    headerIcon: Image(WireDriveFileType.pdf.imageResource),
                    headerText: "PDF (336 KB)",
                    labelText: "short file name",
                    progress: nil,
                    isError: false
                ),
                (
                    headerIcon: Image(WireDriveFileType.pdf.imageResource),
                    headerText: "PDF (336 KB)",
                    labelText: "this is a file with a medium name that wraps",
                    progress: 0.5,
                    isError: false
                ),
                (
                    headerIcon: Image(WireDriveFileType.pdf.imageResource),
                    headerText: "PDF (336 KB)",
                    labelText: "this is a file with a long name that wraps and doesn't fit into the two lines of text",
                    progress: 1,
                    isError: true
                )
            ]

        for (index, testCase) in testCases.enumerated() {
            let view = WireDriveDocumentAttachmentPreview(
                headerIcon: testCase.headerIcon,
                headerText: testCase.headerText,
                labelText: testCase.labelText,
                progress: testCase.progress,
                isError: testCase.isError
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
