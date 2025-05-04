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

import CoreData
import WireBackup
import WireDataModel
import WireDomain
import WireFoundation

struct UserStoreAdapter: UserStoreProtocol {
    typealias QualifiedID = WireFoundation.QualifiedID

    let userLocalStore: UserLocalStore

    init(context: NSManagedObjectContext) {
        userLocalStore = UserLocalStore(
            context: context,
            messageLocalStore: MessageLocalStore(context: context)
        )
    }

    func totalUserCount() async throws -> Int {
        try await userLocalStore.totalBackupableUserCount()
    }

    func fetchAllUserIDs() async throws -> Set<QualifiedID> {
        let userIDs = try await userLocalStore.fetchAllBackupableUserIDs()
            .map(WireFoundation.QualifiedID.init)
        return Set(userIDs)
    }

    func fetchAllUsers() async throws -> [UserEntity] {
        let users = try await userLocalStore.fetchAllBackupableUsers()
        return await userLocalStore.context.perform {
            users.compactMap { user in
                guard let user = UserEntity(user) else {
                    assertionFailure()
                    return nil
                }
                return user
            }
        }
    }

    func addUser(
        id: QualifiedID,
        name: String,
        handle: String
    ) async throws {
        let userInfo = NewUserInfo(
            userID: WireDataModel.QualifiedID(id),
            name: name,
            handle: handle,
            teamID: nil,
            accentID: 0,
            previewAssetKey: nil,
            completeAssetKey: nil,
            isDeleted: false,
            email: nil,
            expiresAt: nil,
            serviceID: nil,
            serviceProvider: nil,
            supportedProtocols: nil
        )
        await userLocalStore.persistUser(userInfo: userInfo)
    }

    // MARK: -

    struct UserEntity: UserEntityProtocol {

        let id: QualifiedID
        let name: String
        let handle: String

        init?(_ user: ZMUser) {
            guard let qualifiedID = user.qualifiedID else { return nil }

            self.id = QualifiedID(qualifiedID)
            self.name = user.name ?? ""
            self.handle = user.handle ?? ""
        }

    }

}
