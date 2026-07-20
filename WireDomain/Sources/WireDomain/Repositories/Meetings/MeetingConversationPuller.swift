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
import WireCallingData

/// Bridges `WireDomain`'s `ConversationRepositoryProtocol` into `WireCallingData`'s
/// `MeetingConversationPullerProtocol`, so the meeting repository can pull meeting
/// conversations it doesn't know yet without depending on `WireDomain` directly.
struct MeetingConversationPuller: MeetingConversationPullerProtocol {

    let conversationRepository: any ConversationRepositoryProtocol

    func pullConversationIfUnknown(id: UUID, domain: String) async throws {
        guard await conversationRepository.fetchConversation(id: id, domain: domain) == nil else { return }

        try await conversationRepository.pullConversation(id: id, domain: domain)
    }

}
