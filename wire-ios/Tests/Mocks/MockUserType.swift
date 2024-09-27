//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireDataModel
import WireFoundation
@testable import Wire

class MockUserType: NSObject, UserType, Decodable, EditableUserType {
    // MARK: Lifecycle

    // MARK: - Decodable

    required convenience init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try? container.decode(String.self, forKey: .name)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.initials = try? container.decode(String.self, forKey: .initials)
        self.handle = try? container.decode(String.self, forKey: .handle)
        self.domain = try? container.decode(String.self, forKey: .domain)
        self.isConnected = (try? container.decode(Bool.self, forKey: .isConnected)) ?? false
        if let rawAccentColorValue = try? container.decode(Int16.self, forKey: .accentColorValue),
           let zmAccentColor = ZMAccentColor.from(rawValue: rawAccentColorValue) {
            self.zmAccentColor = zmAccentColor
        }
    }

    // MARK: Internal

    // MARK: - dummy user names

    static let usernames = [
        "Anna",
        "Claire",
        "Dean",
        "Erik",
        "Frank",
        "Gregor",
        "Hanna",
        "Inge",
        "James",
        "Laura",
        "Klaus",
        "Lena",
        "Linea",
        "Lara",
        "Elliot",
        "Francois",
        "Felix",
        "Brian",
        "Brett",
        "Hannah",
        "Ana",
        "Paula",
    ]

    // MARK: - MockHelpers

    var isTrusted = true

    let legalHoldDataSource = MockLegalHoldDataSource()

    var teamIdentifier: UUID?
    var remoteIdentifier: UUID?

    var canLeaveConversation = false
    var canCreateConversation = true
    var canDeleteConversation = false
    var canAddUserToConversation = true
    var canRemoveUserFromConversation = true
    var canAddServiceToConversation = false
    var canRemoveService = false
    var canModifyOtherMemberInConversation = false
    var canModifyTitleInConversation = false
    var canModifyReadReceiptSettingsInConversation = false
    var canModifyEphemeralSettingsInConversation = false
    var canModifyNotificationSettingsInConversation = false
    var canModifyAccessControlSettings = false
    var isGroupAdminInConversation = false
    var isGuestInConversation = false
    var isPendingMetadataRefresh = false

    // MARK: - UserType Conformance

    // MARK: Basic Properties

    var domain: String?

    var name: String?

    var displayName = ""

    var initials: String?

    var handle: String?

    var emailAddress: String?

    var phoneNumber: String? = "+123456789"

    var accentColorValue: ZMAccentColorRawValue = AccentColor.blue.rawValue

    var availability: Availability = .none

    var allClients: [UserClientType] = []

    var smallProfileImageCacheKey: String?

    var mediumProfileImageCacheKey: String?

    var previewImageData: Data?

    var completeImageData: Data?

    var richProfile: [UserRichProfileField] = []

    var readReceiptsEnabled = false

    // MARK: - Conversations

    var oneToOneConversation: ZMConversation?

    var activeConversations: Set<ZMConversation> = Set()

    // MARK: - Querying

    var isFederated = false

    var isSelfUser = false

    var mockedIsServiceUser = false
    var isVerified = false

    // MARK: - Team

    var membership: Member?

    var hasTeam = false

    var hasDigitalSignatureEnabled = false

    var teamName: String?

    var teamRole: TeamRole = .none

    // MARK: - Connections

    var canBeConnected = false

    var isConnected = false

    var isBlocked = false

    var blockState: ZMBlockState = .none

    var isIgnored = false

    var isPendingApprovalBySelfUser = false

    var isPendingApprovalByOtherUser = false

    // MARK: - Wireless

    var isWirelessUser = false

    var isExpired = false

    var expiresAfter: TimeInterval = 0

    // MARK: Misc

    var usesCompanyLogin = false

    var managedByWire = false

    var isAccountDeleted = false

    var isUnderLegalHold = false

    var needsRichProfileUpdate = false

    // MARK: - Capabilities

    var canCreateService = false

    var canManageTeam = false

    var canCreateMLSGroups = false

    // MARK: - Refresh requests

    var refreshDataCount = 0
    var refreshRichProfileCount = 0
    var refreshMembershipCount = 0
    var refreshTeamDataCount = 0

    var zmAccentColor: ZMAccentColor? {
        get { .from(rawValue: accentColorValue) }
        set { accentColorValue = newValue?.rawValue ?? 0 }
    }

    var isServiceUser: Bool {
        mockedIsServiceUser
    }

    var isTeamMember: Bool {
        teamIdentifier != nil
    }

    func accept(completion: @escaping (Error?) -> Void) {
        isBlocked = false
    }

    func block(completion: @escaping (Error?) -> Void) {
        isBlocked = true
    }

    func ignore(completion: @escaping (Error?) -> Void) {}

    func cancelConnectionRequest(completion: @escaping (Error?) -> Void) {}

    func canLeave(_: ZMConversation) -> Bool {
        canLeaveConversation
    }

    func canCreateConversation(type: ZMConversationType) -> Bool {
        canCreateConversation
    }

    func canDeleteConversation(_: ZMConversation) -> Bool {
        canDeleteConversation
    }

    func canAddUser(to conversation: ConversationLike) -> Bool {
        canAddUserToConversation
    }

    func canRemoveUser(from conversation: ZMConversation) -> Bool {
        canRemoveUserFromConversation
    }

    func canAddService(to conversation: ZMConversation) -> Bool {
        canAddServiceToConversation
    }

    func canRemoveService(from conversation: ZMConversation) -> Bool {
        canRemoveService
    }

    func canAccessCompanyInformation(of user: UserType) -> Bool {
        guard
            let otherUser = user as? MockUserType,
            let teamIdentifier,
            let otherTeamIdentifier = otherUser.teamIdentifier
        else {
            return false
        }

        return teamIdentifier == otherTeamIdentifier
    }

    func canModifyOtherMember(in conversation: ZMConversation) -> Bool {
        canModifyOtherMemberInConversation
    }

    func canModifyTitle(in conversation: ConversationLike) -> Bool {
        canModifyTitleInConversation
    }

    func canModifyReadReceiptSettings(in conversation: ConversationLike) -> Bool {
        canModifyReadReceiptSettingsInConversation
    }

    func canModifyEphemeralSettings(in conversation: ConversationLike) -> Bool {
        canModifyEphemeralSettingsInConversation
    }

    func canModifyNotificationSettings(in conversation: ConversationLike) -> Bool {
        canModifyNotificationSettingsInConversation
    }

    func canModifyAccessControlSettings(in conversation: ConversationLike) -> Bool {
        canModifyAccessControlSettings
    }

    func isGroupAdmin(in conversation: ConversationLike) -> Bool {
        isGroupAdminInConversation
    }

    // MARK: - Methods

    func connect(completion: @escaping (Error?) -> Void) {
        // No op
    }

    func isGuest(in conversation: ConversationLike) -> Bool {
        isGuestInConversation
    }

    func requestPreviewProfileImage() {
        // No op
    }

    func requestCompleteProfileImage() {
        // No op
    }

    func imageData(for size: ProfileImageSize) -> Data? {
        switch size {
        case .preview:
            previewImageData
        case .complete:
            completeImageData
        }
    }

    func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (Data?) -> Void) {
        switch size {
        case .preview:
            completion(previewImageData)
        case .complete:
            completion(completeImageData)
        }
    }

    func refreshData() {
        refreshDataCount += 1
    }

    func refreshRichProfile() {
        refreshRichProfileCount += 1
    }

    func refreshMembership() {
        refreshMembershipCount += 1
    }

    func refreshTeamData() {
        refreshTeamDataCount += 1
    }
}
