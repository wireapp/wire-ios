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
        return messageData is Text
    }

    public var hasConfirmation: Bool {
        return messageData is Confirmation
    }

    public var hasReaction: Bool {
        return messageData is WireProtos.Reaction
    }

    public var hasAsset: Bool {
        return messageData is WireProtos.Asset
    }

    public var hasClientAction: Bool {
        return messageData is ClientAction
    }

    public var hasCleared: Bool {
        return messageData is Cleared
    }

    public var hasLastRead: Bool {
        return messageData is LastRead
    }

    public var hasKnock: Bool {
        return messageData is Knock
    }

    public var hasExternal: Bool {
        return messageData is External
    }

    public var hasAvailability: Bool {
        return messageData is WireProtos.Availability
    }

    public var hasEdited: Bool {
        return messageData is MessageEdit
    }

    public var hasDeleted: Bool {
        return messageData is MessageDelete
    }

    public var hasCalling: Bool {
        return messageData is Calling
    }

    public var hasHidden: Bool {
        return messageData is MessageHide
    }

    public var hasLocation: Bool {
        return messageData is Location
    }

    public var hasDataTransfer: Bool {
        return messageData is DataTransfer
    }
}

// MARK: - Ephemeral

extension Ephemeral {
    public var hasAsset: Bool {
        return messageData is WireProtos.Asset
    }

    public var hasKnock: Bool {
        return messageData is Knock
    }

    public var hasLocation: Bool {
        return messageData is Location
    }

    public var hasText: Bool {
        return messageData is Text
    }
}
