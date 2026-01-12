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

import Foundation
import NeedleFoundation
import UserNotifications
import WireDataModel

protocol ShowNotificationDependency: Dependency {
    var contentHandler: (UNNotificationContent) -> Void { get }
    var accountManager: AccountManager { get }
    var selectedAccount: Account { get }
    var conversationLocalStore: any ConversationLocalStoreProtocol { get }
    var databaseSaver: any DatabaseSaverProtocol { get }
}

protocol ShowNotificationStepProtocol {
    func showNotifications(
        _ notifications: [UserNotification]
    ) async throws
}

final class ShowNotificationStep: Component<ShowNotificationDependency>, ShowNotificationStepProtocol {

    func showNotifications(
        _ notifications: [UserNotification]
    ) async throws {
        let showNotificationUseCase = ShowNotificationUseCase(
            contentHandler: dependency.contentHandler,
            conversationLocalStore: dependency.conversationLocalStore,
            selectedAccount: dependency.selectedAccount,
            accountManager: dependency.accountManager,
            databaseSaver: dependency.databaseSaver
        )

        try await showNotificationUseCase.invoke(
            userNotifications: notifications
        )
    }
}
