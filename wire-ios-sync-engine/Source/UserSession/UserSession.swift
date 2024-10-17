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
import LocalAuthentication
import WireDataModel

/// An abstraction of the user session for use in the presentation
/// layer.
public protocol UserSession: AnyObject {

    // MARK: - Mixed properties and methods

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: structure mixed methods and properties in sections

    var userProfile: UserProfile { get }

    /// The current session lock, if any.

    var lock: SessionLock? { get }

    /// Whether the session needs to be unlocked by the user
    /// via passcode or biometric authentication.

    var isLocked: Bool { get }

    /// Whether the screen curtain is required.
    ///
    /// The screen curtain hides the contents of the app while it is
    /// not active, such as when it is in the task switcher.

    var requiresScreenCurtain: Bool { get }

    /// Whether the app lock on.

    var isAppLockActive: Bool { get set }

    /// Whether the app lock feature is availble to the user.

    var isAppLockAvailable: Bool { get }

    /// Whether the app lock is mandatorily active.

    var isAppLockForced: Bool { get }

    /// The maximum number of seconds allowed in the background before the
    /// authentication is required.

    var appLockTimeout: UInt { get }

    /// Whether a custom passcode has been set.

    var isCustomAppLockPasscodeSet: Bool { get }

    /// Whether a custom passcode (rather a device passcode) should be used.

    var requireCustomAppLockPasscode: Bool { get }

    /// Whether the user should be notified of the app lock being disabled.

    var shouldNotifyUserOfDisabledAppLock: Bool { get }

    /// Whether the user needs to be informed about configuration changes.

    var needsToNotifyUserOfAppLockConfiguration: Bool { get set }

    /// Unlocks the database.

    func unlockDatabase() throws

    /// Open the app lock.

    func openAppLock() throws

    /// Authenticate with device owner credentials (biometrics or passcode).
    ///
    /// - Parameters:
    ///     - passcodePreference: Used to determine which type of passcode is used.
    ///     - description: The message to dispaly in the authentication UI.
    ///     - callback: Invoked with the authentication result.

    func evaluateAppLockAuthentication(
        passcodePreference: AppLockPasscodePreference,
        description: String,
        callback: @escaping (AppLockAuthenticationResult) -> Void
    )

    /// Authenticate with a custom passcode.
    ///
    /// - Parameter customPasscode: The user inputted passcode.
    /// - Returns: The authentication result, which should be either `granted` or `denied`.

    func evaluateAuthentication(customPasscode: String) -> AppLockAuthenticationResult

    /// Delete the app lock passcode if it exists.

    func deleteAppLockPasscode() throws

    var conversationDirectory: ConversationDirectoryType { get }

    /// The user who is logged into this session.
    ///
    /// This can only be used on the main thread.

    var selfUser: any UserType { get }

    var selfUserLegalHoldSubject: any SelfUserLegalHoldable { get }

    var editableSelfUser: any UserType & EditableUserType { get }

    func perform(_ changes: @escaping () -> Void)

    func enqueue(_ changes: @escaping () -> Void)

    func enqueue(
        _ changes: @escaping () -> Void,
        completionHandler: (() -> Void)?
    )
    // swiftlint:disable todo_requires_jira_link
    // TODO: rename to "shouldHideNotificationContent"
    var isNotificationContentHidden: Bool { get set }

    // TODO: rename to "isEncryptionAtRestEnabled"
    // swiftlint:enable todo_requires_jira_link
    var encryptMessagesAtRest: Bool { get }

    func setEncryptionAtRest(enabled: Bool, skipMigration: Bool) throws

    func addUserObserver(
        _ observer: UserObserving,
        for user: UserType
    ) -> NSObjectProtocol?

    func addUserObserver(
        _ observer: UserObserving
    ) -> NSObjectProtocol

    func addMessageObserver(
        _ observer: ZMMessageObserver,
        for message: ZMConversationMessage
    ) -> NSObjectProtocol

    func addConferenceCallingUnavailableObserver(
        _ observer: ConferenceCallingUnavailableObserver
    ) -> Any

