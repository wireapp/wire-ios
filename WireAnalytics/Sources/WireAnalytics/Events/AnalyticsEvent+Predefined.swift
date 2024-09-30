//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

public extension AnalyticsEvent {

    /// An event tracking when the user opens the app.
    ///
    /// - Returns: An app open analytics event.

    static func appOpen() -> AnalyticsEvent {
        self.init(name: "app.open")
    }

    /// An event tracking when the user fails to export a backup.
    ///
    /// - Returns: A backup export failure analytics event.

    static func backupExportFailed() -> AnalyticsEvent {
        self.init(name: "backup.export_failed")
    }

    /// An event tracking when the user successuflly restores a backup.
    ///
    /// - Returns: A backup restored analytics event.

    static func backupRestored() -> AnalyticsEvent {
        self.init(name: "backup.restore_succeeded")
    }

    /// An event tracking when the user fails to restores a backup.
    ///
    /// - Returns: A backup restore failure analytics event.

    static func backupRestoredFailed() -> AnalyticsEvent {
        self.init(name: "backup.restore_failed")
    }

    /// An event tracking when the user initiates a call.
    ///
    /// - Parameters:
    ///   - isVideo: Whether video is enabled.
    ///   - conversationType: The type of conversation.
    ///
    /// - Returns: A call initialized analytics event.

    static func callInitialized(
        isVideo: Bool,
        conversationType: ConversationType
    ) -> AnalyticsEvent {
        self.init(
            name: "calling.initiated_call",
            segmentation: [
                .isVideoCall(isVideo),
                .groupType(conversationType)
            ]
        )
    }

    /// An event tracking when the user joins a call.
    ///
    /// - Parameters:
    ///   - isVideo: Whether video is enabled.
    ///   - conversationType: The type of conversation.
    ///
    /// - Returns: A call joined analytics event.

    static func callJoined(
        isVideo: Bool,
        conversationType: ConversationType
    ) -> AnalyticsEvent {
        self.init(
            name: "calling.joined_call",
            segmentation: [
                .isVideoCall(isVideo),
                .groupType(conversationType)
            ]
        )
    }

    /// An event tracking the when the user contributes to a conversation.
    ///
    /// - Parameters:
    ///   - contributionType: The type of contribution.
    ///   - conversationType: The type of conversation.
    ///   - conversationSize: The number of participants in the conversation.
    ///
    /// - Returns: A conversation contribution anlytics event.

    static func conversationContribution(
        _ contributionType: ConversationContributionType,
        conversationType: ConversationType,
        conversationSize: UInt
    ) -> AnalyticsEvent {
        self.init(
            name: "contributed",
            segmentation: [
                .contributionType(contributionType),
                .groupType(conversationType),
                .conversationSize(conversationSize)
            ]
        )
    }

}
