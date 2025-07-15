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
import WireFoundation
import WireLogging

extension ZMUserSession: AnalyticsEventTrackerProvider {

    enum AnalyticsError: Error {

        case selfClientIsNotRegistered
        case failedToBroadcastAnalyticsID(any Error)

    }

    func createAnalyticsUser() async throws -> AnalyticsUser {
        let (analyticsID, teamInfo): (String, TeamInfo?) = try await syncContext.perform { [syncContext] in
            let selfUser = ZMUser.selfUser(in: syncContext)

            // Sanity check that we don't setup analytics too early.
            guard let userID = selfUser.selfClient()?.remoteIdentifier.flatMap(UUID.init(uuidString:)) else {
                throw AnalyticsError.selfClientIsNotRegistered
            }

            let analyticsID: String
            var teamInfo: TeamInfo?

            let analyticsIDFromRegistration = PrivateUserDefaults<AnalyticsUserIDDefaultsKey>(
                userID: userID,
                storage: UserDefaults.standard
            ).object(forKey: .analyticsIDFromRegistration) as? String
            if let existingID = selfUser.analyticsIdentifier {
                analyticsID = existingID
            } else if let analyticsIDFromRegistration {
                analyticsID = analyticsIDFromRegistration
                if let analyticsUUID = UUID(uuidString: analyticsIDFromRegistration) {
                    try self.broadcastAnalyticsID(analyticsUUID)
                }
                selfUser.analyticsIdentifier = analyticsID
            } else {
                let newID = UUID()
                analyticsID = newID.transportString()
                try self.broadcastAnalyticsID(newID)
                selfUser.analyticsIdentifier = analyticsID
            }

            if let team = selfUser.team, let teamID = team.remoteIdentifier {
                teamInfo = TeamInfo(
                    id: teamID.uuidString,
                    role: selfUser.teamRole.analyticsValue,
                    size: UInt(team.members.count)
                )
            }

            return (analyticsID, teamInfo)
        }

        return AnalyticsUser(
            analyticsIdentifier: analyticsID,
            teamInfo: teamInfo
        )
    }

    private func broadcastAnalyticsID(_ id: UUID) throws {
        do {
            WireLogger.analytics.debug("broadcasting new analytics id")
            let message = DataTransfer(trackingIdentifier: id)
            try ZMConversation.sendMessageToSelfClients(message, in: syncContext)
        } catch {
            throw AnalyticsError.failedToBroadcastAnalyticsID(error)
        }
    }

}

// MARK: -

/// If the user went through the flow of registering a new personal account and gave consent to analytics tracking,
/// the newly created analytics id is temporarily stored in this property. After setting up the user session this
/// property will be cleared and the value stored in the database under `ZMUser.analyticsIdentifier` property.

private enum AnalyticsUserIDDefaultsKey: String, DefaultsKey {
    case analyticsIDFromRegistration
}
