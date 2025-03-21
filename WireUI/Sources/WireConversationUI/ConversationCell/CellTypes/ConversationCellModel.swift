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
    case guestsAllowedInfo(GuestsAllowedInfoModel)

    /// Used to group messages.
    case timeDivider(TimeDividerModel)

    /// Used to present any kind of system generated messages.
    case systemMessage(SystemMessageModel)

    /// todo
    case ping(PingModel)

    /// todo
    case collapsedMessage(CollapsedMessageModel)

    /// todo
    case compositeMessage(CompositeMessageModel)

    /// todo
    case simpleTextMessage(SimpleTextMessageModel)

    /// todo
    case extendedTextMessage(ExtendedTextMessageModel)

    /// todo
    // case audioMessage(AudioMessageModel)

    /// todo
    // case videoMessage(VideoMessageModel)

    /// todo
    // case fileMessage(FileMessageModel)

    /// todo
    // case location(LocationModel)

    /// Placeholder for deleted messages.
    case deletedMessage(DeletedMessageModel)

    // TODO: add missing cases
    // location: sender, time, reactions, isObfuscated, ephemeral, isCollapsed
    // audio, video, file: sender, time, reactions, canBeShared?, isCollapsed
    // TODO: isObfuscated? attribute or separate cell/model?
    // TODO: actions?
    // TODO: deleted message
    // TODO: extended message with generic content? (link attachment, link preview, audio, video, file, location)
    // TODO: message status: delivered? edited? seen?

}

public typealias TODO = Int
public typealias AudioMessageModel = TODO
public typealias VideoMessageModel = TODO
public typealias FileMessageModel = TODO
public typealias LocationModel = TODO
