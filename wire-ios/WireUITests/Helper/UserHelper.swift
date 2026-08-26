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
import os
import WireNetwork

struct Member {
    let name: String
    let email: String
    let password: String
    var id: String?
}

final class UserHelper {
    private struct InstanceKey: Hashable {
        let apiVersion: APIVersion
        let backend: BackendTarget
    }

    private static var instances = OSAllocatedUnfairLock<[InstanceKey: UserHelper]>(uncheckedState: [:])

    private let httpClient = HttpClient()

    let backend: BackendTarget
    let backendURL: URL
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
    private let environment: BackendEnvironment

    static func instance(
        apiVersion: APIVersion = APIVersion.productionVersions.max()!,
        backend: BackendTarget = .staging
    ) -> UserHelper {
        let key = InstanceKey(apiVersion: apiVersion, backend: backend)

        if let instance = instances.withLock({ $0[key] }) {
            return instance
        }

        let instance = UserHelper(apiVersion: apiVersion, backend: backend)
        instances.withLock { $0[key] = instance }
        return instance
    }

    static var `default`: UserHelper {
        instance(
            apiVersion: APIVersion.productionVersions.max()!,
            backend: .staging
        )
    }

    /// Deletes users created by all instances of UserHelper.
    static func deleteCreatedUsers() async {
        let instances = instances.withLock { $0 }.values

        for instance in instances {
            await instance.deleteCreatedUsers()
        }
    }

