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

    associatedtype ConversationList: MainConversationListProtocol
    associatedtype ConversationBuilder: MainConversationBuilderProtocol // TODO: remove if not needed here
    associatedtype SettingsContentBuilder: MainSettingsContentBuilderProtocol
    associatedtype UserProfileBuilder: MainUserProfileBuilderProtocol // TODO: instead a general present method could be offered (UIViewController), the actual preparatino could be done in some sub-coordinator
    associatedtype UserID: Sendable

    @MainActor
    func showConversationList(conversationFilter: ConversationList.ConversationFilter?) async
    @MainActor
    func showArchive() async
    @MainActor
    func showSettings() async

    @MainActor
    func showConversation(conversationID: ConversationList.ConversationID) async
    /// This method will be called by the custom back button in the conversation content screen.
    @MainActor
    func hideConversation()

    @MainActor
    func showSettingsContent(_ topLevelMenuItem: SettingsContentBuilder.TopLevelMenuItem)
    @MainActor
    func hideSettingsContent()

    @MainActor
    func showSelfProfile() async
    @MainActor
    func showUserProfile(userID: UserID) async
    @MainActor
    func showConnect() async

    @MainActor
    func presentViewController(_ viewController: UIViewController) async
}
