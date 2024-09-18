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

/// Handles the navigation when a user is authenticated.
public protocol MainCoordinatorProtocol: AnyObject {

    /// Show the conversation list keeping the selected conversation filter as is.
    func showConversationList() async
    /// Show the conversation list and change the filter setting to some or none.
    //func showConversationList(conversationFilter: Int?) async // TODO: add associated type?
    func showArchivedConversations() async
    func showSelfProfile() async
    func showSettings() async

//    func openConversation(
//        _ conversation: ZMConversation,
//        focusOnView focus: Bool,
//        animated: Bool
//    )
//
//    func openConversation<Message>(
//        _ conversation: ZMConversation,
//        scrollTo message: Message,
//        focusOnView focus: Bool,
//        animated: Bool
//    ) where Message: ZMConversationMessage
//
//    func showConversationList()
}
