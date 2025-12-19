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
import WireDataModel

/// Uniquely identifies a message's cached section controller.
///
/// The identifier includes both the message's nonce (stable identity) and delivery state
/// (transient state) to ensure proper cache invalidation when delivery state changes.
///
/// When a message's delivery state changes (e.g., from `.pending` to `.sent`), the identifier
/// changes. This is used to force a cache miss and recreation of the section controller
/// with updated cell descriptions and prevents the UI from showing stale delivery states.
/// (see `ConversationTableViewDataSource`)
///
struct MessageCacheIdentifier: Hashable {
    let nonce: UUID
    let deliveryState: ZMDeliveryState

    init(nonce: UUID, deliveryState: ZMDeliveryState) {
        self.nonce = nonce
        self.deliveryState = deliveryState
    }

    /// Convenience initializer from a message
    /// Returns nil if the message has no nonce

    init?(message: ZMConversationMessage) {
        guard let nonce = message.nonce else { return nil }
        self.nonce = nonce
        self.deliveryState = message.deliveryState
    }
}
