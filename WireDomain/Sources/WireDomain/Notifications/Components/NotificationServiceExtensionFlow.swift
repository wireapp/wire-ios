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

import NeedleFoundation
import WireDataModel

final class NotificationServiceExtensionFlow: BootstrapComponent {

    enum Failure: Error {
        case missingAppGroupID
    }

    public let contentHandler: (UNNotificationContent) -> Void
    public let applicationIdentifier: String
    public let applicationContainer: URL

    init(
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) throws {
        self.contentHandler = contentHandler

        let infoDictionary = Bundle.main.infoDictionary
        guard let appGroupID = infoDictionary?["WireGroupId"] as? String else {
            throw Failure.missingAppGroupID
        }

        let applicationIdentifier = "group.\(appGroupID)"
        let applicationContainer = FileManager.sharedContainerDirectory(
            for: applicationIdentifier
        )

        self.applicationIdentifier = applicationIdentifier
        self.applicationContainer = applicationContainer
    }

    func start(request: UNNotificationRequest) async throws {
        try await processNotificationRequestStep.process(
            request: request
        )
    }

    // MARK: - Children

    var processNotificationRequestStep: any ProcessNotificationRequestStepFactory {
        ProcessNotificationRequestStep(parent: self)
    }
}
