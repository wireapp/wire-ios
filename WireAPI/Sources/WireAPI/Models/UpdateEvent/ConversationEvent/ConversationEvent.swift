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

import Foundation

/// An event concerning conversations.

public enum ConversationEvent: Equatable {

    /// A conversation's access settings were updated.

    case accessUpdate(ConversationAccessUpdateEvent)

    /// A conversation's guest link code was updated.

    case codeUpdate(ConversationCodeUpdateEvent)

    /// A new conversation was created.

    case create(ConversationCreateEvent)

    /// An existing conversation was deleted.

    case delete(ConversationDeleteEvent)

    /// A knock (aka ping) message was added to a conversation.

    case knock

    /// One or more users were added to a conversation.

    case memberJoin

    /// One or more users were removed from a conversation.

    case memberLeave

    /// One or more users have updated metadata in a conversation.

    case memberUpdate

    /// An unencrypted message was added to a conversation.

    case messageAdd

    /// A conversation's self-deleting-message timer was updated.

    case messageTimerUpdate

    /// An MLS message was added to a conversation.

    case mlsMessageAdd

    /// The self user has been added to an MLS group.

    case mlsWelcome

    /// An encrypted Proteus asset message was added to a conversation.

    case proteusAssetAdd

    /// An encrypted Proteus message was added to a conversation.

    case proteusMessageAdd

    /// A conversation's message protocol was updated.

    case protocolUpdate

    /// A conversation's read receipt mode was updated.

    case receiptModeUpdate

    /// A conversation's name was updated.

    case rename

    /// One or more users are typing in a conversation.

    case typing

}
