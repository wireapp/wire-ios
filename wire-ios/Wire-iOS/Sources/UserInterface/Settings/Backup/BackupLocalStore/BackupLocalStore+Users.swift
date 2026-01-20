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

import WireBackup
import WireDataModel
import WireFoundation

extension BackupLocalStore {

    private var userFetchRequest: NSFetchRequest<any NSFetchRequestResult> {
        let fetchRequest = ZMUser.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        fetchRequest.returnsObjectsAsFaults = true
        fetchRequest.includesPropertyValues = false
        return fetchRequest
    }

    func fetchAllUserIDs() async throws -> Set<WireFoundation.QualifiedID> {
        let fetchRequest = ZMUser.fetchRequest()
        fetchRequest.propertiesToFetch = ["remoteIdentifier_data", "domain"]
        return try await backupContext.perform { [backupContext] in
            let users = try backupContext.fetch(fetchRequest) as! [ZMUser]
            return Set(users.compactMap(\.qualifiedID).map(WireFoundation.QualifiedID.init))
        }
    }

    func fetchAllUsers() -> AsyncThrowingStream<UserBackupModel, any Error> {
        AsyncThrowingStream { continuation in
            Task<Void, Never> {
                do {
                    try await backupContext.perform {
                        let users = try backupContext.fetch(userFetchRequest) as! [ZMUser]
                        for user in users {
                            autoreleasepool {
                                if let backupUser = UserBackupModel(user) {
                                    continuation.yield(backupUser)
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func addUser(_ backupUser: UserBackupModel) async throws {
        // Adding users needs to be done on the sync context. See more in `ZMUser.fetchOrCreate`
        let syncContext = contextProvider.syncContext

        await syncContext.perform { [syncContext] in
            let user = ZMUser.fetchOrCreate(
                with: backupUser.qualifiedID.id,
                domain: backupUser.qualifiedID.domain,
                in: syncContext
            )
            if user.handle?.isEmpty != false {
                user.handle = backupUser.handle
            }
            user.isPendingMetadataRefresh = true
            user.needsToBeUpdatedFromBackend = true
        }
    }

}

// MARK: -

private extension UserBackupModel {

    init?(_ user: ZMUser) {
        guard let qualifiedID = user.qualifiedID else { return nil }

        self.init(
            qualifiedID: QualifiedID(qualifiedID),
            name: user.name ?? "",
            handle: user.handle ?? ""
        )
    }

}
