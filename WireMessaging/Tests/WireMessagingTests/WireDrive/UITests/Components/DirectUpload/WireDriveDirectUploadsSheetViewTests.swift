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

struct WireDriveDirectUploadsSheetViewTests {

    private let snapshotHelper: SnapshotHelper = .init()
        .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)

    @Test
    @MainActor
    func mixedBatch() {
        snapshotHelper.verifyLightAndDark(matching: makeView(items: .previewBatch))
    }

    @Test
    @MainActor
    func singleFileUploading() {
        let items: [WireDriveDirectUploadItem] = [
            .preview(fileName: "MOV_567823.mp4", status: .uploading(progress: 0.6))
        ]
        snapshotHelper.verifyLightAndDark(matching: makeView(items: items))
    }

    @Test
    @MainActor
    func everythingFailed() {
        let items: [WireDriveDirectUploadItem] = [
            .preview(fileName: "a.pdf", status: .failed(error: .unauthorized), isRetryable: true),
            .preview(fileName: "b.pdf", status: .failed(error: .fileNotFound), isRetryable: false)
        ]
        snapshotHelper.verifyLightAndDark(matching: makeView(items: items))
    }

    @MainActor
    private func makeView(items: [WireDriveDirectUploadItem]) -> some View {
        WireDriveDirectUploadsSheetView(viewModel: .preview(items: items))
            .frame(width: 375, height: 500)
    }
}
