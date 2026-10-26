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

extension ZMMessage {

    class func predicateForMessagesOlderThan(_ date: Date) -> NSPredicate {
        NSPredicate(format: "%K < %@", ZMMessageServerTimestampKey, date as NSDate)
    }

    public class func deleteMessagesOlderThan(_ date: Date, context: NSManagedObjectContext) throws {
        // Batch deletion bypasses per-message cleanup. Capture keys while rows are readable, then
        // release durable assets only after the database deletion has succeeded.
        let expiredOutboxAssets = ZMAssetClientMessage.sortedFetchRequest(with: NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                predicateForMessagesOlderThan(date), NSPredicate(format: "outboxStateRaw != 0")
            ]
        ))
        let assets = try context.fetch(expiredOutboxAssets) as! [ZMAssetClientMessage]
        let retainedKeys = assets.reduce(into: Set<String>()) {
            $0.formUnion(context.zm_fileAssetCache.outboxAssetKeys(for: $1))
        }
        context.zm_fileAssetCache.deleteAssetsOlderThan(date)
        try context.batchDeleteEntities(named: ZMMessage.entityName(), matching: predicateForMessagesOlderThan(date))
        context.zm_fileAssetCache.releaseOutboxAssetKeys(retainedKeys, discard: true)
    }

}
