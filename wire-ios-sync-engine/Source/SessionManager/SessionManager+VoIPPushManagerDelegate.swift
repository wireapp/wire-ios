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
import PushKit
import WireLogging

extension SessionManager: VoIPPushManagerDelegate {

    public func processPendingCallEvents(accountID: UUID) async {
        WireLogger.calling.info("process pending call events preemptively")

        guard
            let account = accountManager.account(with: accountID)
        else {
            WireLogger.calling
                .error("failed to process pending call events preemptively: account not found for \(accountID))")
            return
        }

        guard
            let activity = BackgroundActivityFactory.shared.startBackgroundActivity(name: "processPendingCallEvents")
        else {
            WireLogger.calling.error("failed to process pending call events preemptively: activity not started")
            return
        }

        do {
            let session = try await withSession(for: account)
            await session.processPendingCallEvents()
        } catch {
            WireLogger.calling
                .error("failed to process pending call events preemptively: cannot load session - \(error)")
        }
        BackgroundActivityFactory.shared.endBackgroundActivity(activity)
    }
}

private extension VoIPPushPayload {

    func caller(in context: NSManagedObjectContext) -> ZMUser? {
        ZMUser.fetch(
            with: senderID,
            domain: senderDomain,
            in: context
        )
    }

    func conversation(in context: NSManagedObjectContext) -> ZMConversation? {
        ZMConversation.fetch(
            with: conversationID,
            domain: conversationDomain,
            in: context
        )
    }

}

private extension [AnyHashable: Any] {

    var stringIdentifier: String {
        guard
            let data = self["data"] as? [AnyHashable: Any],
            let innerData = data["data"] as? [AnyHashable: Any],
            let id = innerData["id"]
        else {
            return description
        }

        return "\(id)"
    }

}
