//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


public extension ZMUser {

    @objc static func fetchAndMerge(with remoteIdentifier: UUID, createIfNeeded: Bool, in context: NSManagedObjectContext) -> ZMUser? {
        // We must only ever call this on the sync context. Otherwise, there's a race condition
        // where the UI and sync contexts could both insert the same user (same UUID) and we'd end up
        // having two duplicates of that user, and we'd have a really hard time recovering from that.
        //
        assert(!createIfNeeded || context.zm_isSyncContext, "Race condition!")
        if let result = fetchAndMergeDuplicates(with: remoteIdentifier, in: context) {
            return result
        } else if(createIfNeeded) {
            let user = ZMUser.insertNewObject(in: context)
            user.remoteIdentifier = remoteIdentifier
            return user
        } else {
            return nil
        }
    }
}
