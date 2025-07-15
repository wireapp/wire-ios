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
import WireAnalytics
import WireDataModel
import WireLogging

extension ZMUserSession: AnalyticsEventTrackerProvider {

    enum AnalyticsError: Error {

        case selfClientIsNotRegistered
        case failedToBroadcastAnalyticsID(any Error)

    }

    func createAnalyticsUser() async throws -> AnalyticsUser {
        let (trackingID, teamInfo) = try await syncContext.perform { [syncContext] in
            let selfUser = ZMUser.selfUser(in: syncContext)

            // Sanity check that we don't setup analytics too early.
            guard selfUser.selfClient()?.remoteIdentifier != nil else {
                throw AnalyticsError.selfClientIsNotRegistered
            }

            let trackingID: String
            var teamInfo: TeamInfo?

            if let existingID = selfUser.trackingID {
                trackingID = existingID
            } else {
                trackingID = UUID().transportString()
                try self.broadcastTrackingID(trackingID)
                selfUser.trackingID = trackingID
            }

            if let team = selfUser.team, let teamID = team.remoteIdentifier {
                teamInfo = TeamInfo(
                    id: teamID.uuidString,
                    role: selfUser.teamRole.analyticsValue,
                    size: UInt(team.members.count)
                )
            }

            return (trackingID, teamInfo)
        }

        return AnalyticsUser(
            trackingID: trackingID,
            teamInfo: teamInfo
        )
    }

    private func broadcastTrackingID(_ trackingID: String) throws {
        do {
            WireLogger.analytics.debug("broadcasting new analytics id")
            let message = DataTransfer(trackingIdentifier: trackingID)
            try ZMConversation.sendMessageToSelfClients(message, in: syncContext)
        } catch {
            throw AnalyticsError.failedToBroadcastAnalyticsID(error)
        }
    }

}
