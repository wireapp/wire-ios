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
import WireAPI

class UserManager {
    var createdUsers: [UserInfo]
    var networkStack: NetworkStack
    var apiService: APIService
    
    let authenticationAPI: AuthenticationAPI
    let selfUserAPI: SelfUserAPI
    let authenticationManager: AuthenticationManager
    
    private let cookieStorage: any CookieStorageProtocol
    
    init() {
        createdUsers = []
        networkStack = NetworkStack(backendEnvironment: .staging, minTLSVersion: .v1_2, cookieEncryptionKey: Data())
        cookieStorage = MockCookieStorage()
        authenticationManager = AuthenticationManager(
            clientID: "selfClientID",
            cookieStorage: cookieStorage,
            networkService: networkStack.apiNetworkService,
            onAuthenticationFailure: { @Sendable () in return}
        )
        apiService = APIService(networkService: networkStack.apiNetworkService, authenticationManager: authenticationManager)
        authenticationAPI = AuthenticationAPIBuilder(networkService: networkStack.apiNetworkService).makeAPI(for: .v8)
        selfUserAPI = SelfUserAPIBuilder(apiService: apiService).makeAPI(for: .v8)
    }
    
    func createPersonalUser() async throws -> UserInfo {
        let user = UserGenerator.generateUniqueUserInfo()

        // Start registration
        let cookies = try await authenticationAPI.testRegisterPersonalAccount(name: user.name, email: user.email, password: user.password)
        try await cookieStorage.storeCookies(cookies)

        // Get activation code
        let (activationCode, activationKey) = try await BackendClient.getActivationCode(email: user.email)

        // Activate user
        try await authenticationAPI.testActivateUser(email: user.email, key: activationKey, code: activationCode)

        // Set username
        try await selfUserAPI.testUpdateHandle(handle: user.username)

        createdUsers.append(user)
        return user
    }
    
    func addUser(_ user: UserInfo) {
        createdUsers.append(user)
    }
    
    func addUser(email: String, password: String) {
        createdUsers.append(UserInfo(email: email, password: password))
    }
    
    func deleteUser(_ user: UserInfo) async throws {
        try await selfUserAPI.testDeleteSelf(password: user.password)
    }
    
    func deleteCreatedUsers() async throws {
        for user in createdUsers {
            print("Deleting \(user.email)")
            try await deleteUser(user)
        }
    }
}

private extension BackendEnvironment {
    static let backendURL = "https://\(ProcessInfo.processInfo.environment["BACKEND_URL"]!)"
    static let staging = BackendEnvironment(url: URL(string: backendURL)!, webSocketURL: URL(string: backendURL)!, pinnedKeys: [], proxySettings: nil)
}

final class MockCookieStorage: CookieStorageProtocol {
    var cookies: [HTTPCookie]
    
    init() {
        cookies = []
    }
    
    func storeCookies(_ cookies: [HTTPCookie]) async throws {
        print("Storing \(cookies)")
        self.cookies = cookies
    }
    
    func fetchCookies() async throws -> [HTTPCookie] {
        print("Giving \(cookies)")
        return cookies
    }
    
    func removeCookies() async throws {
        print("Clearing cookies")
        cookies = []
    }
}
