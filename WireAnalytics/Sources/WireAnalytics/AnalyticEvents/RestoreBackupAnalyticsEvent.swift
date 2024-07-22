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

/// Enum representing the possible outcomes of a backup restoration.
public enum RestoreBackupResult {

    /// Indicates that the backup restoration was successful.
    case succeeded

    /// Indicates that the backup restoration failed.
    case failed

}

/// Struct representing an analytics event for backup restoration.
public struct RestoreBackupAnalyticsEvent: AnalyticsEvent {

    /// The result of the backup restoration.
    public let result: RestoreBackupResult

    /// Initializes a new RestoreBackupAnalyticsEvent with the given result.
    ///
    /// - Parameter result: The result of the backup restoration.
    public init(result: RestoreBackupResult) {
        self.result = result
    }

    /// The name of the event, which depends on the restoration result.
    public var eventName: String {
        switch result {
        case .succeeded:
            "restoreBackupSucceeded"
        case .failed:
            "restoreBackupFailed"
        }
    }

    /// Additional segmentation data for the event.
    public var segmentation: [SegmentationKeys: String] {
        [:]
    }
}
