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

// sourcery: AutoMockable
public protocol MLSConversationVerificationStatusUpdating {

    func updateAllStatuses() async throws

}

public class MLSConversationVerificationStatusUpdater: MLSConversationVerificationStatusUpdating {

    // MARK: - Properties

    private let updateMLSGroupVerificationStatus: UpdateMLSGroupVerificationStatusUseCaseProtocol
    private let syncContext: NSManagedObjectContext

    // MARK: - Life cycle

    public init(
        updateMLSGroupVerificationStatus: UpdateMLSGroupVerificationStatusUseCaseProtocol,
        syncContext: NSManagedObjectContext
    ) {
        self.updateMLSGroupVerificationStatus = updateMLSGroupVerificationStatus
        self.syncContext = syncContext
    }

    // MARK: - Public interface

    public func updateAllStatuses() async throws {
        let groupIDConversationTuples: [(MLSGroupID, ZMConversation)] = await syncContext.perform { [self] in
            let conversations = ZMConversation.fetchMLSConversations(in: syncContext)
            return conversations.compactMap {
                guard let groupID = $0.mlsGroupID else {
                    return nil
                }
                return (groupID, $0)
            }
        }

        for (groupID, conversation) in groupIDConversationTuples {
            try await updateMLSGroupVerificationStatus.invoke(for: conversation, groupID: groupID)
        }
    }
}
