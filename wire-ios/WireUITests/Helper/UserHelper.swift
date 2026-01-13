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

    let authenticationAPI: AuthenticationAPI
    let teamsAPI: TeamsAPI
    let selfUserAPI: SelfUserAPI
    let conversationsAPI: ConversationsAPI
    let connectionsAPI: ConnectionsAPI

    private let cookieStorage = MockCookieStorage()
    private let authenticationManager = MockAuthManager()

    init(apiVersion: APIVersion = .v8) {

        self.createdUsers = []
        self.networkStack = NetworkStack(
            backendEnvironment: BackendContext.backendEnvironment,
            minTLSVersion: .v1_2,
            cookieEncryptionKey: Data(),
            authenticationManager: authenticationManager
        )

        self.authenticationAPI = AuthenticationAPIBuilder(networkService: networkStack.apiNetworkService)
            .makeAPI(for: apiVersion)
        self.selfUserAPI = SelfUserAPIBuilder(apiService: networkStack.apiService).makeAPI(for: apiVersion)
        self.teamsAPI = TeamsAPIBuilder(apiService: networkStack.apiService)
            .makeAPI(for: apiVersion)
        self.conversationsAPI = ConversationsAPIBuilder(apiService: networkStack.apiService).makeAPI(for: apiVersion)
        self.connectionsAPI = ConnectionsAPIBuilder(apiService: networkStack.apiService).makeAPI(for: apiVersion)
    }

    func basicAuth(_ backend: BackendTarget = BackendContext.current) -> String {
        switch backend {
        case .staging:
            guard let auth = ProcessInfo.processInfo.environment["BASIC_AUTH"] else {
                fatalError("Missing BASIC_AUTH environment variable")
            }
            return auth

        case .anta:
            guard let auth = ProcessInfo.processInfo.environment["BASIC_AUTH_ANTA"] else {
                fatalError("Missing BASIC_AUTH_ANTA environment variable")
            }
            return auth
        }
    }

    func createPersonalUser() async throws -> UserInfo {
        let user = UserGenerator.generateUniqueUserInfo()

        // Start registration
        let cookies = try await authenticationAPI.registerPersonalAccount(
            name: user.name,
            email: user.email,
            password: user.password
        )
        cookieStorage.cookies = cookies

        // Get activation code
        let (activationCode, activationKey) = try await authenticationAPI.getActivationCode(
            forEmail: user.email,
            basicAuth: basicAuth()
        )

        // Activate user
        try await authenticationAPI.activateUser(email: user.email, key: activationKey, code: activationCode)

        // get accessToken for current user
        let (_, accessToken) = try await authenticationAPI.login(
            email: user.email,
            password: user.password,
            verificationCode: nil,
            label: nil
        )

        authenticationManager.accessToken = accessToken

        // Set username
        try await selfUserAPI.updateHandle(handle: user.username)

        // Store id in UserInfo
        let selfUser = try await selfUserAPI.getSelfUser()
        user.id = selfUser.id.uuidString

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

    func registerUserAsTeamOwner() async throws -> (qualifiedID: QualifiedID, owner: UserInfo) {
        let teamOwner = UserGenerator.generateUniqueUserInfo()

        let (teamID, qualifiedId) = try await authenticationAPI.registerTeamOwner(
            email: teamOwner.email,
            password: teamOwner.password,
            name: teamOwner.name,
            teamName: teamOwner.teamName
        )

        teamOwner.teamID = teamID

        // Get activation code
        let (activationCode, activationKey) = try await authenticationAPI.getActivationCode(
            forEmail: teamOwner.email,
            basicAuth: basicAuth()
        )

        // Activate user
        try await authenticationAPI.activateUser(email: teamOwner.email, key: activationKey, code: activationCode)

        authenticationManager.accessToken = try await fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )

        // Set username
        try await selfUserAPI.updateHandle(handle: teamOwner.username)

        createdUsers.append(teamOwner)
        return (qualifiedID: qualifiedId, owner: teamOwner)
    }

    func fetchAccessToken(email: String, password: String) async throws -> AccessToken {
        let (_, accessToken) = try await authenticationAPI.login(
            email: email,
            password: password,
            verificationCode: nil,
            label: nil
        )

        return accessToken
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
        -> (conversationID: UUID?, domain: String?) {
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

    func createGroupConversations(
        qualifiedIds: [QualifiedID],
        owner: UserInfo,
        groupName: String
    ) async throws {

        let params = CreateGroupConversationParameters(
            groupType: .group,
            messageProtocol: .proteus,
            creatorClientID: "deprecated",
            qualifiedUserIDs: qualifiedIds,
            unqualifiedUserIDs: [],
            name: groupName,
            accessMode: [.invite, .code],
            accessRoles: [.teamMember, .guest, .app, .nonTeamMember],
            legacyAccessRole: nil,
            teamID: owner.teamID,
            isReadReceiptsEnabled: true
        )

        let (_, accessToken) = try await authenticationAPI.login(
            email: owner.email,
            password: owner.password,
            verificationCode: nil,
            label: nil
        )
        authenticationManager.accessToken = accessToken

        _ = try await conversationsAPI.createGroupConversation(parameters: params)
    }

    func sendConnectionRequestToUser(
        domain: String,
        userId: String
    ) async throws {

        _ = try await connectionsAPI.sendConnectionRequest(domain: domain, userId: userId)
    }

    func acceptConnectionRequestFromUser(
        domain: String,
        user1: UserInfo,
        userId: String
    ) async throws {

        let (_, accessToken) = try await authenticationAPI.login(
            email: user1.email,
            password: user1.password,
            verificationCode: nil,
            label: nil
        )
        authenticationManager.accessToken = accessToken

        try await connectionsAPI.acceptConnectionRequest(domain: domain, userId: userId)
    }
}

extension BackendEnvironment {
    static let backendURL = "https://\(ProcessInfo.processInfo.environment["BACKEND_URL"]!)"
    static let backendURLAnta = "https://\(ProcessInfo.processInfo.environment["BACKEND_URL_ANTA"]!)"
    static let staging = BackendEnvironment(
        url: URL(string: backendURL)!,
        webSocketURL: URL(string: backendURL)!,
        blacklistURL: URL(string: backendURL)!,
        pinnedKeys: [],
        proxySettings: nil
    )

    static let anta = BackendEnvironment(
        url: URL(string: backendURLAnta)!,
        webSocketURL: URL(string: backendURLAnta)!,
        blacklistURL: URL(string: backendURLAnta)!,
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

class MockAuthManager: AuthenticationManagerProtocol {

    enum AccessTokenError: Error {
        case notImplemented
    }

    var accessToken: WireNetwork.AccessToken?

    func getValidAccessToken() async throws -> WireNetwork.AccessToken {
        guard let accessToken else {
            throw AccessTokenError.notImplemented
        }
        return accessToken
    }

    func refreshAccessToken() async throws -> WireNetwork.AccessToken {
        throw AccessTokenError.notImplemented
    }
}
