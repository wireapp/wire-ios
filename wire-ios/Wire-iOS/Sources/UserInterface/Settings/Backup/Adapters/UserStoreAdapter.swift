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
        try await userLocalStore.fetchAllBackupableUsers().map(UserEntity.init)
    }

    // MARK: -

    struct UserEntity: UserEntityProtocol {
        typealias QualifiedID = WireFoundation.QualifiedID

        let user: ZMUser

        var id: QualifiedID {
            user.qualifiedID.map { qualifiedID in
                QualifiedID(qualifiedID)
            } ?? QualifiedID(id: user.remoteIdentifier, domain: "")
        }

        var name: String {
            get { user.name ?? "" }
            nonmutating set { user.name = newValue }
        }

        var handle: String {
            get { user.handle ?? "" }
            nonmutating set { user.handle = newValue }
        }

        init(_ user: ZMUser) {
            self.user = user
        }

    }

}
