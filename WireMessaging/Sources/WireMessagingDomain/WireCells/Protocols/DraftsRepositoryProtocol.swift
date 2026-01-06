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
package protocol DraftsRepositoryProtocol: Sendable {

    func drafts(for cellName: String) async -> AsyncStream<[WireCellsDraft]>
    func publishAll(for cellName: String) async throws
    func clearPublishedDrafts(for cellName: String) async -> [WireCellsDraft]
    func addDraft(_ draft: WireCellsDraft, for cellName: String) async
    func fetchDraft(nodeID: UUID, cellName: String) async -> WireCellsDraft?
    func deleteDraft(nodeID: UUID, cellName: String) async
    func updateDraft(_ draft: WireCellsDraft, for cellName: String) async

}
