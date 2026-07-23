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

/// Backfills the `effectiveConversationType` attribute introduced in model version 2.136.0.
///
/// `effectiveConversationType` is a persisted mirror of the computed `conversationType` (which promotes team-1:1 and
/// service group conversations to `.oneOnOne`).
final class EffectiveConversationTypeMigrationAction: CoreDataMigrationAction {

    override func execute(in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        request.fetchBatchSize = 200

        let conversations = try context.fetch(request)
        for conversation in conversations {
            conversation.effectiveConversationType = conversation.conversationType
        }
    }
}
