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
import WireDataModel
import WireDomain
import WireLogging

/// **Issue:** Duplicate `ZMUser` rows could exist locally for the same domain and remote identifier - [WPB-22498]
///
/// A mismatch between a `nil` and an empty-string domain produced different `primaryKey` values for what is
/// otherwise the same user, so the `primaryKey` uniqueness constraint didn't prevent the duplicate from being
/// created. Left in place, the duplicate could later crash the app when both rows were fetched by identity.
/// This migration keeps one user per (remoteIdentifier, domain) pair, transfers the other copies' relationships
/// onto it, marks it to be refetched from the backend, and deletes the other copies.
struct AppVersionMigration_4_30_0: AppVersionMigration {

    let version: SemanticVersion = "4.30.0"
    let coreDataStack: CoreDataStackProtocol

    private struct UserIdentity: Hashable {
        let remoteIdentifier: UUID
        let domain: String?
    }

    func perform() async throws {
        let context = coreDataStack.syncContext

        try await context.perform {
            let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
            // Deterministic order so the "kept" user (`duplicates.first`) is reproducible rather than
            // depending on the store's unspecified default fetch order.
            request.sortDescriptors = [NSSortDescriptor(key: "primaryKey", ascending: true)]
            let users = (try? context.fetch(request)) ?? []

            let duplicateGroups = Dictionary(grouping: users) {
                // "" and nil both mean "no domain", so they must be treated as the same identity here.
                UserIdentity(
                    remoteIdentifier: $0.remoteIdentifier,
                    domain: $0.domain?.isEmpty == true ? nil : $0.domain
                )
            }.values.filter { $0.count > 1 }

            WireLogger.appVersionMigration.info(
                "\(duplicateGroups.count) duplicate user(s) to remove",
                attributes: .safePublic
            )

            for duplicates in duplicateGroups {
                guard let keptUser = duplicates.first else { continue }
                keptUser.needsToBeUpdatedFromBackend = true

                for duplicate in duplicates.dropFirst() {
                    transferRelationships(from: duplicate, to: keptUser)
                    context.delete(duplicate)
                }
            }

            try context.save()
        }
    }

    /// Moves every relationship still pointing at `duplicate` onto `keptUser` before `duplicate` is deleted,
    /// so that Core Data's `Nullify` delete rules don't silently drop messages, connections, or reactions
    /// that referenced the duplicate.
    ///
    /// `participantRoles` is skipped on purpose: it is `Cascade`-deleted with the duplicate instead, since
    /// `keptUser` may already have its own role in the same conversations, and the backend conversation sync
    /// (triggered by `needsToBeUpdatedFromBackend`) reconciles `keptUser`'s participation anyway.
    private func transferRelationships(from duplicate: ZMUser, to keptUser: ZMUser) {
        for relationship in duplicate.entity.relationshipsByName.values where relationship.name != "participantRoles" {
            let name = relationship.name

            if relationship.isOrdered {
                let duplicateValues = duplicate.mutableOrderedSetValue(forKey: name)
                keptUser.mutableOrderedSetValue(forKey: name).addObjects(from: duplicateValues.array)
                duplicateValues.removeAllObjects()
            } else if relationship.isToMany {
                let duplicateValues = duplicate.mutableSetValue(forKey: name)
                keptUser.mutableSetValue(forKey: name).addObjects(from: duplicateValues.allObjects)
                duplicateValues.removeAllObjects()
            } else if keptUser.value(forKey: name) == nil, let duplicateValue = duplicate.value(forKey: name) {
                keptUser.setValue(duplicateValue, forKey: name)
            }
        }
    }
}
