//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

public protocol SettingsCoordinatorProtocol: AnyObject {
    @MainActor
    func showSettings(content: SettingsTopLevelContent)
}

public extension SettingsCoordinatorProtocol {
//    func showConversation<ConversationID: Sendable>(conversationID: ConversationID) async {
//        showConversation(conversationID: conversationID, messageID: nil)
//    }
}

@MainActor
public final class AnySettingsCoordinator: SettingsCoordinatorProtocol {

    private let showSettings: (_ content: SettingsTopLevelContent) -> Void

    public init<SettingsCoordinator: SettingsCoordinatorProtocol>(
        settingsCoordinator: SettingsCoordinator
    ) {
        showSettings = settingsCoordinator.showSettings
    }

    public func showSettings(content: SettingsTopLevelContent) {
        showSettings(content)
    }
}
