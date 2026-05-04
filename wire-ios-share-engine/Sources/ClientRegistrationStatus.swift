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

import WireRequestStrategy

final class ClientRegistrationStatus: NSObject, ClientRegistrationDelegate {

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    var clientIsReadyForRequests: Bool {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: move constant into shared framework
        if let clientId = context.persistentStoreMetadata(forKey: ZMPersistedClientIdKey) as? String {
            return !clientId.isEmpty
        }

        return false
    }

    func didDetectCurrentClientDeletion() {
        // nop
    }
}