    func addConferenceCallStateObserver(
        _ observer: WireCallCenterCallStateObserver
    ) -> Any

    func addConferenceCallErrorObserver(
        _ observer: WireCallCenterCallErrorObserver
    ) -> Any

    func addConversationListObserver(
        _ observer: ZMConversationListObserver,
        for list: ConversationList
    ) -> NSObjectProtocol

    func conversationList() -> ConversationList

    func pendingConnectionConversationsInUserSession() -> ConversationList

    func archivedConversationsInUserSession() -> ConversationList

    var ringingCallConversation: ZMConversation? { get }

    var maxAudioMessageLength: TimeInterval { get }

    var maxUploadFileSize: UInt64 { get }

    func acknowledgeFeatureChange(for feature: Feature.Name)

    func fetchMarketingConsent(
        completion: @escaping (
            Result<Bool, Error>
        ) -> Void
    )

    func setMarketingConsent(
        granted: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    )

    func classification(
        users: [UserType],
        conversationDomain: String?
    ) -> SecurityClassification?

    var maxVideoLength: TimeInterval { get }

    func proxiedRequest(
        path: String,
        method: ZMTransportRequestMethod,
        type: ProxiedRequestType,
        callback: ProxyRequestCallback?
    ) -> ProxyRequest

    func cancelProxiedRequest(_ request: ProxyRequest)

    var networkState: NetworkState { get }

    var selfUserClient: UserClient? { get }

    var e2eiFeature: Feature.E2EI { get }

    var mlsFeature: Feature.MLS { get }

    func fetchAllClients()

    func createTeamOneOnOne(
        with user: UserType,
        completion: @escaping (Swift.Result<ZMConversation, CreateTeamOneOnOneConversationError>) -> Void
    )

    // MARK: MLS

    var mlsGroupVerification: (any MLSGroupVerificationProtocol)? { get }

    // MARK: Notifications

    /// Provides a unique context to bind notifications this user session.
    var notificationContext: any NotificationContext { get }

    // MARK: Context provider

    var contextProvider: any ContextProvider { get }

    // MARK: Use Cases

    var getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol { get }

    var isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol { get }

    var isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol { get }

    var getIsE2eIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol { get }

    var getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol { get }

    var enrollE2EICertificate: EnrollE2EICertificateUseCaseProtocol { get }

    var checkOneOnOneConversationIsReady: CheckOneOnOneConversationIsReadyUseCaseProtocol { get }

    var lastE2EIUpdateDateRepository: LastE2EIdentityUpdateDateRepositoryInterface? { get }

    func makeGetMLSFeatureUseCase() -> GetMLSFeatureUseCaseProtocol

    func makeConversationSecureGuestLinkUseCase() -> CreateConversationGuestLinkUseCaseProtocol

    func makeSetConversationGuestsAndServicesUseCase() -> SetAllowGuestAndServicesUseCaseProtocol

    func makeAppendTextMessageUseCase() -> any AppendTextMessageUseCaseProtocol

    func makeAppendImageMessageUseCase() -> any AppendImageMessageUseCaseProtocol

    func makeAppendKnockMessageUseCase() -> any AppendKnockMessageUseCaseProtocol

    func makeAppendLocationMessageUseCase() -> any AppendLocationMessagekUseCaseProtocol

    func makeAppendFileMessageUseCase() -> any AppendFileMessageUseCaseProtocol

    func makeToggleMessageReactionUseCase() -> any ToggleMessageReactionUseCaseProtocol

    func makeCallQualitySurveyUseCase() -> any SubmitCallQualitySurveyUseCaseProtocol

    func fetchSelfConversationMLSGroupID() async -> MLSGroupID?

    func e2eIdentityUpdateCertificateUpdateStatus() -> E2EIdentityCertificateUpdateStatusUseCaseProtocol?

    // MARK: - Dependency Injection

    /// Cache for search users.
    var searchUsersCache: SearchUsersCache { get }
}
