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

import WireDataModel
import WireMainNavigation
import WireSettings

final class AnyMainCoordinator<Dependencies: WireMainNavigation.MainCoordinatorDependencies>: MainCoordinatorProtocol {

    let mainCoordinator: any MainCoordinatorProtocol

    private let _showConversationList: @MainActor (Dependencies.ConversationFilter?) async -> Void
    private let _showConversation: @MainActor (ConversationModel, ConversationMessageModel?) async -> Void
    private let _showSettingsContent: @MainActor (Dependencies.SettingsTopLevelMenuItem) -> Void
    private let _showUserProfile: @MainActor (User) async -> Void

    init<MainCoordinator: MainCoordinatorProtocol>(mainCoordinator: MainCoordinator) where
    MainCoordinator.Dependencies == Dependencies {

        self.mainCoordinator = mainCoordinator

        _showConversationList = { conversationFilter in
            let conversationFilter = conversationFilter.map { MainCoordinator.ConversationFilter(mappingFrom: $0) }
            await mainCoordinator.showConversationList(conversationFilter: conversationFilter)
        }
        _showConversation = { conversation, message in
            await mainCoordinator.showConversation(conversation: conversation, message: message)
        }
        _showSettingsContent = { topLevelMenuItem in
            let topLevelMenuItem = MainCoordinator.SettingsTopLevelMenuItem(mappingFrom: topLevelMenuItem)
            mainCoordinator.showSettingsContent(topLevelMenuItem)
        }
        _showUserProfile = { user in
            await mainCoordinator.showUserProfile(user: user)
        }
    }

    @MainActor
    func showConversationList(conversationFilter: Dependencies.ConversationFilter?) async {
        await _showConversationList(conversationFilter)
    }

    @MainActor
    func showArchive() async {
        await mainCoordinator.showArchive()
    }

    @MainActor
    func showSettings() async {
        await mainCoordinator.showSettings()
    }

    @MainActor
    func showConversation(conversation: ConversationModel, message: ConversationMessageModel?) async {
        await _showConversation(conversation, message)
    }

    @MainActor
    func hideConversation() {
        mainCoordinator.hideConversation()
    }

    @MainActor
    func showSettingsContent(_ topLevelMenuItem: Dependencies.SettingsTopLevelMenuItem) {
        _showSettingsContent(topLevelMenuItem)
    }

    @MainActor
    func hideSettingsContent() {
        mainCoordinator.hideSettingsContent()
    }

    @MainActor
    func showSelfProfile() async {
        await mainCoordinator.showSelfProfile()
    }

    @MainActor
    func showUserProfile(user: User) async {
        await _showUserProfile(user)
    }

    @MainActor
    func showConnect() async {
        await mainCoordinator.showConnect()
    }

    @MainActor
    func showCreateGroupConversation() async {
        await mainCoordinator.showCreateGroupConversation()
    }

    @MainActor
    func presentViewController(_ viewController: UIViewController) async {
        await mainCoordinator.presentViewController(viewController)
    }

    @MainActor
    func dismissPresentedViewController() async {
        await mainCoordinator.dismissPresentedViewController()
    }
}
