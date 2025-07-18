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
import WireNetwork

class UserManager {
    var createdUsers: [UserInfo]
    var networkStack: NetworkStack
    var apiService: APIService
    var networkService: NetworkService

    let authenticationAPI: AuthenticationAPI
    let teamsAPI: TeamsAPI
    let selfUserAPI: SelfUserAPI
    let authenticationManager: AuthenticationManager

    private let cookieStorage: any CookieStorageProtocol

    init(apiVersion: APIVersion = .v8) {
        self.createdUsers = []
        self.networkStack = NetworkStack(
            backendEnvironment: .staging,
            minTLSVersion: .v1_2,
            cookieEncryptionKey: Data()
        )
        self.networkService = networkStack.apiNetworkService
        self.cookieStorage = MockCookieStorage()
        self.authenticationManager = AuthenticationManager(
            clientID: nil,
            cookieStorage: cookieStorage,
            networkService: networkService,
            onAuthenticationFailure: { @Sendable () in }
        )
        self.apiService = APIService(
            networkService: networkStack.apiNetworkService,
            authenticationManager: authenticationManager
        )
        self.authenticationAPI = AuthenticationAPIBuilder(networkService: networkStack.apiNetworkService)
            .makeAPI(for: apiVersion)
        self.selfUserAPI = SelfUserAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
        self.teamsAPI = TeamsAPIBuilder(apiService: apiService, networkService: networkStack.apiNetworkService)
            .makeAPI(for: apiVersion)
    }

    func createPersonalUser() async throws -> UserInfo {
        let user = UserGenerator.generateUniqueUserInfo()

        // Start registration
        let cookies = try await authenticationAPI.registerPersonalAccount(
            name: user.name,
            email: user.email,
            password: user.password
        )
        try await cookieStorage.storeCookies(cookies)

        // Get activation code
        let (activationCode, activationKey) = try await BackendClient.getActivationCode(email: user.email)

        // Activate user
        try await authenticationAPI.activateUser(email: user.email, key: activationKey, code: activationCode)

        // Set username
        try await selfUserAPI.updateHandle(handle: user.username)

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
        try await selfUserAPI.deleteSelf(password: user.password)
    }

    func deleteTeam(teamID: UUID, password: String, code: String) async throws {
        try await selfUserAPI.deleteTeam(
            teamId: teamID,
            password: password,
            verificationCode: code
        )
    }

    func deleteCreatedUsers() async {
        for user in createdUsers {
            do {
                if let teamID = try await BackendClient.getTeamIDFromSelfRequest(
                    email: user.email,
                    password: user.password
                ) {
                    // If team exists, try deleting the team
                    try await BackendClient.sendVerificationCode(email: user.email, password: user.password)
                    let code = try await InbucketClient.getVerificationCode(email: user.email)
                    try await deleteTeam(teamID: teamID, password: user.password, code: code)
                } else {
                    // If no team, delete user
                    try await deleteUser(user)
                }
            } catch {
                print("❌ Failed to clean up user \(user.email): \(error)")
            }
        }
    }

    func registerUserAsTeamOwner() async throws -> UserInfo {
        var teamOwner = UserGenerator.generateUniqueUserInfo()

        let teamID = try await authenticationAPI.registerTeamOwner(
            email: teamOwner.email,
            password: teamOwner.password,
            name: teamOwner.name,
            teamName: teamOwner.teamName
        )

        teamOwner.teamID = teamID
        createdUsers.append(teamOwner)
        return teamOwner
    }

    func getInvitationIdToAddMemberInTeam(
        email: String,
        password: String,
        teamID: UUID,
        memberEmail: String,
        memberName: String
    ) async throws -> UUID {

        let (activationCode, activationKey) = try await authenticationAPI.getActivationCode(forEmail: email)

        try await authenticationAPI.activateUser(email: email, key: activationKey, code: activationCode)

        let (_, AccessToken) = try await authenticationAPI.login(
            email: email,
            password: password,
            verificationCode: nil,
            label: nil
        )
        return try await teamsAPI.inviteMemberToTeam(
            access_token: AccessToken.token,
            teamID: teamID,
            memberName: memberName,
            memberEmail: memberEmail
        )
    }

    func getInvitationCodeToAddMemberInTeam(teamID: UUID, invitationID: UUID) async throws -> String {

        try await authenticationAPI.getInvitationCode(teamID: teamID, invitationID: invitationID)
    }

    func registerUserAsTeamMember(teamMember: UserInfo, invitationCode: String) async throws {

        try await authenticationAPI.registerTeamMember(
            email: teamMember.email,
            password: teamMember.password,
            name: teamMember.name,
            invitationCode: invitationCode
        )
    }
}

private extension BackendEnvironment {
    static let backendURL = "https://\(ProcessInfo.processInfo.environment["BACKEND_URL"]!)"
    static let staging = BackendEnvironment(
        url: URL(string: backendURL)!,
        webSocketURL: URL(string: backendURL)!,
        pinnedKeys: [],
        proxySettings: nil
    )
}

private final class MockCookieStorage: CookieStorageProtocol {
    var cookies: [HTTPCookie]

    init() {
        self.cookies = []
    }

    func storeCookies(_ cookies: [HTTPCookie]) async throws {
        self.cookies = cookies
    }

    func fetchCookies() async throws -> [HTTPCookie] {
        cookies
    }

    func removeCookies() async throws {
        cookies = []
    }
}
