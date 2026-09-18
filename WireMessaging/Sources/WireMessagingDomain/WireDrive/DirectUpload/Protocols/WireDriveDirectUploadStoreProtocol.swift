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
/// Persists Wire Drive direct uploads so they survive app termination.
package protocol WireDriveDirectUploadStoreProtocol: Sendable {

    func fetchAll() async throws -> [WireDriveDirectUploadRecord]

    func fetch(uploadID: UUID) async throws -> WireDriveDirectUploadRecord?

    func fetch(states: [WireDriveDirectUploadRecord.State]) async throws -> [WireDriveDirectUploadRecord]

    func upsert(_ record: WireDriveDirectUploadRecord) async throws

    func upsert(records: [WireDriveDirectUploadRecord]) async throws

    func delete(uploadIDs: [UUID]) async throws

    /// Removes every record, e.g. on logout.

    func deleteAll() async throws
}
