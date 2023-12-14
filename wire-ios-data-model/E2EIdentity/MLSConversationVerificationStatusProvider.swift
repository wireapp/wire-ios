//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public protocol MLSConversationVerificationStatusProviderInterface {

    func invoke(_ groupID: MLSGroupID)

}

public class MLSConversationVerificationStatusProvider: MLSConversationVerificationStatusProviderInterface {

    private var e2eIConversationService: E2eIConversationServiceInterface
    private var syncContext: NSManagedObjectContext

    public init(e2eIConversationService: E2eIConversationServiceInterface, syncContext: NSManagedObjectContext) {
        self.e2eIConversationService = e2eIConversationService
        self.syncContext = syncContext
    }

    public func invoke(_ groupID: MLSGroupID) {
        var conversation: ZMConversation?
        let coreCryptoStatus = e2eIConversationService.getConversationVerificationStatus(groupID: groupID)
        syncContext.performAndWait {
            conversation = ZMConversation.fetch(with: groupID, in: syncContext)
        }
        guard let conversation = conversation else {
            return
        }
        updateStatusAndNotifyUserIfNeeded(newStatusFromCC: coreCryptoStatus, conversation: conversation)
    }

    private func updateStatusAndNotifyUserIfNeeded(newStatusFromCC: MLSVerificationStatus, conversation: ZMConversation) {
        guard let currentStatus = conversation.mlsVerificationStatus else {
            return
        }

        let newStatus = getActualNewStatus(newStatusFromCC: newStatusFromCC, currentStatus: currentStatus)
        guard newStatus != currentStatus else {
            return
        }
        conversation.mlsVerificationStatus = newStatus
        // TODO: check conditions - https://wearezeta.atlassian.net/browse/WPB-3233
        if newStatus == .degraded || newStatus == .verified {
            notifyUserAboutStateChanges(newStatus, in: conversation)
        }
    }

    private func getActualNewStatus(newStatusFromCC: MLSVerificationStatus, currentStatus: MLSVerificationStatus) -> MLSVerificationStatus {
        switch (newStatusFromCC, currentStatus) {
        case (.notVerified, .verified):
            return .degraded
        case(.notVerified, .degraded):
            return .degraded
        default:
            return newStatusFromCC
        }
    }

    private func notifyUserAboutStateChanges(_ newStatus: MLSVerificationStatus, in conversation: ZMConversation) {
        // TODO: add system message - https://wearezeta.atlassian.net/browse/WPB-3233
    }
}
