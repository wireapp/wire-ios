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

    var updateProteusToMLSMigrationStatusAction: RecurringAction {
        .init(id: #function, interval: .oneDay) { [weak self] in
            Task { [weak self] in
                do {
                    try await self?.proteusToMLSMigrationCoordinator.updateMigrationStatus()
                } catch {
                    WireLogger.mls.error("proteusToMLSMigrationCoordinator.updateMigrationStatus() threw error: \(String(reflecting: error))")
                }
            }
        }
    }

    var refreshUsersMissingMetadataAction: RecurringAction {
        .init(id: #function, interval: 3 * .oneHour) { [weak self] in

            guard let context = self?.managedObjectContext else { return }
            context.performGroupedAndWait { context in

                let fetchRequest = ZMUser.sortedFetchRequest(with: ZMUser.predicateForUsersArePendingToRefreshMetadata())
                guard let users = context.fetchOrAssert(request: fetchRequest) as? [ZMUser] else {
                    return
                }

                users.forEach { $0.refreshData() }
                context.saveOrRollback()
            }
        }
    }

    var refreshConversationsMissingMetadataAction: RecurringAction {
        .init(id: #function, interval: 3 * .oneHour) { [weak self] in

            guard let context = self?.managedObjectContext else { return }
            context.performGroupedAndWait { context in

                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ZMConversation.entityName())
                fetchRequest.predicate = ZMConversation.predicateForConversationsArePendingToRefreshMetadata()

                guard let conversations = context.executeFetchRequestOrAssert(fetchRequest) as? [ZMConversation] else {
                    return
                }

                conversations.forEach { $0.needsToBeUpdatedFromBackend = true }
                context.saveOrRollback()
            }
        }
    }

    var refreshTeamMetadataAction: RecurringAction {
        .init(id: #function, interval: .oneDay) { [weak self] in

            guard let context = self?.managedObjectContext else { return }
            context.performGroupedAndWait { context in

                guard let team = ZMUser.selfUser(in: context).team else { return }
                team.refreshMetadata()
            }
        }
    }

    var refreshFederationCertificatesAction: RecurringAction {
        .init(id: #function, interval: .oneDay) { [weak self] in
            guard
                let self,
                viewContext.performAndWait({ self.e2eiFeature.isEnabled })
            else { return }

            Task {
                do {
                    try await self.e2eiRepository.fetchFederationCertificate()
                } catch {
                    WireLogger.e2ei.error("Failed to refresh federation certificates: \(error)")
                }
            }
        }
    }
}
