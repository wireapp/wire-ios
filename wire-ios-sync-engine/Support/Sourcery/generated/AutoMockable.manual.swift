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

public import Foundation
public import WireDomain
public import WireFoundation

import WireAnalytics

@testable import WireSyncEngine

public typealias UserType = WireDataModel.UserType

public class MockMessageSenderInterface: MessageSenderInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - sendMessage

    public var sendMessageMessage_Invocations: [any SendableMessage] = []
    public var sendMessageMessage_MockError: Error?
    public var sendMessageMessage_MockMethod: ((any SendableMessage) async throws -> Void)?

    public func sendMessage(message: any SendableMessage) async throws {
        sendMessageMessage_Invocations.append(message)

        if let error = sendMessageMessage_MockError {
            throw error
        }

        guard let mock = sendMessageMessage_MockMethod else {
            fatalError("no mock for `sendMessageMessage`")
        }

        try await mock(message)
    }

    // MARK: - broadcastMessage

    public var broadcastMessageMessage_Invocations: [any ProteusMessage] = []
    public var broadcastMessageMessage_MockError: Error?
    public var broadcastMessageMessage_MockMethod: ((any ProteusMessage) async throws -> Void)?

    public func broadcastMessage(message: any ProteusMessage) async throws {
        broadcastMessageMessage_Invocations.append(message)

        if let error = broadcastMessageMessage_MockError {
            throw error
        }

        guard let mock = broadcastMessageMessage_MockMethod else {
            fatalError("no mock for `broadcastMessageMessage`")
        }

        try await mock(message)
    }

}

public class MockSessionEstablisherInterface: SessionEstablisherInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - establishSession

    public var establishSessionWithApiVersion_Invocations: [(clients: Set<QualifiedClientID>, apiVersion: APIVersion)] = []
    public var establishSessionWithApiVersion_MockError: Error?
    public var establishSessionWithApiVersion_MockMethod: ((Set<QualifiedClientID>, APIVersion) async throws -> Void)?

    public func establishSession(with clients: Set<QualifiedClientID>, apiVersion: APIVersion) async throws {
        establishSessionWithApiVersion_Invocations.append((clients: clients, apiVersion: apiVersion))

        if let error = establishSessionWithApiVersion_MockError {
            throw error
        }

        guard let mock = establishSessionWithApiVersion_MockMethod else {
            fatalError("no mock for `establishSessionWithApiVersion`")
        }

        try await mock(clients, apiVersion)
    }

}

public class MockMessageAppendableConversation: MessageAppendableConversation {

    // MARK: - Life cycle

    public init() {}

    // MARK: - conversationType

    public var conversationType: ZMConversationType {
        get { return underlyingConversationType }
        set(value) { underlyingConversationType = value }
    }

    public var underlyingConversationType: ZMConversationType!

    // MARK: - localParticipants

    public var localParticipants: Set<ZMUser> {
        get { return underlyingLocalParticipants }
        set(value) { underlyingLocalParticipants = value }
    }

    public var underlyingLocalParticipants: Set<ZMUser>!

    // MARK: - draftMessage

    public var draftMessage: DraftMessage?

    // MARK: - appendText

    public var appendTextContentMentionsReplyingToFetchLinkPreviewNonce_Invocations: [(content: String, mentions: [Mention], quotedMessage: (any ZMConversationMessage)?, fetchLinkPreview: Bool, nonce: UUID)] = []
    public var appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockError: Error?
    public var appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockMethod: ((String, [Mention], (any ZMConversationMessage)?, Bool, UUID) throws -> any ZMConversationMessage)?
    public var appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockValue: (any ZMConversationMessage)?

    @discardableResult
    public func appendText(content: String, mentions: [Mention], replyingTo quotedMessage: (any ZMConversationMessage)?, fetchLinkPreview: Bool, nonce: UUID) throws -> any ZMConversationMessage {
        appendTextContentMentionsReplyingToFetchLinkPreviewNonce_Invocations.append((content: content, mentions: mentions, quotedMessage: quotedMessage, fetchLinkPreview: fetchLinkPreview, nonce: nonce))

        if let error = appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockError {
            throw error
        }

        if let mock = appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockMethod {
            return try mock(content, mentions, quotedMessage, fetchLinkPreview, nonce)
        } else if let mock = appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockValue {
            return mock
        } else {
            fatalError("no mock for `appendTextContentMentionsReplyingToFetchLinkPreviewNonce`")
        }
    }

    // MARK: - appendKnock

    public var appendKnock_Invocations: [UUID] = []
    public var appendKnock_MockError: Error?
    public var appendKnock_MockMethod: ((UUID) throws -> any ZMConversationMessage)?
    public var appendKnock_MockValue: (any ZMConversationMessage)?

    @discardableResult
    public func appendKnock(nonce: UUID) throws -> any ZMConversationMessage {
        appendKnock_Invocations.append(nonce)

        if let error = appendKnock_MockError {
            throw error
        }

        if let mock = appendKnock_MockMethod {
            return try mock(nonce)
        } else if let mock = appendKnock_MockValue {
            return mock
        } else {
            fatalError("no mock for `appendKnock`")
        }
    }

    // MARK: - appendImage

    public var appendImage_Invocations: [(image: SendableImage, nonce: UUID)] = []
    public var appendImage_MockError: Error?
    public var appendImage_MockMethod: ((SendableImage, UUID) throws -> any ZMConversationMessage)?
    public var appendImage_MockValue: (any ZMConversationMessage)?

    @discardableResult
    public func appendImage(_ image: SendableImage, nonce: UUID) throws -> any ZMConversationMessage {
        appendImage_Invocations.append((image: image, nonce: nonce))

        if let error = appendImage_MockError {
            throw error
        }

        if let mock = appendImage_MockMethod {
            return try mock(image, nonce)
        } else if let mock = appendImage_MockValue {
            return mock
        } else {
            fatalError("no mock for `appendImage`")
        }
    }

    // MARK: - appendLocation

