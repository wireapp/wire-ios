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
import WireDataModel
import WireLogging
import WireNetwork

struct CommitPendingProposalItem: WorkItem {
    private let repository: ConversationRepositoryProtocol
    private let mlsService: MLSServiceInterface

    let id = UUID()
    var priority: WorkItemPriority {
        .medium
    }

    let conversationID: WireDataModel.QualifiedID
    let groupID: WireDataModel.MLSGroupID
    let timestamp: Date
    let logger = WireLogger.mls

    public init(
        repository: ConversationRepositoryProtocol,
        conversationID: WireDataModel.QualifiedID,
        groupID: WireDataModel.MLSGroupID,
        timestamp: Date,
        mlsService: MLSServiceInterface
    ) {
        self.repository = repository
        self.conversationID = conversationID
        self.groupID = groupID
        self.timestamp = timestamp
        self.mlsService = mlsService
    }

    func start() async throws {
        let logAttributes: LogAttributes = [.mlsGroupID: groupID.safeForLoggingDescription] + LogAttributes.safePublic
        if timestamp.isInThePast {
            logger.info("commit scheduled in the past, committing...", attributes: logAttributes)

            try await mlsService.commitPendingProposals(in: groupID)
        } else {
            logger.info(
                "commit scheduled in the future, waiting...",
                attributes: logAttributes
            )

            let timeIntervalSinceNow = timestamp.timeIntervalSinceNow
            if timeIntervalSinceNow > 0 {
                try await Task.sleep(for: .seconds(timeIntervalSinceNow))
            }

            let isSelfAnActiveMember = await repository.isSelfAnActiveMember(in: groupID)

            guard isSelfAnActiveMember else {
                logger.info(
                    "cancelling commit as the user is no longer a member",
                    attributes: logAttributes
                )
                return
            }

            logger.info("scheduled commit is ready, committing...", attributes: logAttributes)
            try await mlsService.commitPendingProposals(in: groupID)
        }
    }
}
