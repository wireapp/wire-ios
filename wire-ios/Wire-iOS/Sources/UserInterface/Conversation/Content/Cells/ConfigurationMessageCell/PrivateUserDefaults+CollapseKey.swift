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

import Foundation
import WireFoundation

extension PrivateUserDefaults where Key == CollapseKey {
    
    func wasMessagedUncollapsedBefore(nonce: String?) -> Bool {
        guard let nonce, let uncollapsedMessages = stringArray(forKey: .uncollapsedMessages) else {
            return false
        }
        return uncollapsedMessages.contains(nonce)
    }
    
    func removeWasUncollapsed(_ message: ConversationMessage) {
        guard !message.isText,
            let nonce = message.nonce?.uuidString else { return }
        var uncollapsedMessages: [String] = stringArray(forKey: .uncollapsedMessages) ?? []
        if let index = uncollapsedMessages.firstIndex(of: nonce) {
            uncollapsedMessages.remove(at: index)
        }
        set(uncollapsedMessages, forKey: .uncollapsedMessages)
    }
    
    func saveWasUncollapsed(_ message: ConversationMessage) {
        guard !message.isText,
            let nonce = message.nonce?.uuidString else { return }
        var uncollapsedMessages: [String] = stringArray(forKey: .uncollapsedMessages) ?? []
        uncollapsedMessages.append(nonce)
        set(uncollapsedMessages, forKey: .uncollapsedMessages)
    }
}
