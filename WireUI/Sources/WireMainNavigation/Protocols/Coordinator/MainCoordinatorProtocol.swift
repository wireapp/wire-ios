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
    associatedtype ConversationBuilder: MainConversationBuilderProtocol
    associatedtype Settings: MainSettingsProtocol
    associatedtype SettingsContent: MainSettingsContentProtocol

    /// Make the conversation list visible. Don't show any conversation content.
    func showConversationList(
        conversationFilter: ConversationList.ConversationFilter?
    ) async

    /// In the expanded split view layout make the conversation list visible and show the conversation with the provided id.
    /// In collapsed layout show the conversation content.
//    func showConversationList(
//        conversationFilter: ConversationList.ConversationFilter?,
//        conversationID: ConversationList.ConversationID?
//    ) async

    /// In the expanded split view layout make the conversation list visible and show the conversation with the provided id and scroll to the message with the provided id.
    /// In collapsed layout show the conversation content and scroll to the message with the provided id.
//    func showConversationList(
//        conversationFilter: ConversationList.ConversationFilter?,
//        conversationID: ConversationList.ConversationID?,
//        messageID: ConversationList.MessageID?
//    ) async

    func showConversation(conversationID: ConversationList.ConversationID) async
    @MainActor
    func hideConversation()

    func showArchivedConversations() async // TODO: rename showArchive

    /// Present the app settings at the specified content.
    ///
    /// In expanded layout this method presents the main settings menu in the supplementary column.
    /// If a non-nil `content` argument is provided, additionally the specified settings content is displayed
    /// in th secondary column.
    ///
    /// In collapsed layout when `content` is nil, this method presents the main settings menu.
    /// If `content` is non-nil, this method presents the main settings and navigates into the settings content.
    @MainActor
    func showSettings(content: SettingsContent.SettingsContent?)
    @MainActor
    func hideSettingsContent()

    func showSelfProfile() async
    func showConnect() async
}
