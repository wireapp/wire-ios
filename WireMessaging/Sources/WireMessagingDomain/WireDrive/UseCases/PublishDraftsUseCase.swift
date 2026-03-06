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
import WireAnalytics
package import WireFoundation

package struct PublishDraftsUseCase: WireDrivePublishDraftsUseCaseProtocol {

    private let cellName: String
    private let draftRepository: any DraftsRepositoryProtocol
    private var analyticsProvider: () -> (any AnalyticsEventTrackerProtocol)?

    package init(
        cellName: String,
        draftRepository: any DraftsRepositoryProtocol,
        analyticsProvider: @escaping () -> (any AnalyticsEventTrackerProtocol)?
    ) {
        self.cellName = cellName
        self.draftRepository = draftRepository
        self.analyticsProvider = analyticsProvider
    }

    package func invoke(containsText: Bool) async throws {
        let drafts = try await draftRepository.publishAll(for: cellName)

        let mixedTypes = Set(drafts.map(\.fileType)).count > 1

        analyticsProvider()?.trackEvent(
            .WireDriveSendFiles.shareFileNumber(
                containsText: containsText,
                numberOfAttachments: drafts.count,
                mixedTypes: mixedTypes
            )
        )

        for draft in drafts {
            let fileExtension = "." + draft.assetURL.pathExtension
            let fileSize = UInt64(draft.bytes)

            analyticsProvider()?.trackEvent(
                .WireDriveSendFiles.shareFile(
                    fileExtension: fileExtension,
                    fileSize: fileSize
                )
            )
        }
    }
}
