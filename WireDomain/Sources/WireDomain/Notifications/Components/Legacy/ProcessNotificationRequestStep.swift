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

// TODO: [WPB-19818] delete when multibackend is released

import NeedleFoundation
import UserNotifications
import WireDataModel

protocol ProcessNotificationRequestDependency: Dependency {
    var currentAppVersion: String { get }
    var applicationContainer: URL { get }
}

protocol ProcessNotificationRequestStepProtocol {
    func process(
        request: UNNotificationRequest
    ) async throws
}

final class ProcessNotificationRequestStep: Component<ProcessNotificationRequestDependency>,
    ProcessNotificationRequestStepProtocol {

    func process(
        request: UNNotificationRequest
    ) async throws {
        let processNotificationUseCase = ProcessNotificationRequestUseCase()
        let payload = try await processNotificationUseCase.invoke(request: request)

        try await verifyUserStep(
            userID: payload.userID,
            eventID: payload.eventID
        )
        .verifyUserSession()
    }

    func verifyUserStep(
        userID: UUID,
        eventID: UUID
    ) throws -> VerifyUserStep {
        let accountURLs = AccountURLs(root: dependency.applicationContainer)
        let accountManager = try AccountManager(
            currentAppVersion: dependency.currentAppVersion,
            directory: accountURLs.accounts
        )

        return try VerifyUserStep(
            parent: self,
            userID: userID,
            eventID: eventID,
            accountManager: accountManager
        )
    }

}
