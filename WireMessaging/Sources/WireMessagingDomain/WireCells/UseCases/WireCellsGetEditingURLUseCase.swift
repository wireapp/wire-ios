//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// Returns a URL to an online editor where a document can be edited, along with the date when the URL was generated.
package struct WireCellsGetEditingURLUseCase {

    private let editingURLRepository: any WireCellsEditingURLRepositoryProtocol

    package init(
        editingURLRepository: any WireCellsEditingURLRepositoryProtocol
    ) {
        self.editingURLRepository = editingURLRepository
    }

    /// Fetches the editor URL for a given node ID.
    ///
    /// - Parameter nodeID: The unique identifier of the node/document.
    /// - Returns: The editor URL, or `nil` if no URL is available.
    /// - Throws: An error if the request fails.
    package func invoke(nodeID: UUID) async throws -> URL? {
        try await editingURLRepository.getEditorURL(id: nodeID)?.url
    }

}
