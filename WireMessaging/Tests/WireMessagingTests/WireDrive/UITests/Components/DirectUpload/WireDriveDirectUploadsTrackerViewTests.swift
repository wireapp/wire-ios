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
import WireTestingPackage

@testable import WireMessagingDomain
@testable import WireMessagingUI

struct WireDriveDirectUploadsTrackerViewTests {

    private let snapshotHelper: SnapshotHelper = .init()
        .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)

    @Test
    @MainActor
    func uploading() {
        snapshotHelper.verifyLightAndDark(matching: makeView(items: .previewBatch))
    }

    @Test
    @MainActor
    func allUploaded() {
        let items: [WireDriveDirectUploadItem] = [
            .preview(fileName: "a.pdf", status: .uploaded),
            .preview(fileName: "b.pdf", status: .uploaded)
        ]
        snapshotHelper.verifyLightAndDark(matching: makeView(items: items))
    }

    @Test
    @MainActor
    func allFailed() {
        let items: [WireDriveDirectUploadItem] = [
            .preview(fileName: "a.pdf", status: .failed(error: .unauthorized), isRetryable: true),
            .preview(fileName: "b.pdf", status: .failed(error: .unauthorized), isRetryable: true)
        ]
        snapshotHelper.verifyLightAndDark(matching: makeView(items: items))
    }

    @Test
    @MainActor
    func partiallyFailed() {
        let items: [WireDriveDirectUploadItem] = [
            .preview(fileName: "a.pdf", status: .uploaded),
            .preview(fileName: "b.pdf", status: .failed(error: .unauthorized), isRetryable: true),
            .preview(fileName: "c.pdf", status: .uploading(progress: 0.4))
        ]
        snapshotHelper.verifyLightAndDark(matching: makeView(items: items))
    }

    @MainActor
    private func makeView(items: [WireDriveDirectUploadItem]) -> some View {
        WireDriveDirectUploadsTrackerView(viewModel: .preview(items: items))
            .frame(width: 375)
            .fixedSize(horizontal: false, vertical: true)
    }
}
