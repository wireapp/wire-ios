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

import UIKit

struct ConversationRootViewModel {

    struct AccessibilityState {
        let navigationBarElementsHidden: Bool
        let conversationElementsHidden: Bool
    }

    func navigationBarHeight(
        isOneOnOneConversation: Bool,
        isConnectedUserFederated: Bool,
        defaultHeight: CGFloat,
        federatedHeight: CGFloat
    ) -> CGFloat {
        isOneOnOneConversation && isConnectedUserFederated ? federatedHeight : defaultHeight
    }

    func shouldRefreshNavigationItems(
        currentStyle: UIUserInterfaceStyle,
        previousStyle: UIUserInterfaceStyle?
    ) -> Bool {
        currentStyle != previousStyle
    }

    func accessibilityState(isConversationVisible: Bool) -> AccessibilityState {
        AccessibilityState(
            navigationBarElementsHidden: !isConversationVisible,
            conversationElementsHidden: !isConversationVisible
        )
    }
}
