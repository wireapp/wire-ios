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

import UIKit

public protocol MainCoordinatorProtocol: AnyObject {

    associatedtype Dependencies: MainCoordinatorProtocolDependencies

    typealias ConversationFilter = Dependencies.ConversationFilter
    typealias ConversationModel = Dependencies.ConversationModel
    typealias ConversationMessageModel = Dependencies.ConversationMessageModel
    typealias SettingsTopLevelMenuItem = Dependencies.SettingsTopLevelMenuItem

    @MainActor
    func showConversationList(conversationFilter: ConversationFilter?) async
    @MainActor
    func showArchive() async
    @MainActor
    func showSettings() async

    @MainActor
    func showConversation(conversation: ConversationModel, message: ConversationMessageModel?) async
    /// This method will be called by the custom back button in the conversation content screen.
    @MainActor
    func hideConversation()

    @MainActor
    func showSettingsContent(_ topLevelMenuItem: SettingsTopLevelMenuItem)
    @MainActor
    func hideSettingsContent()

    @MainActor
    func presentViewController(_ viewController: UIViewController) async
    @MainActor
    func dismissPresentedViewController() async

    // TODO: [WPB-11651] Move theses methods out of the protocol. The `presentViewController(_:)` method should be used.

    @MainActor
    func showConnect() async
    @MainActor
    func showCreateGroupConversation() async
}
