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
    associatedtype ConversationBuilder: MainConversationBuilderProtocol
    associatedtype SettingsContentBuilder: MainSettingsContentBuilderProtocol

    @MainActor
    func showConversationList(conversationFilter: ConversationList.ConversationFilter?)
    @MainActor
    func showArchive()
    @MainActor
    func showSettings()

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
    func showSelfProfile()
    @MainActor
    func showConnect()
}
