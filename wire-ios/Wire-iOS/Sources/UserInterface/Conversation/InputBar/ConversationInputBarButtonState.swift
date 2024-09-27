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
import WireDataModel
import WireSyncEngine

final class ConversationInputBarButtonState {
    // MARK: Internal

    var sendButtonEnabled: Bool {
        let disableSendButton: Bool? = Settings.shared[.sendButtonDisabled]
        return hasText || (disableSendButton == false && !markingDown)
    }

    var sendButtonHidden: Bool {
        editing
    }

    var ephemeralIndicatorButtonHidden: Bool {
        editing || !ephemeral || isEphemeralSendingDisabled
    }

    var ephemeralIndicatorButtonEnabled: Bool {
        !ephemeralIndicatorButtonHidden && !syncedMessageDestructionTimeout && !isEphemeralTimeoutForced
    }

    var ephemeral: Bool {
        guard let timeout = destructionTimeout else { return false }
        return timeout != .none
    }

    func update(
        textLength: Int,
        editing: Bool,
        markingDown: Bool,
        destructionTimeout: MessageDestructionTimeoutValue?,
        mode: ConversationInputBarViewControllerMode,
        syncedMessageDestructionTimeout: Bool,
        isEphemeralSendingDisabled: Bool,
        isEphemeralTimeoutForced: Bool
    ) {
        self.textLength = textLength
        self.editing = editing
        self.markingDown = markingDown
        self.destructionTimeout = destructionTimeout
        self.mode = mode
        self.syncedMessageDestructionTimeout = syncedMessageDestructionTimeout
        self.isEphemeralSendingDisabled = isEphemeralSendingDisabled
        self.isEphemeralTimeoutForced = isEphemeralTimeoutForced
    }

    // MARK: Private

    private var textLength = 0
    private var editing = false
    private var markingDown = false
    private var destructionTimeout: MessageDestructionTimeoutValue?
    private var mode = ConversationInputBarViewControllerMode.textInput
    private var syncedMessageDestructionTimeout = false
    private var isEphemeralSendingDisabled = false
    private var isEphemeralTimeoutForced = false

    private var hasText: Bool {
        textLength != 0
    }
}
