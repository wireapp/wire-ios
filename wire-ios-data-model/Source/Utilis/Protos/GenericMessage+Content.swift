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

// MARK: - GenericMessage

extension GenericMessage {
    public var hasText: Bool {
        messageData is Text
    }

    public var hasConfirmation: Bool {
        messageData is Confirmation
    }

    public var hasReaction: Bool {
        messageData is WireProtos.Reaction
    }

    public var hasAsset: Bool {
        messageData is WireProtos.Asset
    }

    public var hasClientAction: Bool {
        messageData is ClientAction
    }

    public var hasCleared: Bool {
        messageData is Cleared
    }

    public var hasLastRead: Bool {
        messageData is LastRead
    }

    public var hasKnock: Bool {
        messageData is Knock
    }

    public var hasExternal: Bool {
        messageData is External
    }

    public var hasAvailability: Bool {
        messageData is WireProtos.Availability
    }

    public var hasEdited: Bool {
        messageData is MessageEdit
    }

    public var hasDeleted: Bool {
        messageData is MessageDelete
    }

    public var hasCalling: Bool {
        messageData is Calling
    }

    public var hasHidden: Bool {
        messageData is MessageHide
    }

    public var hasLocation: Bool {
        messageData is Location
    }

    public var hasDataTransfer: Bool {
        messageData is DataTransfer
    }
}

// MARK: - Ephemeral

extension Ephemeral {
    public var hasAsset: Bool {
        messageData is WireProtos.Asset
    }

    public var hasKnock: Bool {
        messageData is Knock
    }

    public var hasLocation: Bool {
        messageData is Location
    }

    public var hasText: Bool {
        messageData is Text
    }
}
