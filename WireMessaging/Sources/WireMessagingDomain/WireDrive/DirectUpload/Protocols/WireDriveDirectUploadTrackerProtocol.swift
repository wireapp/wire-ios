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

package import Combine
package import Foundation

// sourcery: AutoMockable
/// Observes the state of every Wire Drive direct upload, and is what the pipeline reports into.
@MainActor
package protocol WireDriveDirectUploadTrackerProtocol: AnyObject {

    // MARK: - Reading

    /// The current state of all tracked uploads.

    var summary: WireDriveDirectUploadsSummary { get }

    /// Emits the current summary immediately, then on every change.

    var summaryPublisher: AnyPublisher<WireDriveDirectUploadsSummary, Never> { get }

    /// Emits the given upload immediately, then on every change, and `nil` once it is removed.

    func publisher(uploadID: UUID) -> AnyPublisher<WireDriveDirectUploadItem?, Never>

    /// Emits the uploads destined for exactly the given folder, oldest first — not its subfolders.

    func publisher(folderPath: String) -> AnyPublisher<[WireDriveDirectUploadItem], Never>

    // MARK: - Writing

    /// Replaces the tracked set outright, dropping anything not present in `items`.

    func replaceAll(with items: [WireDriveDirectUploadItem])

    /// Merges `items` into the tracked set without dropping anything absent from it.

    func upsert(_ items: [WireDriveDirectUploadItem])

    /// Updates only the progress of an already-tracked, non-terminal upload. A no-op otherwise.

    func updateProgress(uploadID: UUID, progress: Float)

    /// Empties the tracked set.

    func removeAll()
}
