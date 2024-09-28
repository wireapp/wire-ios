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

public protocol MainCoordinatorProtocol: AnyObject {
    associatedtype ConversationList: MainConversationListProtocol

    /// Make the conversation list visible. Don't show any conversation content.
    func showConversationList(
        conversationFilter: ConversationList.ConversationFilter?
    ) async

    /// In the expanded split view layout make the conversation list visible and show the conversation with the provided id.
    /// In collapsed layout show the conversation content.
    func showConversationList(
        conversationFilter: ConversationList.ConversationFilter?,
        conversationID: ConversationList.ConversationID?
    ) async

    /// In the expanded split view layout make the conversation list visible and show the conversation with the provided id and scroll to the message with the provided id.
    /// In collapsed layout show the conversation content and scroll to the message with the provided id.
    func showConversationList(
        conversationFilter: ConversationList.ConversationFilter?,
        conversationID: ConversationList.ConversationID?,
        messageID: ConversationList.MessageID?
    ) async

    func showArchivedConversations() async
    func showSettings<SettingsContent: MainSettingsContentRepresentable>(content: SettingsContent?) async
    // func showSettings() async

    func showSelfProfile() async
    func showConnect() async
}

// TODO: remove
/*
public extension MainCoordinatorProtocol {

    func showConversationList(
        conversationFilter: ConversationList.ConversationFilter?
    ) async {
        await showConversationList(
            conversationFilter: conversationFilter,
            conversationID: .none
        )
    }

    func showConversationList(
        conversationFilter: ConversationList.ConversationFilter?,
        conversationID: ConversationList.ConversationID?
    ) async {
        await showConversationList(
            conversationFilter: conversationFilter,
            conversationID: conversationID,
            messageID: .none
        )
    }

    // func showSettings() async {
    //     await showSettings(content: .none)
    // }
}
 */
