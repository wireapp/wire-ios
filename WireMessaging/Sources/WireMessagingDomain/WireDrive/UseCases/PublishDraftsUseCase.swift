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
package import WireFoundation
import WireAnalytics

package struct PublishDraftsUseCase: WireDrivePublishDraftsUseCaseProtocol {

    private let cellName: String
    private let draftRepository: any DraftsRepositoryProtocol
    private weak var analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?

    package init(cellName: String, draftRepository: any DraftsRepositoryProtocol, analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?) {
        self.cellName = cellName
        self.draftRepository = draftRepository
        self.analyticsEventTracker = analyticsEventTracker
    }

    package func invoke(containsText: Bool) async throws {
        let drafts = try await draftRepository.publishAll(for: cellName)
        
        let mixedTypes = Set(drafts.map { $0.fileType }).count > 1
        
        analyticsEventTracker?.trackEvent(
            .WireDriveSendFiles.shareFileNumber(
                containsText: containsText,
                numberOfAttachments: drafts.count,
                mixedTypes: mixedTypes
            )
        )
    }
}
