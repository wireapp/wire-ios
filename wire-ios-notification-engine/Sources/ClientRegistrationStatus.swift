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
import WireDataModel
import WireRequestStrategy

final class ClientRegistrationStatus: NSObject, ClientRegistrationDelegate {
    // MARK: - Properties

    let context: NSManagedObjectContext

    // MARK: - Life cycle

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Methods

    var clientIsReadyForRequests: Bool {
        if let clientId = context.persistentStoreMetadata(forKey: ZMPersistedClientIdKey) as? String {
            // swiftlint:disable:next todo_requires_jira_link
            // TODO: move constant into shared framework
            return !clientId.isEmpty
        }

        return false
    }

    func didDetectCurrentClientDeletion() {
        // nop
    }
}
