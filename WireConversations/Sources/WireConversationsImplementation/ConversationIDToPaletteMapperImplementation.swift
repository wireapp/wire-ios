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

import WireConversationsAPI
package import WireConversationsResources

package final class ConversationIDToIconMapper: ConversationIDToPaletteMapper {

    let palette: [WireConversationGroupIconAsset] = .all

    package init() {}

    package func palette(for conversationID: String) -> WireConversationGroupIconAsset {
        // Calculate the combined hash
        let hashValue = stringHashCode(conversationID)
        // Convert to positive Int for indexing
        let index = abs(Int(hashValue)) % palette.count
        return palette[index]
    }
}