    public var appendLocation_Invocations: [(locationData: LocationData, nonce: UUID)] = []
    public var appendLocation_MockError: Error?
    public var appendLocation_MockMethod: ((LocationData, UUID) throws -> any ZMConversationMessage)?
    public var appendLocation_MockValue: (any WireDataModel.ZMConversationMessage)?

    @discardableResult
    public func appendLocation(with locationData: LocationData, nonce: UUID) throws -> any ZMConversationMessage {
        appendLocation_Invocations.append((locationData: locationData, nonce: nonce))

        if let error = appendLocation_MockError {
            throw error
        }

        if let mock = appendLocation_MockMethod {
            return try mock(locationData, nonce)
        } else if let mock = appendLocation_MockValue {
            return mock
        } else {
            fatalError("no mock for `appendLocation`")
        }
    }

    // MARK: - appendFile

    public var appendFile_Invocations: [(fileMetadata: ZMFileMetadata, nonce: UUID)] = []
    public var appendFile_MockError: Error?
    public var appendFile_MockMethod: ((ZMFileMetadata, UUID) throws -> ZMConversationMessage)?
    public var appendFile_MockValue: ZMConversationMessage?

    @discardableResult
    public func appendFile(with fileMetadata: ZMFileMetadata, nonce: UUID) throws -> ZMConversationMessage {
        appendFile_Invocations.append((fileMetadata: fileMetadata, nonce: nonce))

        if let error = appendFile_MockError {
            throw error
        }

        if let mock = appendFile_MockMethod {
            return try mock(fileMetadata, nonce)
        } else if let mock = appendFile_MockValue {
            return mock
        } else {
            fatalError("no mock for `appendFile`")
        }
    }
}

public class MockUserSession: UserSession {
    public func resolveOneOnOneConversation(with userID: WireDataModel.QualifiedID) async throws -> WireDataModel.OneOnOneConversationResolution {
        return .noAction
    }
    
    public var isBuildBlacklisted = false
    public var resolvedBackendMetadata = BackendMetadataProvider(
        apiVersionOverride: .v0,
        domainOverride: "wire.com",
        isFederationEnabledOverride: false,
        isBackendMLSEnabledOverride: false
    )
    public var isBackendMLSEnabled: Bool = false

    // MARK: - Life cycle

    public init() {}

    // MARK: - userProfile

    public var userProfile: UserProfile {
        get { return underlyingUserProfile }
        set(value) { underlyingUserProfile = value }
    }

    public var underlyingUserProfile: UserProfile!

    // MARK: - isTornDown

    public var isTornDown: Bool {
        get { return underlyingIsTornDown }
        set(value) { underlyingIsTornDown = value }
    }

    public var underlyingIsTornDown: Bool!

    // MARK: - lock

    public var lock: SessionLock?

    // MARK: - isLocked

    public var isLocked: Bool {
        get { return underlyingIsLocked }
        set(value) { underlyingIsLocked = value }
    }

    public var underlyingIsLocked: Bool!

    // MARK: - requiresScreenCurtain

    public var requiresScreenCurtain: Bool {
        get { return underlyingRequiresScreenCurtain }
        set(value) { underlyingRequiresScreenCurtain = value }
    }

    public var underlyingRequiresScreenCurtain: Bool!

    // MARK: - isAppLockActive

    public var isAppLockActive: Bool {
        get { return underlyingIsAppLockActive }
        set(value) { underlyingIsAppLockActive = value }
    }

    public var underlyingIsAppLockActive: Bool!

    // MARK: - isAppLockAvailable

    public var isAppLockAvailable: Bool {
        get { return underlyingIsAppLockAvailable }
        set(value) { underlyingIsAppLockAvailable = value }
    }

    public var underlyingIsAppLockAvailable: Bool!

    // MARK: - isAppLockForced

    public var isAppLockForced: Bool {
        get { return underlyingIsAppLockForced }
        set(value) { underlyingIsAppLockForced = value }
    }

    public var underlyingIsAppLockForced: Bool!

    // MARK: - appLockTimeout

    public var appLockTimeout: UInt {
        get { return underlyingAppLockTimeout }
        set(value) { underlyingAppLockTimeout = value }
    }

    public var underlyingAppLockTimeout: UInt!

    // MARK: - isCustomAppLockPasscodeSet

    public var isCustomAppLockPasscodeSet: Bool {
        get { return underlyingIsCustomAppLockPasscodeSet }
        set(value) { underlyingIsCustomAppLockPasscodeSet = value }
    }

    public var underlyingIsCustomAppLockPasscodeSet: Bool!

    // MARK: - requireCustomAppLockPasscode

    public var requireCustomAppLockPasscode: Bool {
        get { return underlyingRequireCustomAppLockPasscode }
        set(value) { underlyingRequireCustomAppLockPasscode = value }
    }

    public var underlyingRequireCustomAppLockPasscode: Bool!

    // MARK: - shouldNotifyUserOfDisabledAppLock

    public var shouldNotifyUserOfDisabledAppLock: Bool {
        get { return underlyingShouldNotifyUserOfDisabledAppLock }
        set(value) { underlyingShouldNotifyUserOfDisabledAppLock = value }
    }

    public var underlyingShouldNotifyUserOfDisabledAppLock: Bool!

    // MARK: - needsToNotifyUserOfAppLockConfiguration

    public var needsToNotifyUserOfAppLockConfiguration: Bool {
        get { return underlyingNeedsToNotifyUserOfAppLockConfiguration }
        set(value) { underlyingNeedsToNotifyUserOfAppLockConfiguration = value }
    }

    public var underlyingNeedsToNotifyUserOfAppLockConfiguration: Bool!

    // MARK: - analyticsEventTracker

    public var analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?

    // MARK: - conversationDirectory

    public var conversationDirectory: ConversationDirectoryType {
        get { return underlyingConversationDirectory }
        set(value) { underlyingConversationDirectory = value }
    }

    public var underlyingConversationDirectory: ConversationDirectoryType!

    // MARK: - selfUser

