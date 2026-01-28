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
@preconcurrency import WireDataModel
import WireLogging
import WireNetwork

struct CommitPendingProposalItem: WorkItem, CustomStringConvertible {
    private let repository: ConversationRepositoryProtocol
    private let mlsService: MLSServiceInterface

    var description: String {
        "CommitPendingProposalItem: \(id), mlsGroupID: \(groupID), conversationID: \(conversationID)"
    }

    let id = UUID()
    var priority: WorkItemPriority {
        .medium
    }

    let conversationID: WireDataModel.QualifiedID
    let groupID: WireDataModel.MLSGroupID
    let logger = WireLogger.mls

    public init(
        repository: ConversationRepositoryProtocol,
        conversationID: WireDataModel.QualifiedID,
        groupID: WireDataModel.MLSGroupID,
        mlsService: MLSServiceInterface
    ) {
        self.repository = repository
        self.conversationID = conversationID
        self.groupID = groupID
        self.mlsService = mlsService
    }

    func start() async throws {
        let logAttributes: LogAttributes = [.mlsGroupID: groupID.safeForLoggingDescription] + LogAttributes.safePublic

        let isSelfAnActiveMember = await repository.isSelfAnActiveMember(in: groupID)
        // TODO: check the group exists
        guard isSelfAnActiveMember else {
            logger.info("cancelling commit as the user is no longer a member", attributes: logAttributes)
            return
        }

        logger.info("committing pending proposals now...", attributes: logAttributes)
        try await mlsService.commitPendingProposals(in: groupID)
    }
}
