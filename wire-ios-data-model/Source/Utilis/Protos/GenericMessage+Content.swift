//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import GenericMessageProtocol

// MARK: - GenericMessage

public extension GenericMessage {
    var hasText: Bool {
        messageData is Text
    }

    var hasConfirmation: Bool {
        messageData is Confirmation
    }

    var hasReaction: Bool {
        messageData is GenericMessageProtocol.Reaction
    }

    var hasAsset: Bool {
        messageData is GenericMessageProtocol.Asset
    }

    var hasClientAction: Bool {
        messageData is ClientAction
    }

    var hasCleared: Bool {
        messageData is Cleared
    }

    var hasLastRead: Bool {
        messageData is LastRead
    }

    var hasKnock: Bool {
        messageData is Knock
    }

    var hasExternal: Bool {
        messageData is External
    }

    var hasAvailability: Bool {
        messageData is GenericMessageProtocol.Availability
    }

    var hasEdited: Bool {
        messageData is MessageEdit
    }

    var hasDeleted: Bool {
        messageData is MessageDelete
    }

    var hasCalling: Bool {
        messageData is Calling
    }

    var hasHidden: Bool {
        messageData is MessageHide
    }

    var hasLocation: Bool {
        messageData is Location
    }

    var hasDataTransfer: Bool {
        messageData is DataTransfer
    }
}

// MARK: - Ephemeral

public extension Ephemeral {
    var hasAsset: Bool {
        messageData is GenericMessageProtocol.Asset
    }

    var hasKnock: Bool {
        messageData is Knock
    }

    var hasLocation: Bool {
        messageData is Location
    }

    var hasText: Bool {
        messageData is Text
    }
}