    public var selfUser: any UserType {
        get { return underlyingSelfUser }
        set(value) { underlyingSelfUser = value }
    }

    public var underlyingSelfUser: (any UserType)!

    // MARK: - selfUserLegalHoldSubject

    public var selfUserLegalHoldSubject: any SelfUserLegalHoldable {
        get { return underlyingSelfUserLegalHoldSubject }
        set(value) { underlyingSelfUserLegalHoldSubject = value }
    }

    public var underlyingSelfUserLegalHoldSubject: (any SelfUserLegalHoldable)!

    // MARK: - editableSelfUser

    public var editableSelfUser: any UserType & EditableUserType {
        get { return underlyingEditableSelfUser }
        set(value) { underlyingEditableSelfUser = value }
    }

    public var underlyingEditableSelfUser: (any UserType & EditableUserType)!

    // MARK: - isNotificationContentHidden

    public var isNotificationContentHidden: Bool {
        get { return underlyingIsNotificationContentHidden }
        set(value) { underlyingIsNotificationContentHidden = value }
    }

    public var underlyingIsNotificationContentHidden: Bool!

    // MARK: - encryptMessagesAtRest

    public var encryptMessagesAtRest: Bool {
        get { return underlyingEncryptMessagesAtRest }
        set(value) { underlyingEncryptMessagesAtRest = value }
    }

    public var underlyingEncryptMessagesAtRest: Bool!

    // MARK: - ringingCallConversation

    public var ringingCallConversation: ZMConversation?

    // MARK: - maxAudioMessageLength

    public var maxAudioMessageLength: TimeInterval {
        get { return underlyingMaxAudioMessageLength }
        set(value) { underlyingMaxAudioMessageLength = value }
    }

    public var underlyingMaxAudioMessageLength: TimeInterval!

    // MARK: - maxUploadFileSize

    public var maxUploadFileSize: UInt64 {
        get { return underlyingMaxUploadFileSize }
        set(value) { underlyingMaxUploadFileSize = value }
    }

    public var underlyingMaxUploadFileSize: UInt64!

    // MARK: - maxVideoLength

    public var maxVideoLength: TimeInterval {
        get { return underlyingMaxVideoLength }
        set(value) { underlyingMaxVideoLength = value }
    }

    public var underlyingMaxVideoLength: TimeInterval!

    // MARK: - networkState

    public var networkState: NetworkState {
        get { return underlyingNetworkState }
        set(value) { underlyingNetworkState = value }
    }

    public var underlyingNetworkState: NetworkState!

    // MARK: - selfUserClient

    public var selfUserClient: UserClient?

    // MARK: - e2eiFeature

    public var e2eiFeature: Feature.E2EI {
        get { return underlyingE2eiFeature }
        set(value) { underlyingE2eiFeature = value }
    }

    public var underlyingE2eiFeature: Feature.E2EI!

    // MARK: - mlsFeature

    public var mlsFeature: Feature.MLS {
        get { return underlyingMlsFeature }
        set(value) { underlyingMlsFeature = value }
    }

    public var underlyingChannelsFeature: Feature.Channels!

    // MARK: - channelsFeature

    public var channelsFeature: Feature.Channels {
        get { return underlyingChannelsFeature }
        set(value) { underlyingChannelsFeature = value }
    }

    public var underlyingMlsFeature: Feature.MLS!

    // MARK: - chatBubblesSimpleFeature
    
    public var isChatBubbleSimpleEnabled: Bool = false
    
    public var isWireCellsEnabled: Bool = false
    
    public var isEnterpriseUser: Bool = false
    
    // MARK: - mlsGroupVerification

    public var mlsGroupVerification: (any MLSGroupVerificationProtocol)?

    // MARK: - notificationContext

    public var notificationContext: any NotificationContext {
        get { return underlyingNotificationContext }
        set(value) { underlyingNotificationContext = value }
    }

    public var underlyingNotificationContext: (any NotificationContext)!

    // MARK: - contextProvider

    public var contextProvider: any ContextProvider {
        get { return underlyingContextProvider }
        set(value) { underlyingContextProvider = value }
    }

    public var underlyingContextProvider: (any ContextProvider)!

    // MARK: - getUserClientFingerprint

    public var getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol {
        get { return underlyingGetUserClientFingerprint }
        set(value) { underlyingGetUserClientFingerprint = value }
    }

    public var underlyingGetUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol!

    // MARK: - isUserE2EICertifiedUseCase

    public var isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol {
        get { return underlyingIsUserE2EICertifiedUseCase }
        set(value) { underlyingIsUserE2EICertifiedUseCase = value }
    }

    public var underlyingIsUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol!

    // MARK: - isSelfUserE2EICertifiedUseCase

    public var isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol {
        get { return underlyingIsSelfUserE2EICertifiedUseCase }
        set(value) { underlyingIsSelfUserE2EICertifiedUseCase = value }
    }

    public var underlyingIsSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol!

    // MARK: - getIsE2eIdentityEnabled

    public var getIsE2eIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol {
        get { return underlyingGetIsE2eIdentityEnabled }
        set(value) { underlyingGetIsE2eIdentityEnabled = value }
    }

    public var underlyingGetIsE2eIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol!

    // MARK: - getE2eIdentityCertificates

    public var getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol {
        get { return underlyingGetE2eIdentityCertificates }
        set(value) { underlyingGetE2eIdentityCertificates = value }
    }

    public var underlyingGetE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol!

    // MARK: - enrollE2EICertificate

    public var enrollE2EICertificate: EnrollE2EICertificateUseCaseProtocol {
        get { return underlyingEnrollE2EICertificate }
        set(value) { underlyingEnrollE2EICertificate = value }
    }

    public var underlyingEnrollE2EICertificate: EnrollE2EICertificateUseCaseProtocol!

    // MARK: - checkOneOnOneConversationIsReady

    public var checkOneOnOneConversationIsReady: CheckOneOnOneConversationIsReadyUseCaseProtocol {
        get { return underlyingCheckOneOnOneConversationIsReady }
        set(value) { underlyingCheckOneOnOneConversationIsReady = value }
    }

