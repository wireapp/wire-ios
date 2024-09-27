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

/// Struct representing an analytics event for backup restoration.
public struct RestoreBackupAnalyticsEvent: AnalyticsEvent {

    /// Indicates whether the backup restoration was successful.
    public let didSucceed: Bool

    /// Initializes a new RestoreBackupAnalyticsEvent.
    ///
    /// - Parameter didSucceed: A boolean indicating whether the backup restoration was successful.
    public init(didSucceed: Bool) {
        self.didSucceed = didSucceed
    }

    /// The name of the event, which depends on the restoration result.
    public var eventName: String {
        didSucceed ? "backup.restore_succeeded" : "backup.restore_failed"
    }

    /// Additional segmentation data for the event.
    public var segmentation: Set<SegmentationEntry> {
        []
    }
}
