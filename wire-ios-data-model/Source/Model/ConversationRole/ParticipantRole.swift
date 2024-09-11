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

let ZMParticipantRoleRoleValueKey = #keyPath(ParticipantRole.role)

@objcMembers
public final class ParticipantRole: ZMManagedObject {
    /// - Note: conversation is optional dbut we should make sure it's always created with one using
    /// `create(managedObjectContext:user:conversation:)`
    @NSManaged public var conversation: ZMConversation?
    /// - Note: user is optional but we should make sure it's always created with one using
    /// `create(managedObjectContext:user:conversation:)`
    @NSManaged public var user: ZMUser?
    @NSManaged public var role: Role?

    override public static func entityName() -> String {
        "ParticipantRole"
    }

    override public static func isTrackingLocalModifications() -> Bool {
        true
    }

    @discardableResult
    public static func create(
        managedObjectContext: NSManagedObjectContext,
        user: ZMUser,
        conversation: ZMConversation
    ) -> ParticipantRole {
        let entry = ParticipantRole.insertNewObject(in: managedObjectContext)
        entry.user = user
        entry.conversation = conversation
        return entry
    }
}
