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

// sourcery: AutoMockable
public protocol ConversationCreationRepositoryProtocol {

    /// Legacy services (bots) are deprecated and cannot be set up any more. However, teams who have bots already set up
    /// may continue using them.
    /// While the `apps` feature flag controls if the UI allows for starting a conversation with an app (new-style
    /// MLS-only service) or adding an app to a conversation, there is no feature flag for bots (old-style Proteus-only
    /// services). If there are bots already added to the team, bots are considered enabled.

    func areBotsSetUpInTheTeam() async throws -> Bool

}
