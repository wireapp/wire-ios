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

import Foundation

class UserManager {
    var createdUsers: [UserInfo]
    
    init() {
        createdUsers = []
    }
    
    func createPersonalUser() async throws -> UserInfo {
        var user = UserGenerator.generateUniqueUserInfo()
        let newUser = try await BackendClient.registerPersonalUser(user)
        createdUsers.append(newUser)
        return newUser
    }
    
    func deleteUser(_ user: UserInfo) async throws {
        let access_token = try? await BackendClient.loginViaAPI(email: user.email, password: user.password)
        if(access_token != nil) {
            try? await BackendClient.deletePersonalUser(access_token:access_token!, password: user.password)
            puts("Cleaned up \(user.email)")
        }
    }
    
    func deleteCreatedUsers() async throws {
        for user in createdUsers {
            try await deleteUser(user)
        }
    }
}