    public var underlyingCheckOneOnOneConversationIsReady: CheckOneOnOneConversationIsReadyUseCaseProtocol!

    // MARK: - lastE2EIUpdateDateRepository

    public var lastE2EIUpdateDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?

    // MARK: - searchUsersCache

    public var searchUsersCache: SearchUsersCache {
        get { return underlyingSearchUsersCache }
        set(value) { underlyingSearchUsersCache = value }
    }

    public var underlyingSearchUsersCache: SearchUsersCache!

    // MARK: - fileAssetCache

    public var fileAssetCache: FileAssetCache {
        get { return underlyingFileAssetCache }
        set(value) { underlyingFileAssetCache = value }
    }

    public var underlyingFileAssetCache: FileAssetCache!

    // MARK: - unlockDatabase

    public var unlockDatabase_Invocations: [Void] = []
    public var unlockDatabase_MockError: Error?
    public var unlockDatabase_MockMethod: (() throws -> Void)?

    public func unlockDatabase() throws {
        unlockDatabase_Invocations.append(())

        if let error = unlockDatabase_MockError {
            throw error
        }

        guard let mock = unlockDatabase_MockMethod else {
            fatalError("no mock for `unlockDatabase`")
        }

        try mock()
    }

    // MARK: - openAppLock

    public var openAppLock_Invocations: [Void] = []
    public var openAppLock_MockError: Error?
    public var openAppLock_MockMethod: (() throws -> Void)?

    public func openAppLock() throws {
        openAppLock_Invocations.append(())

        if let error = openAppLock_MockError {
            throw error
        }

        guard let mock = openAppLock_MockMethod else {
            fatalError("no mock for `openAppLock`")
        }

        try mock()
    }

    // MARK: - evaluateAppLockAuthentication

    public var evaluateAppLockAuthenticationPasscodePreferenceDescriptionCallback_Invocations: [(passcodePreference: AppLockPasscodePreference, description: String, callback: (AppLockAuthenticationResult) -> Void)] = []
    public var evaluateAppLockAuthenticationPasscodePreferenceDescriptionCallback_MockMethod: ((AppLockPasscodePreference, String, @escaping (AppLockAuthenticationResult) -> Void) -> Void)?

    public func evaluateAppLockAuthentication(passcodePreference: AppLockPasscodePreference, description: String, callback: @escaping (AppLockAuthenticationResult) -> Void) {
        evaluateAppLockAuthenticationPasscodePreferenceDescriptionCallback_Invocations.append((passcodePreference: passcodePreference, description: description, callback: callback))

        guard let mock = evaluateAppLockAuthenticationPasscodePreferenceDescriptionCallback_MockMethod else {
            fatalError("no mock for `evaluateAppLockAuthenticationPasscodePreferenceDescriptionCallback`")
        }

        mock(passcodePreference, description, callback)
    }

    // MARK: - evaluateAuthentication

    public var evaluateAuthenticationCustomPasscode_Invocations: [String] = []
    public var evaluateAuthenticationCustomPasscode_MockMethod: ((String) -> AppLockAuthenticationResult)?
    public var evaluateAuthenticationCustomPasscode_MockValue: AppLockAuthenticationResult?

    public func evaluateAuthentication(customPasscode: String) -> AppLockAuthenticationResult {
        evaluateAuthenticationCustomPasscode_Invocations.append(customPasscode)

        if let mock = evaluateAuthenticationCustomPasscode_MockMethod {
            return mock(customPasscode)
        } else if let mock = evaluateAuthenticationCustomPasscode_MockValue {
            return mock
        } else {
            fatalError("no mock for `evaluateAuthenticationCustomPasscode`")
        }
    }

    // MARK: - deleteAppLockPasscode

    public var deleteAppLockPasscode_Invocations: [Void] = []
    public var deleteAppLockPasscode_MockError: Error?
    public var deleteAppLockPasscode_MockMethod: (() throws -> Void)?

    public func deleteAppLockPasscode() throws {
        deleteAppLockPasscode_Invocations.append(())

        if let error = deleteAppLockPasscode_MockError {
            throw error
        }

        guard let mock = deleteAppLockPasscode_MockMethod else {
            fatalError("no mock for `deleteAppLockPasscode`")
        }

        try mock()
    }

    // MARK: - perform

    public var perform_Invocations: [() -> Void] = []
    public var perform_MockMethod: ((@escaping () -> Void) -> Void)?

    public func perform(_ changes: @escaping () -> Void) {
        perform_Invocations.append(changes)

        guard let mock = perform_MockMethod else {
            fatalError("no mock for `perform`")
        }

        mock(changes)
    }

    // MARK: - enqueue

    public var enqueue_Invocations: [() -> Void] = []
    public var enqueue_MockMethod: ((@escaping () -> Void) -> Void)?

    public func enqueue(_ changes: @escaping () -> Void) {
        enqueue_Invocations.append(changes)

        guard let mock = enqueue_MockMethod else {
            fatalError("no mock for `enqueue`")
        }

        mock(changes)
    }

    // MARK: - enqueue

    public var enqueueCompletionHandler_Invocations: [(changes: () -> Void, completionHandler: (() -> Void)?)] = []
    public var enqueueCompletionHandler_MockMethod: ((@escaping () -> Void, (() -> Void)?) -> Void)?

    public func enqueue(_ changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        enqueueCompletionHandler_Invocations.append((changes: changes, completionHandler: completionHandler))

        guard let mock = enqueueCompletionHandler_MockMethod else {
            fatalError("no mock for `enqueueCompletionHandler`")
        }

        mock(changes, completionHandler)
    }

    // MARK: - setEncryptionAtRest

    public var setEncryptionAtRestEnabledSkipMigration_Invocations: [(enabled: Bool, skipMigration: Bool)] = []
    public var setEncryptionAtRestEnabledSkipMigration_MockError: Error?
    public var setEncryptionAtRestEnabledSkipMigration_MockMethod: ((Bool, Bool) throws -> Void)?