    private init(
        apiVersion: APIVersion,
        backend: BackendTarget
    ) {
        let environment = backend.environment

        self.backend = backend
        self.apiVersion = apiVersion
        self.backendURL = environment.url
        self.createdUsers = []
        self.networkStack = NetworkStack(
            backendEnvironment: environment,
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
        self.environment = environment
    }

    /// Fetch basicAuth Info from Env variable
    /// - Returns: basicAuth String
    func basicAuth() -> String {
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

        case .bella:
            guard let auth = ProcessInfo.processInfo.environment["BASIC_AUTH_BELLA"] else {
                fatalError("Missing BASIC_AUTH_BELLA environment variable")
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
        for try await ids in try conversationsAPI.getConversationIdentifiers() {
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
        try await InbucketClient.getVerificationCode(email: user.email, backend: backend)
    }

    /// Delete created test users for this helper instance.
    private func deleteCreatedUsers() async {
        let users = createdUsers
        createdUsers.removeAll()

        defer {
            cookieStorage.cookies = []
            authenticationManager.accessToken = nil
        }

        for user in users {
            do {
                if let teamID = try await selfUserAPI.getSelfUser().teamID {
                    // If team exists, try deleting the team
                    try await authenticationAPI.requestVerificationCode(for: user.email)
                    let code = try await InbucketClient.getVerificationCode(email: user.email, backend: backend)
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
        let generated = UserGenerator.generateUniqueUserInfo()
        return try await registerUserAsTeamOwner(teamName: generated.teamName)
    }

    /// Register a team owner with a provided team name.
    /// - Parameter teamName: team name to create.
    /// - Returns: qualifiedId of the owner and ownerInfo
    func registerUserAsTeamOwner(
        teamName: String,
        preferredName: String? = nil
    ) async throws -> (qualifiedID: QualifiedID, owner: UserInfo) {

        let teamOwner = UserGenerator.generateUniqueUserInfo(preferredName: preferredName)
        teamOwner.teamName = teamName

        let (teamID, qualifiedId) = try await authenticationAPI.registerTeamOwner(
            email: teamOwner.email,
            password: teamOwner.password,
            name: teamOwner.name,
            teamName: teamOwner.teamName
        )

        teamOwner.teamID = teamID

        let (activationCode, activationKey) = try await authenticationAPI.getActivationCode(
            forEmail: teamOwner.email,
            basicAuth: basicAuth()
        )

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

        let baseURL = environment.url
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

        let jsonBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (_, response) = try await httpClient.send(
            url: versionedURL,
            method: .put,
            body: jsonBody,
            headers: [
                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
                HttpClient.HeaderKey.authorization: "Bearer \(accessToken.token)"
            ]
        )
        guard response.statusCode == 200 else {
            throw RuntimeError("disableConsentPopup failed with code \(response.statusCode)")
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
            invitationID: invitationID,
            basicAuth: basicAuth()
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
        teamID: UUID,
        preferredName: String? = nil
    ) async throws -> (qualifiedID: QualifiedID, member: UserInfo) {

        let teamMember = UserGenerator.generateUniqueUserInfo(preferredName: preferredName)

        let invitationID = try await teamsAPI.inviteMemberToTeam(
            access_token: ownerAccessToken,
            teamID: teamID,
            memberName: teamMember.name,
            memberEmail: teamMember.email
        )

        let invitationCode = try await authenticationAPI.getInvitationCode(
            teamID: teamID,
            invitationID: invitationID,
            basicAuth: basicAuth()
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

        for try await ids in try conversationsAPI.getConversationIdentifiers() {
            conversationIDs.append(contentsOf: ids)
        }
        return conversationIDs
    }

    /// fetch conversationId based on name or type
    /// - Parameter criteria: pass the criteria to filter conversations
    /// - Returns: conversation UUID and domain info
    func getConversationId(matching criteria: FilterConversationsByCriteria) async throws
        -> (conversationID: UUID, domain: String?) {
        let conversationIDs = try await getQualifiedIdsFromConversationList()

        let conversations = try await conversationsAPI.getConversations(for: conversationIDs)

        let filtered = conversations.found.filter { conversation in
            switch criteria {
            case let .conversationName(name):
                conversation.name == name
            case let .conversationType(type):
                conversation.type == type
            }
        }

        if let match = filtered.first, let id = match.qualifiedID?.id {
            return (id, match.qualifiedID?.domain)
        }
        throw RuntimeError("getConversationId: no matching conversation found")
    }

    /// Create group conversation
    /// - Parameters:
    ///   - qualifiedIds: qualifiedIds for members of the group
    ///   - owner: group owner
    ///   - groupName: groupName
    ///   - driveEnabled: bool
    @discardableResult
    func createGroupConversations(
        qualifiedIds: [QualifiedID],
        owner: UserInfo,
        groupName: String,
        driveEnabled: Bool = false
    ) async throws -> Conversation {

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
            isReadReceiptsEnabled: true,
            cells: driveEnabled
        )

        let (_, accessToken) = try await authenticationAPI.login(
            email: owner.email,
            password: owner.password,
            verificationCode: nil,
            label: nil
        )
        authenticationManager.accessToken = accessToken

        return try await conversationsAPI.createGroupConversation(parameters: params)
    }

    /// Create channel conversation
    /// - Parameters:
    ///   - qualifiedIds: qualifiedIds for members of the channel
    ///   - owner: group owner
    ///   - groupName: groupName
    func createChannelConversations(
        qualifiedIds: [QualifiedID],
        owner: UserInfo,
        channelName: String
    ) async throws {

        let params = CreateGroupConversationParameters(
            groupType: .channel,
            messageProtocol: .mls,
            creatorClientID: "deprecated",
            qualifiedUserIDs: qualifiedIds,
            unqualifiedUserIDs: [],
            name: channelName,
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

    /// Registers a team with a given number of members and optionally creates a group or channel conversation
    /// - Parameters:
    ///   - memberCount: count of members
    ///   - conversation: optional group or channel conversation to create
    ///   - driveEnabled: whether Drive should be unlocked and enabled for for group
    /// - Returns: teamOwner info, teamMembers info, qualifiedIds of members, conversationId if conversation created
    func registerTeam(
        withMemberCount memberCount: Int = 0,
        conversation: CreateConversationOption? = nil,
        driveEnabled: Bool = false,
        names: [String] = []
    ) async throws
        -> (teamOwner: UserInfo, teamMembers: [UserInfo], qualifiedIDs: [QualifiedID], conversationId: UUID?) {

        let generated = UserGenerator.generateUniqueUserInfo()
        let (_, teamOwner) = try await registerUserAsTeamOwner(
            teamName: generated.teamName,
            preferredName: names.first
        )
        guard let teamID = teamOwner.teamID else {
            throw RuntimeError("registerTeam: teamOwner.teamID is nil")
        }

        if driveEnabled {
            try await unlockAndEnableDriveFeature(teamID: teamID)
        }

        let ownerAccessToken = try await fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )

        var qualifiedIDs: [QualifiedID] = []
        qualifiedIDs.reserveCapacity(memberCount)

        var teamMembers: [UserInfo] = []
        teamMembers.reserveCapacity(memberCount)

        for index in 0 ..< memberCount {
            let (qualifiedId, teamMember) = try await registerUsersAsTeamMemberWithUserHandleSet(
                ownerAccessToken: ownerAccessToken.token,
                teamID: teamID,
                preferredName: names.indices.contains(index + 1) ? names[index + 1] : nil
            )
            qualifiedIDs.append(qualifiedId)
            teamMembers.append(teamMember)
        }

        // if conversation creation is requested
        var conversationId: UUID?
        if let conversation {
            switch conversation {
            case let .group(name):
                try await createGroupConversations(
                    qualifiedIds: qualifiedIDs,
                    owner: teamOwner,
                    groupName: name,
                    driveEnabled: driveEnabled
                )

                let (resolvedConversationId, _) = try await getConversationId(matching: .conversationName(name))
                conversationId = resolvedConversationId

            case let .channel(name):
                // unlock and enable Channels
                let backOffice = BackOffice(backendURL: backendURL)
                let basicAuth = basicAuth()
                try await backOffice.unlockChannelFeature(teamId: teamID.uuidString, basicAuth: basicAuth)
                try await backOffice.enableChannelFeature(teamId: teamID.uuidString, basicAuth: basicAuth)

                try await createChannelConversations(
                    qualifiedIds: qualifiedIDs,
                    owner: teamOwner,
                    channelName: name
                )

                let (resolvedConversationId, _) = try await getConversationId(matching: .conversationName(name))
                conversationId = resolvedConversationId
            }
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

    /// Creates a team group with configurable team-member count and total admin count.
    /// `memberCount` excludes the owner; `groupAdminCount` includes the owner.
    func createGroupConversationWithAdminsAndMembers(
        groupName: String,
        memberCount: Int,
        groupAdminCount: Int,
        preventAdminlessGroupsEnabled: Bool = false
    ) async throws -> (
        owner: UserInfo,
        admins: [UserInfo],
        members: [UserInfo],
        conversation: Conversation
    ) {
        let (owner, teamMembers, qualifiedIDs, _) = try await registerTeam(withMemberCount: memberCount)

        guard
            groupAdminCount >= 1,
            groupAdminCount <= memberCount + 1,
            teamMembers.count == memberCount,
            qualifiedIDs.count == memberCount,
            let teamID = owner.teamID
        else {
            throw RuntimeError("createGroupConversationWithAdminsAndMembers: invalid team setup")
        }

        if preventAdminlessGroupsEnabled {
            try await unlockAndEnablePreventAdminlessGroupsFeature(teamID: teamID)
        }

        let conversation = try await createGroupConversations(
            qualifiedIds: qualifiedIDs,
            owner: owner,
            groupName: groupName
        )

        guard let conversationQualifiedID = conversation.qualifiedID else {
            throw RuntimeError("createGroupConversationWithAdminsAndMembers: conversation.qualifiedID is nil")
        }

        let promotedGroupAdminCount = groupAdminCount - 1
        for userID in qualifiedIDs.prefix(promotedGroupAdminCount) {
            try await updateRole(
                "wire_admin",
                userID: userID,
                conversationID: conversationQualifiedID
            )
        }

        let admins = [owner] + Array(teamMembers.prefix(promotedGroupAdminCount))
        let members = Array(teamMembers.dropFirst(promotedGroupAdminCount))

        return (owner, admins, members, conversation)
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

    /// Unlock and Enable Drive feature
    /// - Parameter teamID: teamID where this needs to be enabled
    func unlockAndEnableDriveFeature(teamID: UUID) async throws {
        let backOffice = BackOffice(backendURL: backendURL)
        let basicAuth = basicAuth()
        try await backOffice.getCellsInternal(teamId: teamID.uuidString, basicAuth: basicAuth)
        try await backOffice.unlockCellsFeature(teamId: teamID.uuidString, basicAuth: basicAuth)
        try await backOffice.enableCellsFeature(teamId: teamID.uuidString, basicAuth: basicAuth)
    }

    /// Unlock and Enable Channel feature
    /// - Parameter teamID: teamID where this needs to be enabled
    func unlockAndEnableChannelFeature(teamID: UUID) async throws {
        let backOffice = BackOffice(backendURL: backendURL)
        let basicAuth = basicAuth()
        try await backOffice.unlockChannelFeature(teamId: teamID.uuidString, basicAuth: basicAuth)
        try await backOffice.enableChannelFeature(teamId: teamID.uuidString, basicAuth: basicAuth)
    }

    /// Unlock and enable Prevent Adminless Groups feature
    /// - Parameter teamID: teamID where this needs to be enabled
    func unlockAndEnablePreventAdminlessGroupsFeature(teamID: UUID) async throws {
        let backOffice = BackOffice(backendURL: backendURL)
        let basicAuth = basicAuth()
        try await backOffice.unlockPreventAdminlessGroupsFeature(teamId: teamID.uuidString, basicAuth: basicAuth)
        try await backOffice.enablePreventAdminlessGroupsFeature(teamId: teamID.uuidString, basicAuth: basicAuth)
    }

    func connectDriveEnabledTeamUserWithGuestUser() async throws -> (userA: UserInfo, userB: UserInfo) {
        let (userA, _, _, _) = try await registerTeam(withMemberCount: 1, driveEnabled: true)
        let (userB, _, _, _) = try await registerTeam(withMemberCount: 1)

        // User A
        let (_, accessTokenUserA) = try await authenticationAPI.login(
            email: userA.email,
            password: userA.password,
            verificationCode: nil,
            label: nil
        )
        authenticationManager.accessToken = accessTokenUserA
        let selfUserA = try await selfUserAPI.getSelfUser()
        userA.id = selfUserA.id.uuidString

        // User B
        let (_, accessTokenUserB) = try await authenticationAPI.login(
            email: userB.email,
            password: userB.password,
            verificationCode: nil,
            label: nil
        )
        authenticationManager.accessToken = accessTokenUserB
        let selfUserB = try await selfUserAPI.getSelfUser()
        userB.id = selfUserB.id.uuidString

        // Connects with guest user
        let domain = BackendTarget.staging.domainInfo
        try await sendConnectionRequestToUser(domain: domain, userId: userA.id)
        try await acceptConnectionRequestFromUser(domain: domain, user1: userA, userId: userB.id)

        return (userA, userB)
    }

    func connectTeamUserWithPersonalUser() async throws -> (teamOwner: UserInfo, personalUser: UserInfo) {
        var (userA, _, _, _) = try await registerTeam(withMemberCount: 1, driveEnabled: true)
        var userB = try await createPersonalUser()

        try await login(user: &userA)
        try await login(user: &userB)

        // Connects with personal user
        let domain = BackendTarget.staging.domainInfo
        try await sendConnectionRequestToUser(domain: domain, userId: userA.id)
        try await acceptConnectionRequestFromUser(domain: domain, user1: userA, userId: userB.id)

        return (teamOwner: userA, personalUser: userB)
    }

    func login(user: inout UserInfo) async throws {
        let (_, accessToken) = try await authenticationAPI.login(
            email: user.email,
            password: user.password,
            verificationCode: nil,
            label: nil
        )
        authenticationManager.accessToken = accessToken
        let selfUser = try await selfUserAPI.getSelfUser()
        user.id = selfUser.id.uuidString
    }

    func updateRole(_ role: String, userID: UserID, conversationID: ConversationID) async throws {
        try await conversationsAPI.updateRole(role, userID: userID, conversationID: conversationID)
    }

    func removeParticipant(userID: UserID, conversationID: ConversationID) async throws {
        try await conversationsAPI.removeParticipant(userID: userID, conversationID: conversationID)
    }
}

extension BackendEnvironment {
    static let backendURL = "https://\(ProcessInfo.processInfo.environment["BACKEND_URL"]!)"
    static let backendURLAnta = "https://\(ProcessInfo.processInfo.environment["BACKEND_URL_ANTA"]!)"
    static let backendURLBella = "https://\(ProcessInfo.processInfo.environment["BACKEND_URL_BELLA"]!)"

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

    static let bella = BackendEnvironment(
        url: URL(string: backendURLBella)!,
        webSocketURL: URL(string: backendURLBella)!,
        blacklistURL: URL(string: backendURLBella)!,
        pinnedKeys: [],
        proxySettings: nil
    )
}

extension BackendTarget {
    var environment: BackendEnvironment {
        switch self {
        case .staging:
            .staging
        case .anta:
            .anta
        case .bella:
            .bella
        }
    }
}

enum CreateConversationOption {
    case group(String)
    case channel(String)
}

enum FilterConversationsByCriteria {
    case conversationName(String)
    case conversationType(ConversationType?)
}

private final class MockCookieStorage: CookieStorageProtocol {
    var cookies: [HTTPCookie]

    init() {
        self.cookies = []
    }

    func storeCookies(_ cookies: [HTTPCookie], userID: UUID) throws {
        self.cookies = cookies
    }

    func fetchCookies(userID: UUID) throws -> [HTTPCookie] {
        cookies
    }

    func removeCookies(userID: UUID) throws {
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
        guard let accessToken else {
            throw AccessTokenError.notImplemented
        }
        return accessToken
    }
}
