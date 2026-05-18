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
import WireLogging

final class TeamMemberDiscoveryAgent: TeamMemberDiscoveryAgentProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - TeamMemberDiscoveryAgentProtocol

    public func discoverMembers() async {
        // TODO: WPB-24947 — use teamsAPI.getNotifications(sinceNotificationID:)
        // to fetch recent team notifications, then extract & apply
        // `team.member-join` events to discover all team members
        // (works around the 2000-member cap on the legacy bulk endpoint).
        WireLogger.sync.debug("team member discovery: not implemented yet")
    }

}
