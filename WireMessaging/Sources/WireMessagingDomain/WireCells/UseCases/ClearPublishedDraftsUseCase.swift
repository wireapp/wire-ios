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

import Foundation
import WireLogging

package struct ClearPublishedDraftsUseCase: WireCellsClearPublishedDraftsUseCaseProtocol {

    private let cellName: String
    private let draftRepository: any DraftsRepositoryProtocol

    package init(cellName: String, draftRepository: any DraftsRepositoryProtocol) {
        self.cellName = cellName
        self.draftRepository = draftRepository
    }

    public func invoke() async {
        let cleared = await draftRepository.clearPublishedDrafts(for: cellName)
        let filesForDeletion = cleared.filter(\.requiresCleanup).map(\.assetURL)

        for url in filesForDeletion {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                WireLogger.wireCells.error("Failed to delete draft asset from disk", attributes: .safePublic)
            }
        }
    }
}
