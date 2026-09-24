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

package import Foundation

// sourcery: AutoMockable
/// Drives Wire Drive direct uploads: staging, pre-check, presigning, background transfer
/// and reconciliation after the app is relaunched.
package protocol WireDriveDirectUploadManagerProtocol: Sendable {

    /// Reconciles persisted uploads against the background session's live tasks.
    ///
    /// Called once the database is available, which on a background relaunch may be well after the
    /// session started delivering events.

    func start() async

    /// Accepts a batch of picked files for upload into `destinationFolderPath`.
    @discardableResult
    func enqueue(sources: [WireDriveDirectUploadSource], destinationFolderPath: String) async throws -> UUID

    func cancel(uploadID: UUID) async

    func cancelAll() async

    func retry(uploadID: UUID) async

    /// Retries every failed upload that can still be retried.

    func retryFailed() async

    /// Forgets uploads that finished successfully or were cancelled, and deletes their staged files.
    func clearFinished() async

    /// Cancels everything and removes all state, e.g. on logout.

    func tearDown() async
}
