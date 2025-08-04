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

struct Member {
    let name: String
    let email: String
    let password: String
    var id: String?
}

class UserHelper {
    var createdUsers: [UserInfo]
    var networkStack: NetworkStack
    var apiService: APIService

    let authenticationAPI: AuthenticationAPI
    let teamsAPI: TeamsAPI
    let selfUserAPI: SelfUserAPI
    let conversationsAPI: ConversationsAPI
    let authenticationManager: AuthenticationManager

    private let cookieStorage: any CookieStorageProtocol

    init(apiVersion: APIVersion = .v8) {
        self.createdUsers = []
        self.networkStack = NetworkStack(
            backendEnvironment: .staging,
            minTLSVersion: .v1_2,
            cookieEncryptionKey: Data()
        )
        self.cookieStorage = MockCookieStorage()
        self.authenticationManager = AuthenticationManager(
            clientID: nil,
            cookieStorage: cookieStorage,
            networkService: networkStack.apiNetworkService,
            onAuthenticationFailure: { @Sendable () in }
        )
        self.apiService = APIService(
            networkService: networkStack.apiNetworkService,
            authenticationManager: authenticationManager
        )
        self.authenticationAPI = AuthenticationAPIBuilder(networkService: networkStack.apiNetworkService)
            .makeAPI(for: apiVersion)
        self.selfUserAPI = SelfUserAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
        self.teamsAPI = TeamsAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
        self.conversationsAPI = ConversationsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
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

    func getConversationIds() async throws -> [QualifiedID] {
        var conversationIDs = [QualifiedID]()
        for try await ids in try await conversationsAPI.getConversationIdentifiers() {
            conversationIDs.append(contentsOf: ids)
        }
        return conversationIDs
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
        let teamOwner = UserGenerator.generateUniqueUserInfo()

        let (teamID, id) = try await authenticationAPI.registerTeamOwner(
            email: teamOwner.email,
            password: teamOwner.password,
            name: teamOwner.name,
            teamName: teamOwner.teamName
        )

        teamOwner.teamID = teamID
        teamOwner.id = id
        createdUsers.append(teamOwner)
        return teamOwner
    }

    func fetchAccessToken(email: String, password: String) async throws -> String {
        let (activationCode, activationKey) = try await authenticationAPI.getActivationCode(forEmail: email)

        try await authenticationAPI.activateUser(email: email, key: activationKey, code: activationCode)

        let (_, accessToken) = try await authenticationAPI.login(
            email: email,
            password: password,
            verificationCode: nil,
            label: nil
        )

        return accessToken.token
    }

    func registerUsersAsTeamMember(
        ownerAccessToken: String,
        teamID: UUID
    ) async throws -> (qualifiedID: QualifiedID, member: UserInfo) {
        
        let teamMember = UserGenerator.generateUniqueUserInfo()

        let invitationID = try await teamsAPI.inviteMemberToTeam(
            access_token: ownerAccessToken,
            teamID: teamID,
            memberName: teamMember.name,
            memberEmail: teamMember.email
        )

        let invitationCode = try await authenticationAPI.getInvitationCode(
            teamID: teamID,
            invitationID: invitationID
        )

        let qualifiedID = try await authenticationAPI.registerTeamMember(
            email: teamMember.email,
            password: teamMember.password,
            name: teamMember.name,
            invitationCode: invitationCode
        )

        return (qualifiedID, teamMember)
    }

    func getQualifiedIdsFromConversationList() async throws -> [QualifiedID] {
        var conversationIDs = [QualifiedID]()

        for try await ids in try await conversationsAPI.getConversationIdentifiers() {
            conversationIDs.append(contentsOf: ids)
        }
        return conversationIDs
    }

    func getConversationId(matching criteria: FilterConversationsByCriteria) async throws
        -> (convoId: UUID?, domain: String?) {
        let conversationIDs = try await getQualifiedIdsFromConversationList()

        let conversations = try await conversationsAPI.getConversations(for: conversationIDs)

        let filtered = conversations.found.filter { conversation in
            switch criteria {
            case let .groupName(name):
                conversation.name == name
            case let .conversationType(type):
                conversation.type == type
            }
        }

        if let match = filtered.first {
            return (match.qualifiedID?.id, match.qualifiedID?.domain)
        }
        return (nil, nil)
    }

    func createGroupConversations(memberUser: UserInfo, groupName: String) async throws {
        // NEED FIXING
//        _ = try await BackendClient.loginViaAPI(email: memberUser.email, password: memberUser.password)
//        let selfUser = try await selfUserAPI.getSelfUser()

//        let params = CreateGroupConversationParameters(
//            groupType: .group,
//            messageProtocol: .proteus,
//            creatorClientID: "deprecated",
//            qualifiedUserIDs: [selfUser.qualifiedID],
//            unqualifiedUserIDs: [],
//            name: groupName,
//            accessMode: [.invite, .code],
//            accessRoles: [.teamMember, .guest],
//            legacyAccessRole: nil,
//            teamID: selfUser.teamID,
//            isReadReceiptsEnabled: true
//        )

//        let conversation = try await conversationsAPI.createGroupConversation(parameters: params)
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

enum FilterConversationsByCriteria {
    case groupName(String)
    case conversationType(ConversationType?)
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
