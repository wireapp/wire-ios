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

import Foundation
import Testing
import WireDriveUploadsLiveActivity

@testable import WireMessagingAssembly
@testable import WireMessagingDomain

struct WireDriveUploadsActivityStateTests {

    @Test
    func mapsUploadsInProgressWithNoFailures() {
        let summary = WireDriveDirectUploadsSummary(items: [
            makeUploadItem(.uploaded),
            makeUploadItem(.uploading(progress: 0.5)),
            makeUploadItem(.queued)
        ])

        let state = WireDriveUploadsActivityState(summary: summary)

        #expect(state.phase == .uploading)
        #expect(state.totalCount == 3)
        #expect(state.uploadedCount == 1)
        #expect(state.failedCount == 0)
    }

    @Test
    func mapsUploadsInProgressWithAFailure() {
        let summary = WireDriveDirectUploadsSummary(items: [
            makeUploadItem(.failed(error: .unauthorized)),
            makeUploadItem(.uploading(progress: 0.5))
        ])

        let state = WireDriveUploadsActivityState(summary: summary)

        #expect(state.phase == .uploadingWithFailures)
        #expect(state.failedCount == 1)
    }

    @Test
    func mapsFinishedUploads() {
        let summary = WireDriveDirectUploadsSummary(items: [makeUploadItem(.uploaded), makeUploadItem(.uploaded)])

        let state = WireDriveUploadsActivityState(summary: summary)

        #expect(state.phase == .completed)
        #expect(state.isFinished)
        #expect(state.progress == 1)
    }

    @Test
    func mapsFinishedUploadsWithAFailure() {
        let summary = WireDriveDirectUploadsSummary(items: [
            makeUploadItem(.uploaded),
            makeUploadItem(.failed(error: .unauthorized))
        ])

        let state = WireDriveUploadsActivityState(summary: summary)

        #expect(state.phase == .failed)
        #expect(state.isFinished)
    }

    @Test
    func doesNotCountCancelledUploads() {
        let summary = WireDriveDirectUploadsSummary(items: [makeUploadItem(.uploaded), makeUploadItem(.cancelled)])

        #expect(WireDriveUploadsActivityState(summary: summary).totalCount == 1)
    }
}
