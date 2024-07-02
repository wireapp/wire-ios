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

import WireUtilities

// TODO: instead of conformance to protocol wrap in new type which caches the normalization results
extension ZMConversation: SearchableConversation {

    public var searchableName: String {
        normalizedUserDefinedName ?? displayName?.normalizedForSearch() as String? ?? ""
    }

    public var searchableParticipants: [ZMConversationSearchableParticipant] {
        localParticipants
            .map { localParticipant in
                .init(searchableName: localParticipant.normalizedName ?? localParticipant.name?.normalizedForSearch() as String? ?? "")
            }
    }

    // MARK: - Nested Types

    public struct ZMConversationSearchableParticipant: SearchableConversationParticipant {
        public var searchableName: String
    }
}
