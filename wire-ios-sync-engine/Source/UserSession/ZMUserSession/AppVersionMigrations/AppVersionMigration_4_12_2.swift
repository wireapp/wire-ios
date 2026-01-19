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
import WireDomain
import WireLogging
import WireNetwork

/// **Issue:**: 400 errors on commit-bundle - [WPB-21784]
/// Reset epoch if needed
struct AppVersionMigration_4_12_2: AppVersionMigration {

    let version: SemanticVersion = "4.12.2"
    let coreDataStack: CoreDataStackProtocol
    let coreCrypto: SafeCoreCryptoProtocol

    func perform() async throws {
        let context = coreDataStack.syncContext

        let mlsGroupIDs = await context.perform {
            let conversations = ZMConversation.fetchMLSConversations(in: context)
            return conversations.compactMap(\.mlsGroupID)
        }

        var fixedConversationsCount = 0

        for mlsGroupID in mlsGroupIDs {

            try await coreCrypto.perform { ccContext in
                let epoch: UInt64 = if try await ccContext
                    .conversationExists(conversationId: mlsGroupID.conversationId) {
                    UInt64(try await ccContext.conversationEpoch(conversationId: mlsGroupID.conversationId))
                } else {
                    0
                }

                await context.perform {
                    let conversation = ZMConversation.fetch(with: mlsGroupID, in: context)
                    if conversation?.epoch != epoch {
                        conversation?.epoch = epoch
                        fixedConversationsCount += 1
                    }
                }
            }
        }

        WireLogger.mls.info(
            "Fixing \(fixedConversationsCount) conversations' epoch out of \(mlsGroupIDs.count) conversations",
            attributes: .safePublic
        )

        try await context.perform {
            try context.save()
            WireLogger.mls.info("Saved all conversations' epoch changes", attributes: .safePublic)
        }
    }
}
