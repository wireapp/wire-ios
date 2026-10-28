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
import WireDriveUploadsLiveActivity
import WireMessagingDomain

extension WireDriveUploadsActivityState {

    /// Maps what the tracker reports to what the activity shows.
    init(summary: WireDriveDirectUploadsSummary) {
        let phase: Phase = switch (summary.isFinished, summary.hasFailures) {
        case (false, false): .uploading
        case (false, true): .uploadingWithFailures
        case (true, false): .completed
        case (true, true): .failed
        }

        self.init(
            phase: phase,
            totalCount: summary.trackedCount,
            uploadedCount: summary.uploadedCount,
            failedCount: summary.failedCount,
            progress: Double(summary.overallProgress)
        )
    }

    var isFinished: Bool {
        phase == .completed || phase == .failed
    }
}