    public func setEncryptionAtRest(enabled: Bool, skipMigration: Bool) throws {
        setEncryptionAtRestEnabledSkipMigration_Invocations.append((enabled: enabled, skipMigration: skipMigration))

        if let error = setEncryptionAtRestEnabledSkipMigration_MockError {
            throw error
        }

        guard let mock = setEncryptionAtRestEnabledSkipMigration_MockMethod else {
            fatalError("no mock for `setEncryptionAtRestEnabledSkipMigration`")
        }

        try mock(enabled, skipMigration)
    }

    // MARK: - addUserObserver

    public var addUserObserverFor_Invocations: [(observer: UserObserving, user: UserType)] = []
    public var addUserObserverFor_MockMethod: ((UserObserving, UserType) -> NSObjectProtocol?)?
    public var addUserObserverFor_MockValue: NSObjectProtocol??

    public func addUserObserver(_ observer: UserObserving, for user: UserType) -> NSObjectProtocol? {
        addUserObserverFor_Invocations.append((observer: observer, user: user))

        if let mock = addUserObserverFor_MockMethod {
            return mock(observer, user)
        } else if let mock = addUserObserverFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `addUserObserverFor`")
        }
    }

    // MARK: - addUserObserver

    public var addUserObserver_Invocations: [UserObserving] = []
    public var addUserObserver_MockMethod: ((UserObserving) -> NSObjectProtocol)?
    public var addUserObserver_MockValue: NSObjectProtocol?

    public func addUserObserver(_ observer: UserObserving) -> NSObjectProtocol {
        addUserObserver_Invocations.append(observer)

        if let mock = addUserObserver_MockMethod {
            return mock(observer)
        } else if let mock = addUserObserver_MockValue {
            return mock
        } else {
            fatalError("no mock for `addUserObserver`")
        }
    }

    // MARK: - addMessageObserver

    public var addMessageObserverFor_Invocations: [(observer: ZMMessageObserver, message: ZMConversationMessage)] = []
    public var addMessageObserverFor_MockMethod: ((ZMMessageObserver, ZMConversationMessage) -> NSObjectProtocol)?
    public var addMessageObserverFor_MockValue: NSObjectProtocol?

    public func addMessageObserver(_ observer: ZMMessageObserver, for message: ZMConversationMessage) -> NSObjectProtocol {
        addMessageObserverFor_Invocations.append((observer: observer, message: message))

        if let mock = addMessageObserverFor_MockMethod {
            return mock(observer, message)
        } else if let mock = addMessageObserverFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `addMessageObserverFor`")
        }
    }

    // MARK: - addConferenceCallingUnavailableObserver

    public var addConferenceCallingUnavailableObserver_Invocations: [ConferenceCallingUnavailableObserver] = []
    public var addConferenceCallingUnavailableObserver_MockMethod: ((ConferenceCallingUnavailableObserver) -> Any)?
    public var addConferenceCallingUnavailableObserver_MockValue: Any?

    public func addConferenceCallingUnavailableObserver(_ observer: ConferenceCallingUnavailableObserver) -> Any {
        addConferenceCallingUnavailableObserver_Invocations.append(observer)

        if let mock = addConferenceCallingUnavailableObserver_MockMethod {
            return mock(observer)
        } else if let mock = addConferenceCallingUnavailableObserver_MockValue {
            return mock
        } else {
            fatalError("no mock for `addConferenceCallingUnavailableObserver`")
        }
    }

    // MARK: - addConferenceCallStateObserver

    public var addConferenceCallStateObserver_Invocations: [WireCallCenterCallStateObserver] = []
    public var addConferenceCallStateObserver_MockMethod: ((WireCallCenterCallStateObserver) -> Any)?
    public var addConferenceCallStateObserver_MockValue: Any?

    public func addConferenceCallStateObserver(_ observer: WireCallCenterCallStateObserver) -> Any {
        addConferenceCallStateObserver_Invocations.append(observer)

        if let mock = addConferenceCallStateObserver_MockMethod {
            return mock(observer)
        } else if let mock = addConferenceCallStateObserver_MockValue {
            return mock
        } else {
            fatalError("no mock for `addConferenceCallStateObserver`")
        }
    }

    // MARK: - addConferenceCallErrorObserver

    public var addConferenceCallErrorObserver_Invocations: [WireCallCenterCallErrorObserver] = []
    public var addConferenceCallErrorObserver_MockMethod: ((WireCallCenterCallErrorObserver) -> Any)?
    public var addConferenceCallErrorObserver_MockValue: Any?

    public func addConferenceCallErrorObserver(_ observer: WireCallCenterCallErrorObserver) -> Any {
        addConferenceCallErrorObserver_Invocations.append(observer)

        if let mock = addConferenceCallErrorObserver_MockMethod {
            return mock(observer)
        } else if let mock = addConferenceCallErrorObserver_MockValue {
            return mock
        } else {
            fatalError("no mock for `addConferenceCallErrorObserver`")
        }
    }

    // MARK: - addConversationListObserver

    public var addConversationListObserverFor_Invocations: [(observer: ZMConversationListObserver, list: ConversationList)] = []
    public var addConversationListObserverFor_MockMethod: ((ZMConversationListObserver, ConversationList) -> NSObjectProtocol)?
    public var addConversationListObserverFor_MockValue: NSObjectProtocol?

    public func addConversationListObserver(_ observer: ZMConversationListObserver, for list: ConversationList) -> NSObjectProtocol {
        addConversationListObserverFor_Invocations.append((observer: observer, list: list))

        if let mock = addConversationListObserverFor_MockMethod {
            return mock(observer, list)
        } else if let mock = addConversationListObserverFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `addConversationListObserverFor`")
        }
    }

    // MARK: - conversationList

    public var conversationList_Invocations: [Void] = []
    public var conversationList_MockMethod: (() -> ConversationList)?
    public var conversationList_MockValue: ConversationList?

    public func conversationList() -> ConversationList {
        conversationList_Invocations.append(())

        if let mock = conversationList_MockMethod {
            return mock()
        } else if let mock = conversationList_MockValue {
            return mock
        } else {
            fatalError("no mock for `conversationList`")
        }
    }

    // MARK: - pendingConnectionConversationsInUserSession

    public var pendingConnectionConversationsInUserSession_Invocations: [Void] = []
    public var pendingConnectionConversationsInUserSession_MockMethod: (() -> ConversationList)?
    public var pendingConnectionConversationsInUserSession_MockValue: ConversationList?

    public func pendingConnectionConversationsInUserSession() -> ConversationList {
        pendingConnectionConversationsInUserSession_Invocations.append(())

        if let mock = pendingConnectionConversationsInUserSession_MockMethod {
            return mock()
        } else if let mock = pendingConnectionConversationsInUserSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `pendingConnectionConversationsInUserSession`")
        }
    }

    // MARK: - archivedConversationsInUserSession

    public var archivedConversationsInUserSession_Invocations: [Void] = []
    public var archivedConversationsInUserSession_MockMethod: (() -> ConversationList)?
    public var archivedConversationsInUserSession_MockValue: ConversationList?

    public func archivedConversationsInUserSession() -> ConversationList {
        archivedConversationsInUserSession_Invocations.append(())

        if let mock = archivedConversationsInUserSession_MockMethod {
            return mock()
        } else if let mock = archivedConversationsInUserSession_MockValue {
            return mock
        } else {
            fatalError("no mock for `archivedConversationsInUserSession`")
        }
    }

    // MARK: - acknowledgeFeatureChange

    public var acknowledgeFeatureChangeFor_Invocations: [Feature.Name] = []
    public var acknowledgeFeatureChangeFor_MockMethod: ((Feature.Name) -> Void)?

    public func acknowledgeFeatureChange(for feature: Feature.Name) {
        acknowledgeFeatureChangeFor_Invocations.append(feature)

        guard let mock = acknowledgeFeatureChangeFor_MockMethod else {
            fatalError("no mock for `acknowledgeFeatureChangeFor`")
        }

        mock(feature)
    }

    // MARK: - classification

    public var classificationUsersConversationDomain_Invocations: [(users: [UserType], conversationDomain: String?)] = []
    public var classificationUsersConversationDomain_MockMethod: (([UserType], String?) -> SecurityClassification?)?
    public var classificationUsersConversationDomain_MockValue: SecurityClassification??

    public func classification(users: [UserType], conversationDomain: String?) -> SecurityClassification? {
        classificationUsersConversationDomain_Invocations.append((users: users, conversationDomain: conversationDomain))

        if let mock = classificationUsersConversationDomain_MockMethod {
            return mock(users, conversationDomain)
        } else if let mock = classificationUsersConversationDomain_MockValue {
            return mock
        } else {
            fatalError("no mock for `classificationUsersConversationDomain`")
        }
    }

    // MARK: - proxiedRequest

    public var proxiedRequestPathMethodTypeCallback_Invocations: [(path: String, method: ZMTransportRequestMethod, type: ProxiedRequestType, callback: ProxyRequestCallback?)] = []
    public var proxiedRequestPathMethodTypeCallback_MockMethod: ((String, ZMTransportRequestMethod, ProxiedRequestType, ProxyRequestCallback?) -> ProxyRequest)?
    public var proxiedRequestPathMethodTypeCallback_MockValue: ProxyRequest?

    public func proxiedRequest(path: String, method: ZMTransportRequestMethod, type: ProxiedRequestType, callback: ProxyRequestCallback?) -> ProxyRequest {
        proxiedRequestPathMethodTypeCallback_Invocations.append((path: path, method: method, type: type, callback: callback))

        if let mock = proxiedRequestPathMethodTypeCallback_MockMethod {
            return mock(path, method, type, callback)
        } else if let mock = proxiedRequestPathMethodTypeCallback_MockValue {
            return mock
        } else {
            fatalError("no mock for `proxiedRequestPathMethodTypeCallback`")
        }
    }

    // MARK: - cancelProxiedRequest

    public var cancelProxiedRequest_Invocations: [ProxyRequest] = []
    public var cancelProxiedRequest_MockMethod: ((ProxyRequest) -> Void)?

    public func cancelProxiedRequest(_ request: ProxyRequest) {
        cancelProxiedRequest_Invocations.append(request)

        guard let mock = cancelProxiedRequest_MockMethod else {
            fatalError("no mock for `cancelProxiedRequest`")
        }

        mock(request)
    }

    // MARK: - fetchAllClients

    public var fetchAllClients_Invocations: [Void] = []
    public var fetchAllClients_MockMethod: (() -> Void)?

    public func fetchAllClients() {
        fetchAllClients_Invocations.append(())

        guard let mock = fetchAllClients_MockMethod else {
            fatalError("no mock for `fetchAllClients`")
        }

        mock()
    }

    // MARK: - createTeamOneOnOne

    public var createTeamOneOnOneWithCompletion_Invocations: [(user: UserType, completion: (Swift.Result<ZMConversation, CreateTeamOneOnOneConversationError>) -> Void)] = []
    public var createTeamOneOnOneWithCompletion_MockMethod: ((UserType, @escaping (Swift.Result<ZMConversation, CreateTeamOneOnOneConversationError>) -> Void) -> Void)?

    public func createTeamOneOnOne(with user: UserType, completion: @escaping (Swift.Result<ZMConversation, CreateTeamOneOnOneConversationError>) -> Void) {
        createTeamOneOnOneWithCompletion_Invocations.append((user: user, completion: completion))

        guard let mock = createTeamOneOnOneWithCompletion_MockMethod else {
            fatalError("no mock for `createTeamOneOnOneWithCompletion`")
        }

        mock(user, completion)
    }

    // MARK: - makeGetMLSFeatureUseCase

    public var makeGetMLSFeatureUseCase_Invocations: [Void] = []
    public var makeGetMLSFeatureUseCase_MockMethod: (() -> GetMLSFeatureUseCaseProtocol)?
    public var makeGetMLSFeatureUseCase_MockValue: GetMLSFeatureUseCaseProtocol?

    public func makeGetMLSFeatureUseCase() -> GetMLSFeatureUseCaseProtocol {
        makeGetMLSFeatureUseCase_Invocations.append(())

        if let mock = makeGetMLSFeatureUseCase_MockMethod {
            return mock()
        } else if let mock = makeGetMLSFeatureUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeGetMLSFeatureUseCase`")
        }
    }

    // MARK: - makeConversationSecureGuestLinkUseCase

    public var makeConversationSecureGuestLinkUseCase_Invocations: [Void] = []
    public var makeConversationSecureGuestLinkUseCase_MockMethod: (() -> CreateConversationGuestLinkUseCaseProtocol)?
    public var makeConversationSecureGuestLinkUseCase_MockValue: CreateConversationGuestLinkUseCaseProtocol?

    public func makeConversationSecureGuestLinkUseCase() -> CreateConversationGuestLinkUseCaseProtocol {
        makeConversationSecureGuestLinkUseCase_Invocations.append(())

        if let mock = makeConversationSecureGuestLinkUseCase_MockMethod {
            return mock()
        } else if let mock = makeConversationSecureGuestLinkUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeConversationSecureGuestLinkUseCase`")
        }
    }

    // MARK: - makeSetConversationGuestsAndAppsUseCase

    public var makeSetConversationGuestsAndAppsUseCase_Invocations: [Void] = []
    public var makeSetConversationGuestsAndAppsUseCase_MockMethod: (() -> SetAllowGuestAndAppsUseCaseProtocol)?
    public var makeSetConversationGuestsAndAppsUseCase_MockValue: SetAllowGuestAndAppsUseCaseProtocol?

    public func makeSetConversationGuestsAndAppsUseCase() -> SetAllowGuestAndAppsUseCaseProtocol {
        makeSetConversationGuestsAndAppsUseCase_Invocations.append(())

        if let mock = makeSetConversationGuestsAndAppsUseCase_MockMethod {
            return mock()
        } else if let mock = makeSetConversationGuestsAndAppsUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeSetConversationGuestsAndAppsUseCase`")
        }
    }

    // MARK: - makeAppendTextMessageUseCase

    public var makeAppendTextMessageUseCase_Invocations: [Void] = []
    public var makeAppendTextMessageUseCase_MockMethod: (() -> any AppendTextMessageUseCaseProtocol)?
    public var makeAppendTextMessageUseCase_MockValue: (any AppendTextMessageUseCaseProtocol)?

    public func makeAppendTextMessageUseCase() -> any AppendTextMessageUseCaseProtocol {
        makeAppendTextMessageUseCase_Invocations.append(())

        if let mock = makeAppendTextMessageUseCase_MockMethod {
            return mock()
        } else if let mock = makeAppendTextMessageUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeAppendTextMessageUseCase`")
        }
    }

    // MARK: - makeAppendMultipartMessageUseCase

    public var makeAppendMultipartMessageUseCase_Invocations: [Void] = []
    public var makeAppendMultipartMessageUseCase_MockMethod: (() -> any AppendMultipartMessageUseCaseProtocol)?
    public var makeAppendMultipartMessageUseCase_MockValue: (any AppendMultipartMessageUseCaseProtocol)?

    public func makeAppendMultipartMessageUseCase() -> any AppendMultipartMessageUseCaseProtocol {
        makeAppendMultipartMessageUseCase_Invocations.append(())

        if let mock = makeAppendMultipartMessageUseCase_MockMethod {
            return mock()
        } else if let mock = makeAppendMultipartMessageUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeAppendMultipartMessageUseCase`")
        }
    }

    // MARK: - makeAppendImageMessageUseCase

    public var makeAppendImageMessageUseCase_Invocations: [Void] = []
    public var makeAppendImageMessageUseCase_MockMethod: (() -> any AppendImageMessageUseCaseProtocol)?
    public var makeAppendImageMessageUseCase_MockValue: (any AppendImageMessageUseCaseProtocol)?

    public func makeAppendImageMessageUseCase() -> any AppendImageMessageUseCaseProtocol {
        makeAppendImageMessageUseCase_Invocations.append(())

        if let mock = makeAppendImageMessageUseCase_MockMethod {
            return mock()
        } else if let mock = makeAppendImageMessageUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeAppendImageMessageUseCase`")
        }
    }

    // MARK: - makeAppendKnockMessageUseCase

    public var makeAppendKnockMessageUseCase_Invocations: [Void] = []
    public var makeAppendKnockMessageUseCase_MockMethod: (() -> any AppendKnockMessageUseCaseProtocol)?
    public var makeAppendKnockMessageUseCase_MockValue: (any AppendKnockMessageUseCaseProtocol)?

    public func makeAppendKnockMessageUseCase() -> any AppendKnockMessageUseCaseProtocol {
        makeAppendKnockMessageUseCase_Invocations.append(())

        if let mock = makeAppendKnockMessageUseCase_MockMethod {
            return mock()
        } else if let mock = makeAppendKnockMessageUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeAppendKnockMessageUseCase`")
        }
    }

    // MARK: - makeAppendLocationMessageUseCase

    public var makeAppendLocationMessageUseCase_Invocations: [Void] = []
    public var makeAppendLocationMessageUseCase_MockMethod: (() -> any AppendLocationMessagekUseCaseProtocol)?
    public var makeAppendLocationMessageUseCase_MockValue: (any AppendLocationMessagekUseCaseProtocol)?

    public func makeAppendLocationMessageUseCase() -> any AppendLocationMessagekUseCaseProtocol {
        makeAppendLocationMessageUseCase_Invocations.append(())

        if let mock = makeAppendLocationMessageUseCase_MockMethod {
            return mock()
        } else if let mock = makeAppendLocationMessageUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeAppendLocationMessageUseCase`")
        }
    }

    // MARK: - makeAppendFileMessageUseCase

    public var makeAppendFileMessageUseCase_Invocations: [Void] = []
    public var makeAppendFileMessageUseCase_MockMethod: (() -> any AppendFileMessageUseCaseProtocol)?
    public var makeAppendFileMessageUseCase_MockValue: (any AppendFileMessageUseCaseProtocol)?

    public func makeAppendFileMessageUseCase() -> any AppendFileMessageUseCaseProtocol {
        makeAppendFileMessageUseCase_Invocations.append(())

        if let mock = makeAppendFileMessageUseCase_MockMethod {
            return mock()
        } else if let mock = makeAppendFileMessageUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeAppendFileMessageUseCase`")
        }
    }

    // MARK: - makeToggleMessageReactionUseCase

    public var makeToggleMessageReactionUseCase_Invocations: [Void] = []
    public var makeToggleMessageReactionUseCase_MockMethod: (() -> any ToggleMessageReactionUseCaseProtocol)?
    public var makeToggleMessageReactionUseCase_MockValue: (any ToggleMessageReactionUseCaseProtocol)?

    public func makeToggleMessageReactionUseCase() -> any ToggleMessageReactionUseCaseProtocol {
        makeToggleMessageReactionUseCase_Invocations.append(())

        if let mock = makeToggleMessageReactionUseCase_MockMethod {
            return mock()
        } else if let mock = makeToggleMessageReactionUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeToggleMessageReactionUseCase`")
        }
    }

    // MARK: - makeCallQualitySurveyUseCase

    public var makeCallQualitySurveyUseCase_Invocations: [Void] = []
    public var makeCallQualitySurveyUseCase_MockMethod: (() -> any SubmitCallQualitySurveyUseCaseProtocol)?
    public var makeCallQualitySurveyUseCase_MockValue: (any SubmitCallQualitySurveyUseCaseProtocol)?

    public func makeCallQualitySurveyUseCase() -> any SubmitCallQualitySurveyUseCaseProtocol {
        makeCallQualitySurveyUseCase_Invocations.append(())

        if let mock = makeCallQualitySurveyUseCase_MockMethod {
            return mock()
        } else if let mock = makeCallQualitySurveyUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeCallQualitySurveyUseCase`")
        }
    }

    // MARK: - makeConversationFolderSelectionUseCase

    public var makeConversationFolderSelectionUseCase_Invocations: [Void] = []
    public var makeConversationFolderSelectionUseCase_MockMethod: (() -> UpdateConversationFolderUseCase)?
    public var makeConversationFolderSelectionUseCase_MockValue: UpdateConversationFolderUseCase?

    public func makeConversationFolderSelectionUseCase() -> UpdateConversationFolderUseCase {
        makeConversationFolderSelectionUseCase_Invocations.append(())

        if let mock = makeConversationFolderSelectionUseCase_MockMethod {
            return mock()
        } else if let mock = makeConversationFolderSelectionUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeConversationFolderSelectionUseCase`")
        }
    }

    // MARK: - makeConversationFolderCreationUseCase

    public var makeConversationFolderCreationUseCase_Invocations: [Void] = []
    public var makeConversationFolderCreationUseCase_MockMethod: (() -> CreateConversationFolderUseCase)?
    public var makeConversationFolderCreationUseCase_MockValue: CreateConversationFolderUseCase?

    public func makeConversationFolderCreationUseCase() -> CreateConversationFolderUseCase {
        makeConversationFolderCreationUseCase_Invocations.append(())

        if let mock = makeConversationFolderCreationUseCase_MockMethod {
            return mock()
        } else if let mock = makeConversationFolderCreationUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeConversationFolderCreationUseCase`")
        }
    }

    // MARK: - makeSearchUsersUseCase

    public var makeSearchUsersUseCase_Invocations: [Void] = []
    public var makeSearchUsersUseCase_MockMethod: (() -> SearchUsersUseCaseProtocol)?
    public var makeSearchUsersUseCase_MockValue: SearchUsersUseCaseProtocol?

    public func makeSearchUsersUseCase() -> SearchUsersUseCaseProtocol {
        makeSearchUsersUseCase_Invocations.append(())

        if let mock = makeSearchUsersUseCase_MockMethod {
            return mock()
        } else if let mock = makeSearchUsersUseCase_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeSearchUsersUseCase`")
        }
    }

    // MARK: - fetchSelfConversationMLSGroupID

    public var fetchSelfConversationMLSGroupID_Invocations: [Void] = []
    public var fetchSelfConversationMLSGroupID_MockMethod: (() async -> MLSGroupID?)?
    public var fetchSelfConversationMLSGroupID_MockValue: MLSGroupID??

    public func fetchSelfConversationMLSGroupID() async -> MLSGroupID? {
        fetchSelfConversationMLSGroupID_Invocations.append(())

        if let mock = fetchSelfConversationMLSGroupID_MockMethod {
            return await mock()
        } else if let mock = fetchSelfConversationMLSGroupID_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchSelfConversationMLSGroupID`")
        }
    }

    // MARK: - e2eIdentityUpdateCertificateUpdateStatus

    public var e2eIdentityUpdateCertificateUpdateStatus_Invocations: [Void] = []
    public var e2eIdentityUpdateCertificateUpdateStatus_MockMethod: (() -> E2EIdentityCertificateUpdateStatusUseCaseProtocol?)?
    public var e2eIdentityUpdateCertificateUpdateStatus_MockValue: E2EIdentityCertificateUpdateStatusUseCaseProtocol??

    public func e2eIdentityUpdateCertificateUpdateStatus() -> E2EIdentityCertificateUpdateStatusUseCaseProtocol? {
        e2eIdentityUpdateCertificateUpdateStatus_Invocations.append(())

        if let mock = e2eIdentityUpdateCertificateUpdateStatus_MockMethod {
            return mock()
        } else if let mock = e2eIdentityUpdateCertificateUpdateStatus_MockValue {
            return mock
        } else {
            fatalError("no mock for `e2eIdentityUpdateCertificateUpdateStatus`")
        }
    }

    // MARK: - ClientSessionComponent

    public var clientSessionComponent: ClientSessionComponent?
}
