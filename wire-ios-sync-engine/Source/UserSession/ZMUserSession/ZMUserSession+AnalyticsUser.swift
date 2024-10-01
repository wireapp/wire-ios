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

import Foundation
import WireAnalytics
import WireDataModel

extension ZMUserSession {

    var analyticsUser: AnalyticsUser {
        let selfUser = ZMUser.selfUser(inUserSession: self)
        let analyticsID: String
        var teamInfo: TeamInfo?

        if let existingID = selfUser.analyticsIdentifier {
            analyticsID = existingID
        } else {
            let newID = UUID()
            analyticsID = newID.transportString()
            selfUser.analyticsIdentifier = analyticsID

            syncContext.performGroupedBlock { [syncContext] in
                do {
                    let message = DataTransfer(trackingIdentifier: newID)
                    try ZMConversation.sendMessageToSelfClients(message, in: syncContext)
                } catch let error {
                    WireLogger.analytics.error("Failed to broadcast new analytics ID: \(newID.safeForLoggingDescription) \(error)")
                }
            }
        }

        if let team = selfUser.team, let teamID = team.remoteIdentifier {
            teamInfo = TeamInfo(
                id: teamID.uuidString,
                role: selfUser.teamRole.analyticsValue,
                size: UInt(team.members.count)
            )
        }

        return AnalyticsUser(
            analyticsIdentifier: analyticsID,
            teamInfo: teamInfo
        )
    }

}
