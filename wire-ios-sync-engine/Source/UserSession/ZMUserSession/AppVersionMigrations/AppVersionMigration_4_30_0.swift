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
/// This migration keeps one user per (remoteIdentifier, domain) pair, marks it to be refetched from the backend,
/// and deletes the other copies.
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
            let users = (try? context.fetch(request)) ?? []

            let duplicateGroups = Dictionary(grouping: users) {
                UserIdentity(remoteIdentifier: $0.remoteIdentifier, domain: $0.domain)
            }.values.filter { $0.count > 1 }

            WireLogger.appVersionMigration.info(
                "\(duplicateGroups.count) duplicate user(s) to remove",
                attributes: .safePublic
            )

            for duplicates in duplicateGroups {
                guard let keptUser = duplicates.first else { continue }
                keptUser.needsToBeUpdatedFromBackend = true

                for duplicate in duplicates.dropFirst() {
                    context.delete(duplicate)
                }
            }

            try context.save()
        }
    }
}
