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

public import ActivityKit
import Foundation

/// The Live Activity showing ongoing Wire Drive direct uploads.
///
/// Shared by the app, which updates the activity, and the widget extension, which renders it. It
/// deliberately depends on nothing else so that the extension does not have to link the rest of the package.
public struct WireDriveUploadsActivityAttributes: ActivityAttributes {

    public typealias ContentState = WireDriveUploadsActivityState

    public init() {}
}

/// What the activity shows at a point in time.
public struct WireDriveUploadsActivityState: Codable, Hashable, Sendable {

    public enum Phase: String, Codable, Hashable, Sendable {

        /// Uploads are in progress, and none has failed.
        case uploading

        /// Uploads are in progress, and at least one has failed.
        case uploadingWithFailures

        /// Every upload finished successfully.
        case completed

        /// Nothing is in progress any more, and at least one upload failed.
        case failed
    }

    public var phase: Phase

    /// All the uploads of the activity, finished or not.
    public var totalCount: Int

    public var uploadedCount: Int

    public var failedCount: Int

    /// The fraction of the bytes sent, from 0 to 1.
    public var progress: Double

    public init(phase: Phase, totalCount: Int, uploadedCount: Int, failedCount: Int, progress: Double) {
        self.phase = phase
        self.totalCount = totalCount
        self.uploadedCount = uploadedCount
        self.failedCount = failedCount
        self.progress = progress
    }
}
