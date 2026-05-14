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

struct ShareExtensionViewModel {

    struct ContentValidationDisplayState {
        let charactersRemaining: NSNumber?
        let isPostEnabled: Bool
    }

    private let maximumMessageLength: Int
    private let remainingCharactersThreshold: Int

    init(
        maximumMessageLength: Int = 8000,
        remainingCharactersThreshold: Int = 30
    ) {
        self.maximumMessageLength = maximumMessageLength
        self.remainingCharactersThreshold = remainingCharactersThreshold
    }

    func accountValue(displayName: String?) -> String {
        displayName ?? L10n.ShareExtension.ConversationSelection.Empty.value
    }

    func conversationValue(name: String?) -> String {
        name ?? L10n.ShareExtension.ConversationSelection.Empty.value
    }

    func contentValidationDisplayState(
        text: String,
        hasSharingSession: Bool,
        hasTargetConversation: Bool
    ) -> ContentValidationDisplayState {
        let textLength = text.trimmingCharacters(in: .whitespaces).count
        let remaining = maximumMessageLength - textLength
        let charactersRemaining: NSNumber? = if remaining <= remainingCharactersThreshold {
            remaining as NSNumber
        } else {
            nil
        }
        let hasRequiredState = hasSharingSession && hasTargetConversation
        let isWithinCharacterLimit = charactersRemaining.map { $0.intValue >= 0 } ?? true

        return ContentValidationDisplayState(
            charactersRemaining: charactersRemaining,
            isPostEnabled: hasRequiredState && isWithinCharacterLimit
        )
    }
}
