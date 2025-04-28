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

import WireBackup
import WireDataModel
import WireFoundation
import WireDomain

struct UserStoreAdapter: UserStoreProtocol {

    let userLocalStore: any UserLocalStoreProtocol

    init(userLocalStore: any UserLocalStoreProtocol) {
        self.userLocalStore = userLocalStore
    }

    func totalUserCount() async throws -> Int {
        try await userLocalStore.totalBackupableUserCount()
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

    // MARK: -

    struct UserEntity: UserEntityProtocol {
        typealias QualifiedID = WireFoundation.QualifiedID

        let id: QualifiedID
        let name: String
        let handle: String

        init?(_ user: ZMUser) {
            guard let qualifiedID = user.qualifiedID else { return nil }

            id = QualifiedID(qualifiedID)
            name = user.name ?? ""
            handle = user.handle ?? ""
        }

    }

}
