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

import ActivityKit
import SwiftUI
import WidgetKit
import WireDesign
import WireDriveUploadsActivity
import WireFoundation

/// Shows the ongoing Wire Drive uploads on the lock screen and in the Dynamic Island.
struct WireDriveUploadsLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WireDriveUploadsActivityAttributes.self) { context in
            WireDriveUploadsBannerView(state: context.state)
                .activityBackgroundTint(ColorTheme.Backgrounds.background.onDarkSurface)
                .activitySystemActionForegroundColor(ColorTheme.Backgrounds.onBackground.onDarkSurface)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    WireDriveUploadsBannerView(state: context.state)
                        .activityBackgroundTint(ColorTheme.Backgrounds.background.onDarkSurface)
                        .activitySystemActionForegroundColor(ColorTheme.Backgrounds.onBackground.onDarkSurface)
                }
            } compactLeading: {
                WireDriveUploadsIslandIndicator(state: context.state)
            } compactTrailing: {
                WireDriveUploadsIslandCompactText(state: context.state)
            } minimal: {
                WireDriveUploadsIslandIndicator(state: context.state)
            }
            .keylineTint(ColorTheme.Base.primary(.blue).onDarkSurface)
        }
    }
}

// MARK: - Previews

#if DEBUG
    private extension WireDriveUploadsActivityState {

        static let uploading = Self(phase: .uploading, totalCount: 8, uploadedCount: 6, failedCount: 0, progress: 0.75)
        static let uploadingWithFailure = Self(
            phase: .uploadingWithFailures,
            totalCount: 8,
            uploadedCount: 6,
            failedCount: 1,
            progress: 0.75
        )
        static let completed = Self(phase: .completed, totalCount: 8, uploadedCount: 8, failedCount: 0, progress: 1)
        static let failed = Self(phase: .failed, totalCount: 8, uploadedCount: 0, failedCount: 8, progress: 0)
    }

    #Preview("Banner", as: .content, using: WireDriveUploadsActivityAttributes()) {
        WireDriveUploadsLiveActivity()
    } contentStates: {
        WireDriveUploadsActivityState.uploading
        WireDriveUploadsActivityState.uploadingWithFailure
        WireDriveUploadsActivityState.completed
        WireDriveUploadsActivityState.failed
    }

    #Preview("Compact", as: .dynamicIsland(.compact), using: WireDriveUploadsActivityAttributes()) {
        WireDriveUploadsLiveActivity()
    } contentStates: {
        WireDriveUploadsActivityState.uploading
        WireDriveUploadsActivityState.completed
        WireDriveUploadsActivityState.failed
    }

    #Preview("Minimal", as: .dynamicIsland(.minimal), using: WireDriveUploadsActivityAttributes()) {
        WireDriveUploadsLiveActivity()
    } contentStates: {
        WireDriveUploadsActivityState.uploading
        WireDriveUploadsActivityState.failed
    }

    #Preview("Expanded", as: .dynamicIsland(.expanded), using: WireDriveUploadsActivityAttributes()) {
        WireDriveUploadsLiveActivity()
    } contentStates: {
        WireDriveUploadsActivityState.uploading
        WireDriveUploadsActivityState.completed
        WireDriveUploadsActivityState.failed
    }
#endif
