//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public enum ConversationCellModel: Hashable, Sendable {

    /// Info text for the user to tell that guests are allowed in the conversation.
    case guestsAllowed(GuestsAllowedModel)

    /// Used to group messages.
    case timeDivider(TimeDividerModel)

    /// Used to present any kind of system generated messages.
    case systemMessage(SystemMessageModel)

    // TODO: add missing cases
    // ping: sender, ephemeral progress+time left, isObfuscated, (accessibilityLabel, accessibilityIdentifier)
    // composite: ?
    // simpleTextMessage: sender optional, isSenderCollapsed, attributedText, time, reactions, isObfuscated, ephemeral, edited, seen, isCollapsed
    // extendedTextMessage: simpleTextMessage, quotedMessage, link attachments, link previews, error status
    // collapsedMessage: collapse-icon, ? wrapped message or several types of collapsed messages?
    // location: sender, time, reactions, isObfuscated, ephemeral, isCollapsed
    // audio, video, file: sender, time, reactions, canBeShared?, isCollapsed
    // typing: name(s)
    // TODO: isObfuscated? attribute or separate cell/model?
    // TODO: actions?
    // TODO: deleted message
    // sender contains name, image, availability, accent color, icon (e.g. guest)
    // status delivered? edited? seen?

    // case ?Message

}
