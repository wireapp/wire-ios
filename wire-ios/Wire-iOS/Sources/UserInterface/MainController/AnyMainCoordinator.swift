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

import WireMainNavigation
import WireDataModel
import WireSettings

@MainActor
final class AnyMainCoordinator<MainCoordinator: MainCoordinatorProtocol>: MainCoordinatorProtocol {

    typealias ConversationFilter = MainCoordinator.ConversationList.ConversationFilter
    typealias ConversationList = MainCoordinator.ConversationList
    typealias SettingsContentBuilder = MainCoordinator.SettingsContentBuilder
    typealias ConversationModel = MainCoordinator.ConversationModel
    typealias ConversationMessageModel = MainCoordinator.ConversationMessageModel
    typealias User = MainCoordinator.User
    typealias TopLevelMenuItem = MainCoordinator.SettingsContentBuilder.TopLevelMenuItem

    let mainCoordinator: MainCoordinator

    init(mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
    }

    func showConversationList(conversationFilter: ConversationFilter?) async {
        await mainCoordinator.showConversationList(conversationFilter: conversationFilter)
    }
    
    func showArchive() async {
        await mainCoordinator.showArchive()
    }
    
    func showSettings() async {
        await mainCoordinator.showSettings()
    }
    
    func showConversation(conversation: ConversationModel, message: ConversationMessageModel?) async {
        await mainCoordinator.showConversation(conversation: conversation, message: message)
    }
    
    func hideConversation() {
        mainCoordinator.hideConversation()
    }
    
    func showSettingsContent(_ topLevelMenuItem: TopLevelMenuItem) {
        mainCoordinator.showSettingsContent(topLevelMenuItem)
    }
    
    func hideSettingsContent() {
        mainCoordinator.hideSettingsContent()
    }
    
    func showSelfProfile() async {
        await mainCoordinator.showSelfProfile()
    }
    
    func showUserProfile(user: User) async {
        await mainCoordinator.showUserProfile(user: user)
    }
    
    func showConnect() async {
        await mainCoordinator.showConnect()
    }
    
    func presentViewController(_ viewController: UIViewController) async {
        await mainCoordinator.presentViewController(viewController)
    }
}
