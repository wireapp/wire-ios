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

public struct AnalyticsIdentifierProvider {
    // MARK: Lifecycle

    public init(selfUser: UserType) {
        self.selfUser = selfUser
    }

    // MARK: Public

    public var selfUser: UserType

    public func setIdentifierIfNeeded() {
        guard let user = selfUser as? ZMUser, user.analyticsIdentifier == nil else { return }

        let newId = UUID()
        setAnalytics(identifier: newId, forSelfUser: user)
    }

    // MARK: Internal

    func setAnalytics(identifier: UUID, forSelfUser user: ZMUser) {
        guard user.isSelfUser, user.isTeamMember else { return }

        user.analyticsIdentifier = identifier.transportString()

        guard let syncContext = user.managedObjectContext?.zm_sync else {
            return
        }

        syncContext.performGroupedBlock {
            broadcast(identifier: identifier, context: syncContext)
        }
    }

    // MARK: Private

    private func broadcast(identifier: UUID, context: NSManagedObjectContext) {
        let message = DataTransfer(trackingIdentifier: identifier)
        _ = try? ZMConversation.sendMessageToSelfClients(message, in: context)
    }
}
