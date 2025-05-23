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

public import WireConversationsAPI
/*package*/ public import WireConversationsResources

/*package*/ public final class ConversationIDToChannelIconMapper: ConversationIDToPaletteMapper {

    let palette: [WireConversationChannelIconAsset] = WireConversationChannelIconAsset.all

    /*package*/ public init() {}

    /*package*/ public func palette(for conversationID: String) -> WireConversationChannelIconAsset {
        // make sure id is lowercased
        let id = conversationID.lowercased()
        // Calculate the combined hash
        let hashValue = stringHashCode(id)
        // Convert to positive Int for indexing
        let index = abs(Int(hashValue)) % palette.count
        return palette[index]
    }
}
