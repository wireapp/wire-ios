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
import UserNotifications
import WireDataModel

protocol ProcessNotificationRequestDependency: Dependency {
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
        ).verifyUserSession()
    }

    func verifyUserStep(
        userID: UUID,
        eventID: UUID
    ) throws -> VerifyUserStep {
        let accountManager = AccountManager(
            sharedDirectory: dependency.applicationContainer
        )

        return try VerifyUserStep(
            parent: self,
            userID: userID,
            eventID: eventID,
            accountManager: accountManager
        )
    }

}
