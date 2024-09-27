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

import WireFoundation
import WireUtilities
import XCTest
@testable import WireSyncEngine

final class DummyServiceUser: NSObject, ServiceUser {
    func cancelConnectionRequest(completion: @escaping (Error?) -> Void) {}

    func connect(completion: @escaping (Error?) -> Void) {}

    func block(completion: @escaping (Error?) -> Void) {}

    func accept(completion: @escaping (Error?) -> Void) {}

    func ignore(completion: @escaping (Error?) -> Void) {}

    var remoteIdentifier: UUID?

    var isIgnored = false

    var membership: Member?

    var hasTeam = false

    var isTrusted = false

    var hasLegalHoldRequest = false

    var needsRichProfileUpdate = false

    var availability: Availability = .none

    var teamName: String?

    var isBlocked = false

    var blockState: ZMBlockState = .none

    var isExpired = false

    var isPendingApprovalBySelfUser = false

    var isPendingApprovalByOtherUser = false

    var isWirelessUser = false

    var isUnderLegalHold = false

    var allClients: [UserClientType] = []

    var expiresAfter: TimeInterval = 0

    var readReceiptsEnabled = true

    var isVerified = false

    var isPendingMetadataRefresh = false

    var richProfile: [UserRichProfileField] = []

    /// Whether the user can create conversations.
    @objc
    func canCreateConversation(type: ZMConversationType) -> Bool {
        true
    }

    var canCreateService = false

    var canManageTeam = false

    func canAccessCompanyInformation(of user: UserType) -> Bool {
        false
    }

    func canAddUser(to conversation: ConversationLike) -> Bool {
        false
    }

    func canRemoveUser(from conversation: ZMConversation) -> Bool {
        false
    }

    func canAddService(to conversation: ZMConversation) -> Bool {
        false
    }

    func canDeleteConversation(_: ZMConversation) -> Bool {
        false
    }

    func canRemoveService(from conversation: ZMConversation) -> Bool {
        false
    }

    func canModifyReadReceiptSettings(in conversation: ConversationLike) -> Bool {
        false
    }

    func canModifyEphemeralSettings(in conversation: ConversationLike) -> Bool {
        false
    }

    func canModifyNotificationSettings(in conversation: ConversationLike) -> Bool {
        false
    }

    func canModifyAccessControlSettings(in conversation: ConversationLike) -> Bool {
        false
    }

    func canModifyTitle(in conversation: ConversationLike) -> Bool {
        false
    }

    func canModifyOtherMember(in conversation: ZMConversation) -> Bool {
        false
    }

    func canLeave(_: ZMConversation) -> Bool {
        false
    }

    func isGroupAdmin(in conversation: ConversationLike) -> Bool {
        false
    }

    var domain: String?

    var previewImageData: Data?

    var completeImageData: Data?

    var name: String? = "Service user"

    var displayName = "Service"

    var initials: String? = "S"

    var handle: String? = "service"

    var emailAddress: String? = "dummy@email.com"

    var phoneNumber: String?

    var isSelfUser = false

    var smallProfileImageCacheKey: String? = ""

    var mediumProfileImageCacheKey: String? = ""

    var isConnected = false

    var oneToOneConversation: ZMConversation?

    var accentColorValue: ZMAccentColorRawValue = AccentColor.amber.rawValue

    var zmAccentColor: ZMAccentColor? {
        .from(rawValue: accentColorValue)
    }

    var imageMediumData: Data! = Data()

    var imageSmallProfileData: Data! = Data()

    var imageSmallProfileIdentifier: String! = ""

    var imageMediumIdentifier: String! = ""

    var isTeamMember = false

    var hasDigitalSignatureEnabled = false

    var teamRole: TeamRole = .member

    var canBeConnected = false

    var isServiceUser = true

    var isFederated = false

    var usesCompanyLogin = false

    var isAccountDeleted = false

    var managedByWire = true

    var extendedMetadata: [[String: String]]?

    var activeConversations: Set<ZMConversation> = Set()

    func requestPreviewProfileImage() {}

    func requestCompleteProfileImage() {}

    func imageData(for size: ProfileImageSize) -> Data? {
        nil
    }

    func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (Data?) -> Void) {
        completion(nil)
    }

    func refreshData() {}

    func refreshRichProfile() {}

    func refreshMembership() {}

    func refreshTeamData() {}

    func isGuest(in conversation: ConversationLike) -> Bool {
        false
    }

    var canCreateMLSGroups = false

    var connectionRequestMessage: String? = ""

    var totalCommonConnections: UInt = 0

    var serviceIdentifier: String?
    var providerIdentifier: String?

    init(serviceIdentifier: String, providerIdentifier: String) {
        self.serviceIdentifier = serviceIdentifier
        self.providerIdentifier = providerIdentifier
        super.init()
    }
}

final class ServiceUserTests: IntegrationTest {
    override public func setUp() {
        super.setUp()
        createSelfUserAndConversation()
        createExtraUsersAndConversations()

        XCTAssertTrue(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func createService() -> ServiceUser {
        var mockServiceId: String!
        var mockProviderId: String!
        mockTransportSession.performRemoteChanges { remoteChanges in
            let mockService = remoteChanges.insertService(
                withName: "Service A",
                identifier: UUID().transportString(),
                provider: UUID().transportString()
            )

            mockServiceId = mockService.identifier
            mockProviderId = mockService.provider
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        return DummyServiceUser(serviceIdentifier: mockServiceId, providerIdentifier: mockProviderId)
    }

    func testThatItAddsServiceToExistingConversation() throws {
        // given
        let jobIsDone = customExpectation(description: "service is added")
        let service = createService()
        let conversation = conversation(for: groupConversation)!

        // when
        var result: Result<Void, Error>!
        conversation.add(serviceUser: service, in: userSession!) {
            result = $0
            jobIsDone.fulfill()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNoThrow(try result.get())
    }

    func testThatItCreatesConversationAndAddsUser() {
        // given
        let jobIsDone = customExpectation(description: "service is added")
        let service = createService()

        // when
        service.createConversation(in: userSession!) { result in
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("expected '.success'")
            }
            jobIsDone.fulfill()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDetectsTheConversationFullResponse() {
        // GIVEN
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 403,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
        // WHEN
        let error = AddBotError(response: response)
        // THEN
        XCTAssertEqual(error, .tooManyParticipants)
    }

    func testThatItDetectsBotRejectedResponse() {
        // GIVEN
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 419,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
        // WHEN
        let error = AddBotError(response: response)
        // THEN
        XCTAssertEqual(error, .botRejected)
    }

    func testThatItDetectsBotNotResponding() {
        // GIVEN
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 502,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
        // WHEN
        let error = AddBotError(response: response)
        // THEN
        XCTAssertEqual(error, .botNotResponding)
    }

    func testThatItDetectsGeneralError() {
        // GIVEN
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 500,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
        // WHEN
        let error = AddBotError(response: response)
        // THEN
        XCTAssertEqual(error, .general)
    }
}
