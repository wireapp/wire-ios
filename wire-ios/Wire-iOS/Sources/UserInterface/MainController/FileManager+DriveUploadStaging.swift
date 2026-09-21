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
import WireCommonComponents

extension FileManager {

    static let driveUploadStagingFolderName = "drive-upload-staging"

    /// The directory holding copies of files queued for a Wire Drive direct upload.
    ///
    /// Must be under **Application Support, not Caches**. The system may evict Caches at any
    /// time, and an evicted file turns an upload the user could have retried into a permanent
    /// failure, including after the force-quit that this whole mechanism is built to survive.

    func driveUploadStagingURL(for appGroupIdentifier: String, accountIdentifier: UUID) -> URL? {
        guard let containerURL = containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return nil
        }

        return containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(
                "\(Self.cachesFolderPrefix)-\(accountIdentifier.uuidString)",
                isDirectory: true
            )
            .appendingPathComponent(Self.driveUploadStagingFolderName, isDirectory: true)
    }
}
