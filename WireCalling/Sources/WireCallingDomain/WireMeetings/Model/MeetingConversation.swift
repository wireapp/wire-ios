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

public import Foundation
public import WireFoundation

/// The conversation backing a ``Meeting``, along with its participants.
///
/// Mirrors the Wire Drive `WireDriveConversation` shape: a conversation identifier
/// plus the set of members participating in it. It is resolved from the locally
/// stored conversation when a meeting is fetched, so the UI can show participant
/// avatars without an additional lookup.
public struct MeetingConversation: Equatable, Sendable {

    public let id: QualifiedID

    public let participants: Set<MeetingMember>

    public init(
        id: QualifiedID,
        participants: Set<MeetingMember>
    ) {
        self.id = id
        self.participants = participants
    }

}
