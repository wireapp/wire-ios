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

    let backendURL = BackendContext.backendEnvironment.url
    var createdUsers: [UserInfo]
    var networkStack: NetworkStack

    let apiVersion: APIVersion

    let authenticationAPI: AuthenticationAPI
    let teamsAPI: TeamsAPI
    let selfUserAPI: SelfUserAPI
    let conversationsAPI: ConversationsAPI
    let connectionsAPI: ConnectionsAPI
    let accountsAPI: AccountsAPI

    private let cookieStorage = MockCookieStorage()
    private let authenticationManager = MockAuthManager()

    init(apiVersion: APIVersion = APIVersion.productionVersions.max()!) {
        self.apiVersion = apiVersion
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
        self.accountsAPI = AccountsAPIBuilder(apiService: networkStack.apiService).makeAPI(for: apiVersion)
    }

    /// Fetch basicAuth Info from Env variable
    /// - Parameter backend: backend
    /// - Returns: basicAuth String
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

    /// Create Personal user
    /// - Returns: Newly created UserInfo
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

    /// Add every user to object
    /// - Parameter user: userInfo
    func addUser(_ user: UserInfo) {
        createdUsers.append(user)
    }

    /// Add user
    /// - Parameters:
    ///   - email: email
    ///   - password: password
    func addUser(email: String, password: String) {
        createdUsers.append(UserInfo(email: email, password: password))
    }

    /// Delete user
    /// - Parameter user: userInfo
    func deleteUser(_ user: UserInfo) async throws {
        try await selfUserAPI.deleteSelf(password: user.password)
    }

    /// Get conversationId
    /// - Returns: qualifiedIds Object
    func getConversationIds() async throws -> [QualifiedID] {
        var conversationIDs = [QualifiedID]()
        for try await ids in try await conversationsAPI.getConversationIdentifiers() {
            conversationIDs.append(contentsOf: ids)
        }
        return conversationIDs
    }

    /// Delete created test team
    /// - Parameters:
    ///   - teamID: teamID
    ///   - password: password
    ///   - code: verificationCode
    func deleteTeam(teamID: UUID, password: String, code: String) async throws {
        try await selfUserAPI.deleteTeam(
            teamId: teamID,
            password: password,
            verificationCode: code
        )
    }

    /// Upgrade personal user to Team
    /// - Parameter teamName: teamName
    /// - Returns: teamId
    func upgradePersonalToTeam(teamName: String) async throws -> UUID {
        let response = try await accountsAPI.upgradeToTeam(teamName: teamName)

        return response.teamId
    }

    func getVerificationCode(user: UserInfo) async throws -> String {
        try await InbucketClient.getVerificationCode(email: user.email)
    }
    
    /// Delete  created test users
    func deleteCreatedUsers() async {
        for user in createdUsers {
            do {
                if let teamID = try await selfUserAPI.getSelfUser().teamID {
                    // If team exists, try deleting the team
                    try await authenticationAPI.requestVerificationCode(for: user.email)
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

    /// Register a team owner
    /// - Returns: qualifiedId of the owner and ownerInfo
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

    /// get accesstoken of user by email and password
    /// - Parameters:
    ///   - email: email
    ///   - password: password
    /// - Returns: AccesstToken response
    func fetchAccessToken(email: String, password: String) async throws -> AccessToken {
        let (_, accessToken) = try await authenticationAPI.login(
            email: email,
            password: password,
            verificationCode: nil,
            label: nil
        )

        return accessToken
    }


    /// Disable GDPR consent popup
    /// - Parameter user: userInfo
    func disableConsentPopup(for user: UserInfo) async throws {

        let baseURL = BackendContext.backendEnvironment.url
        let versionedURL = baseURL
            .appendingPathComponent(String(describing: apiVersion))
            .appendingPathComponent("properties")
            .appendingPathComponent("webapp")

        let accessToken = try await fetchAccessToken(email: user.email, password: user.password)

        let body: [String: Any] = [
            "settings": [
                "privacy": [
                    "improve_wire": false,
                    "marketing_consent": false,
                    "telemetry_data_sharing": false
                ]
            ]
        ]

        var request = URLRequest(url: versionedURL)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken.token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        func send(_ url: URL) async throws -> HTTPURLResponse {
            var r = request
            r.url = url
            let (data, response) = try await URLSession.shared.data(for: r)
            return response as! HTTPURLResponse
        }

        let responseCode = try await send(versionedURL)
        if responseCode.statusCode == 200 {
            return
        }
    }

        /// Register user in team as member
        /// - Parameters:
        ///   - ownerAccessToken: ownerAccessToken
        ///   - teamID: teamID
        /// - Returns: qualifiedId and memberInfo
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


    func registerUsersAsTeamMemberWithUserHandleSet(
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

        // get access token
        authenticationManager.accessToken = try await fetchAccessToken(
            email: teamMember.email,
            password: teamMember.password
        )

        // Set handle
        try await selfUserAPI.updateHandle(handle: teamMember.username)

        createdUsers.append(teamMember)

        return (qualifiedID, teamMember)
    }

        /// fetch qualified id from conversations
        /// - Returns: qualifiedID object
    func getQualifiedIdsFromConversationList() async throws -> [QualifiedID] {
        var conversationIDs = [QualifiedID]()

        for try await ids in try await conversationsAPI.getConversationIdentifiers() {
            conversationIDs.append(contentsOf: ids)
        }
        return conversationIDs
    }

    /// fetch conversationId based on name or type
    /// - Parameter criteria: pass the criteria to filter conversations
    /// - Returns: conversation UUID and domain info
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

    /// Create group conversation
    /// - Parameters:
    ///   - qualifiedIds: qualifiedIds for members of the group
    ///   - owner: group owner
    ///   - groupName: groupName
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

    /// Registers a set of teams for a specific owner.
    ///
    /// - Parameter teamOwner: The user information of the person who will own the teams.
    /// - Returns: An array of members name.
    func registerTeamWith2Members(teamOwner: UserInfo) async throws -> [String] {
        guard let teamID = teamOwner.teamID else {
            return []
        }

        let ownerAccessToken = try await fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )

        let (_, teamMember1) = try await registerUsersAsTeamMember(
            ownerAccessToken: ownerAccessToken.token,
            teamID: teamID,
        )

        let (_, teamMember2) = try await registerUsersAsTeamMember(
            ownerAccessToken: ownerAccessToken.token,
            teamID: teamID,
        )
        return [teamMember1.name, teamMember2.name]
    }

    /// Registers number of members..
    /// - Parameters:
    ///   - teamOwner: team owner
    ///   - memberCount: count of members
    /// - Returns: 
    func registerTeamWithXMembersAndOptionalGroup(
        memberCount: Int,
        groupName: String? = nil
    ) async throws
        -> (teamOwner: UserInfo, teamMembers: [UserInfo], qualifiedIDs: [QualifiedID], conversationId: UUID?) {

        let (_, teamOwner) = try await registerUserAsTeamOwner()
        guard let teamID = teamOwner.teamID else {
            throw RuntimeError("registerTeamWithMembersAndOptionalGroup: teamOwner.teamID is nil")
        }

        let ownerAccessToken = try await fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )

        var qualifiedIDs: [QualifiedID] = []
        qualifiedIDs.reserveCapacity(memberCount)

        var teamMembers: [UserInfo] = []
        teamMembers.reserveCapacity(memberCount)

        for _ in 0 ..< memberCount {
            let (qualifiedId, teamMember) = try await registerUsersAsTeamMemberWithUserHandleSet(
                ownerAccessToken: ownerAccessToken.token,
                teamID: teamID
            )
            qualifiedIDs.append(qualifiedId)
            teamMembers.append(teamMember)
        }

        // if group conversation passed
        var conversationId: UUID?
        if let groupName {
            try await createGroupConversations(
                qualifiedIds: qualifiedIDs,
                owner: teamOwner,
                groupName: groupName
            )

            let (resolvedConversationId, _) = try await getConversationId(matching: .groupName(groupName))
            guard let resolvedConversationId else {
                throw RuntimeError(
                    "registerTeamWithMembersAndOptionalGroup: Failed to resolve conversationId for group \(groupName)"
                )
            }
            conversationId = resolvedConversationId
        }

        // unlock and enable ConferenceCalling
        let backOffice = BackOffice(backendURL: backendURL)
        try await backOffice.unlockConferenceCallingFeature(teamId: teamID.uuidString, basicAuth: basicAuth())
        try await backOffice.enableConferenceCallingFeature(
            teamId: teamID.uuidString,
            basicAuth: basicAuth()
        )

        return (
            teamOwner: teamOwner,
            teamMembers: teamMembers,
            qualifiedIDs: qualifiedIDs,
            conversationId: conversationId
        )
    }
    
    /// Send connection request
    /// - Parameters:
    ///   - domain: domain info
    ///   - userId: userId info
    func sendConnectionRequestToUser(
        domain: String,
        userId: String
    ) async throws {

        _ = try await connectionsAPI.sendConnectionRequest(domain: domain, userId: userId)
    }

    /// Accept connection request from user
    /// - Parameters:
    ///   - domain: domain
    ///   - user1: user1-sender
    ///   - userId: userId description
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
