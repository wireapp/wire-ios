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

import WireAPI
import WireDataModel

/// Process team member leave events.
struct TeamMemberLeaveEventProcessor: TeamEventProcessorProtocol {

    enum Error: Swift.Error {
        case failedToFetchUser(UUID)
        case userNotAMemberInTeam(user: UUID, team: UUID)
    }

    let event: TeamMemberLeaveEvent
    let context: NSManagedObjectContext

    func processTeamEvent() async throws {
        try await context.perform {
            guard let user = ZMUser.fetch(with: event.userID, in: context) else {
                throw Error.failedToFetchUser(event.userID)
            }

            guard let member = user.membership else {
                throw Error.userNotAMemberInTeam(user: event.userID, team: event.teamID)
            }

            if user.isSelfUser {
                let notification = AccountDeletedNotification(context: context)
                notification.post(in: context.notificationContext)
            } else {
                user.markAccountAsDeleted(at: .now)
            }

            context.delete(member)
        }
    }

}
