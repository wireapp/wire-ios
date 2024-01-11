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

extension ZMUserSession {

    var refreshUsersMissingMetadataAction: RecurringAction {
        .init(id: #function, interval: 3 * .oneHour) { [weak self] in

            guard let moc = self?.managedObjectContext else { return }
            moc.performGroupedAndWait { moc in

                let fetchRequest = ZMUser.sortedFetchRequest(with: ZMUser.predicateForUsersArePendingToRefreshMetadata())
                guard let users = moc.fetchOrAssert(request: fetchRequest) as? [ZMUser] else {
                    return
                }

                users.forEach { $0.refreshData() }
                moc.saveOrRollback()
            }
        }
    }

    var refreshConversationsMissingMetadataAction: RecurringAction {
        .init(id: #function, interval: 3 * .oneHour) { [weak self] in

            guard let moc = self?.managedObjectContext else { return }
            moc.performGroupedAndWait { moc in

                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ZMConversation.entityName())
                fetchRequest.predicate = ZMConversation.predicateForConversationsArePendingToRefreshMetadata()

                guard let conversations = moc.executeFetchRequestOrAssert(fetchRequest) as? [ZMConversation] else {
                    return
                }

                conversations.forEach { $0.needsToBeUpdatedFromBackend = true }
                moc.saveOrRollback()
            }
        }
    }

    var refreshTeamMetadataAction: RecurringAction {
        .init(id: #function, interval: .oneDay) { [weak self] in

            guard let moc = self?.managedObjectContext else { return }
            moc.performGroupedAndWait { moc in

                guard let team = ZMUser.selfUser(in: moc).team else { return }
                team.refreshMetadata()
            }
        }
    }
}
