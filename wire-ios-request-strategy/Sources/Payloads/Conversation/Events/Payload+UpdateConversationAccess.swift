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
import WireTransport

extension Payload {
    struct UpdateConversationAccess: CodableEventData {
        // MARK: Lifecycle

        init(accessMode: ConversationAccessMode, accessRoles: Set<ConversationAccessRoleV2>) {
            self.access = accessMode.stringValue
            self.accessRole = ConversationAccessRole.fromAccessRoleV2(accessRoles).rawValue
            self.accessRoleV2 = accessRoles.map(\.rawValue)
        }

        // MARK: Internal

        enum CodingKeys: String, CodingKey {
            case access
            case accessRole = "access_role"
            case accessRoleV2 = "access_role_v2"
        }

        static var eventType: ZMUpdateEventType {
            .conversationAccessModeUpdate
        }

        let access: [String]
        let accessRole: String?
        let accessRoleV2: [String]?
    }
}
