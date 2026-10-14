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
import WireDriveUploadsActivity

private typealias Strings = L10n.LiveActivity.Uploads

/// The texts the activity shows for a state.
struct WireDriveUploadsActivityPresentation {

    let state: WireDriveUploadsActivityState

    init(_ state: WireDriveUploadsActivityState) {
        self.state = state
    }

    var isFinished: Bool {
        state.phase == .completed || state.phase == .failed
    }

    var title: String {
        switch state.phase {
        case .uploading, .uploadingWithFailures:
            Strings.Uploading.title
        case .completed:
            Strings.Completed.title
        case .failed:
            state.failedCount == 1
                ? Strings.Failed.titleOne
                : Strings.Failed.titleMany(state.failedCount)
        }
    }

    /// What separates the parts of a subtitle.
    static let separator = " · "

    /// How many of the uploads are done.
    var progressSubtitle: String {
        Strings.Uploading.subtitle(state.uploadedCount, state.totalCount)
    }

    /// The part of the subtitle about the uploads that failed while others are still in progress, which is
    /// shown in red.
    var failureText: String? {
        state.phase == .uploadingWithFailures ? Strings.Uploading.failed(state.failedCount) : nil
    }

    var subtitle: String {
        switch state.phase {
        case .uploading:
            progressSubtitle
        case .uploadingWithFailures:
            [progressSubtitle, Strings.Uploading.failed(state.failedCount)].joined(separator: Self.separator)
        case .completed:
            state.totalCount == 1
                ? Strings.Completed.subtitleOne
                : Strings.Completed.subtitleMany(state.totalCount)
        case .failed:
            state.uploadedCount > 0
                ? Strings.Failed.subtitleWithUploaded(state.uploadedCount, state.totalCount)
                : Strings.Failed.subtitle
        }
    }

    /// What the Dynamic Island shows next to its leading indicator when compact.
    var compactText: String {
        switch state.phase {
        case .uploading, .uploadingWithFailures: "\(state.uploadedCount)/\(state.totalCount)"
        case .completed: "\(state.uploadedCount)/\(state.totalCount)"
        case .failed: "\(state.failedCount)/\(state.totalCount)"
        }
    }
}
