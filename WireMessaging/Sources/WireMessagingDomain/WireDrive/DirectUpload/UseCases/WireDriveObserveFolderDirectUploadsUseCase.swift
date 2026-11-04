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

/// Observes the uploads destined for one folder.
@MainActor
package struct WireDriveObserveFolderDirectUploadsUseCase: WireDriveObserveFolderDirectUploadsUseCaseProtocol {

    private let tracker: any WireDriveDirectUploadTrackerProtocol

    package init(tracker: any WireDriveDirectUploadTrackerProtocol) {
        self.tracker = tracker
    }

    package func invoke(folderPath: String) -> AnyPublisher<[WireDriveDirectUploadItem], Never> {
        tracker.publisher(folderPath: folderPath)
    }
}
