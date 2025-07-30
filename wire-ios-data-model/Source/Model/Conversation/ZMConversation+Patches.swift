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

extension ZMConversation {
    @objc public static let defaultAdminRoleName = "wire_admin"
    @objc public static let defaultMemberRoleName = "wire_member"

    // Model version add a `accessRoleStringsV2` attribute to the `Conversation` entity. The values from
    // accessRoleString, need to be migrated to the new relationship
    static func forceToFetchConversationAccessRoles(in moc: NSManagedObjectContext) {
        let conversationsToFetch = ZMConversation.fetchRequest()

        guard let conversations = moc.fetchOrAssert(request: conversationsToFetch) as? [ZMConversation] else {
            fatal("fetchOrAssert failed")
        }

        conversations.forEach {
            guard $0.isSelfAnActiveMember else { return }
            $0.needsToBeUpdatedFromBackend = true
        }
    }

    // Migration rules for the Model Version 2.98.0
    static func introduceAccessRoleV2(in moc: NSManagedObjectContext) {
        forceToFetchConversationAccessRoles(in: moc)
    }

}
