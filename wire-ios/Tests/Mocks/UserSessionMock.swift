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
import WireDataModelSupport
import WireRequestStrategySupport
import WireSyncEngine
import WireSyncEngineSupport

@testable import Wire

final class UserSessionMock: UserSession {

    var userProfile: UserProfile

    var lastE2EIUpdateDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?

    func fetchSelfConversationMLSGroupID() async -> WireDataModel.MLSGroupID? {
        return MLSGroupID(Data())
    }

    func e2eIdentityUpdateCertificateUpdateStatus() -> E2EIdentityCertificateUpdateStatusUseCaseProtocol? {
        MockE2EIdentityCertificateUpdateStatusUseCaseProtocol()
    }

    var isE2eIdentityEnabled = false
    var certificate = E2eIdentityCertificate.mockNotActivated
    typealias Preference = AppLockPasscodePreference
    typealias Callback = (AppLockModule.AuthenticationResult) -> Void

    lazy var mockGetUserClientFingerprintUseCaseProtocol: MockGetUserClientFingerprintUseCaseProtocol = {
        let mock = MockGetUserClientFingerprintUseCaseProtocol()
        mock.invokeUserClient_MockMethod = { _ in
            return Data("102030405060708090102030405060708090102030405060708090".utf8)
        }
        return mock
    }()

    var _authenticationResult: AppLockAuthenticationResult = .unavailable
    var _evaluationContext = LAContext()

    var mockConversationDirectory = MockConversationDirectory()

    var setEncryptionAtRest: [(enabled: Bool, skipMigration: Bool)] = []

    var unlockDatabase_MockInvocations: [Void] = []

    var openApp: [Void] = []

    var evaluateAuthentication: [(preference: Preference, description: String, callback: Callback)] = []

    var evaluateAuthenticationWithCustomPasscode: [String] = []

    var _passcode: String?

    var networkState: NetworkState = .offline

    var selfUser: any UserType

    var selfUserLegalHoldSubject: any SelfUserLegalHoldable

    var editableSelfUser: any EditableUserType & UserType

    var mockConversationList: ConversationList?

    var searchUsersCache: SearchUsersCache

    var mlsGroupVerification: (any MLSGroupVerificationProtocol)?

    func makeGetMLSFeatureUseCase() -> GetMLSFeatureUseCaseProtocol {
        let mock = MockGetMLSFeatureUseCaseProtocol()
        mock.invoke_MockValue = .init(status: .disabled, config: .init())
        return mock
    }

    convenience init(mockUser: MockZMEditableUser) {
        self.init(
            selfUser: mockUser,
            selfUserLegalHoldSubject: mockUser,
            editableSelfUser: mockUser
        )
    }

    convenience init(mockUser: MockUserType = .createDefaultSelfUser()) {
        self.init(
            selfUser: mockUser,
            selfUserLegalHoldSubject: mockUser,
            editableSelfUser: mockUser
        )
    }

    init(
        selfUser: any UserType,
        selfUserLegalHoldSubject: any SelfUserLegalHoldable,
        editableSelfUser: any EditableUserType & UserType
    ) {
        self.selfUser = selfUser
        self.selfUserLegalHoldSubject = selfUserLegalHoldSubject
        self.editableSelfUser = editableSelfUser

        searchUsersCache = .init()
        userProfile = MockUserProfile()
    }

    var lock: SessionLock? = .screen

    var isLocked = false
    var requiresScreenCurtain = false
    var isAppLockActive: Bool = false
    var isAppLockAvailable: Bool = false
    var isAppLockForced: Bool = false
    var appLockTimeout: UInt = 60
    var requireCustomAppLockPasscode: Bool = false
    var isCustomAppLockPasscodeSet: Bool = false
    var needsToNotifyUserOfAppLockConfiguration: Bool = false

    func openAppLock() throws {
        openApp.append(())
    }

    func evaluateAppLockAuthentication(
        passcodePreference: AppLockPasscodePreference,
        description: String,
        callback: @escaping (AppLockAuthenticationResult) -> Void
    ) {
        evaluateAuthentication.append((passcodePreference, description, callback))
        callback(_authenticationResult)
    }

    func evaluateAuthentication(customPasscode: String) -> AppLockAuthenticationResult {
        evaluateAuthenticationWithCustomPasscode.append(customPasscode)
        return _passcode == customPasscode ? .granted : .denied
    }

    func unlockDatabase() throws {
        unlockDatabase_MockInvocations.append(())
    }

    var maxAudioMessageLength: TimeInterval = 1500 // 25 minutes (25 * 60.0)
    var maxUploadFileSize: UInt64 = 26214400 // 25 megabytes (25 * 1024 * 1024)
    var maxVideoLength: TimeInterval = 240 // 4 minutes (4.0 * 60.0)

    var shouldNotifyUserOfDisabledAppLock = false
    var isNotificationContentHidden = false
    var encryptMessagesAtRest = false
    var ringingCallConversation: ZMConversation?

    var deleteAppLockPasscodeCalls = 0
    func deleteAppLockPasscode() throws {
        deleteAppLockPasscodeCalls += 1
    }

    var conversationDirectory: ConversationDirectoryType {
        return mockConversationDirectory
    }

    func perform(_ changes: @escaping () -> Void) {
        changes()
    }

    func enqueue(_ changes: @escaping () -> Void) {
        changes()
    }

    func enqueue(_ changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        fatalError("not implemented")
    }

    func addUserObserver(_ observer: UserObserving, for user: UserType) -> NSObjectProtocol? {
        return nil
    }

    func addUserObserver(_ observer: UserObserving) -> NSObjectProtocol {
        return NSObject()
    }

    func addConversationListObserver(
        _ observer: WireDataModel.ZMConversationListObserver,
        for list: ConversationList
    ) -> NSObjectProtocol {
        return NSObject()
    }

    func conversationList() -> ConversationList {
        guard let mockConversationList else { fatalError("mockConversationList is not set") }
        return mockConversationList
    }

    func pendingConnectionConversationsInUserSession() -> ConversationList {
        guard let mockConversationList else { fatalError("mockConversationList is not set") }
        return mockConversationList
    }

    func archivedConversationsInUserSession() -> ConversationList {
        guard let mockConversationList else { fatalError("mockConversationList is not set") }
        return mockConversationList
    }

    func setEncryptionAtRest(
        enabled: Bool,
        skipMigration: Bool
    ) throws {
        setEncryptionAtRest.append((enabled: enabled, skipMigration: skipMigration))
    }

    func addMessageObserver(
        _ observer: ZMMessageObserver,
        for message: ZMConversationMessage
    ) -> NSObjectProtocol {
        return NSObject()
    }

    func addConferenceCallingUnavailableObserver(
        _ observer: ConferenceCallingUnavailableObserver
    ) -> Any {
        return NSObject()
    }

    func addConferenceCallStateObserver(
        _ observer: WireCallCenterCallStateObserver
    ) -> Any {
        return NSObject()
    }

    func addConferenceCallErrorObserver(
        _ observer: WireCallCenterCallErrorObserver
    ) -> Any {
        return NSObject()
    }

    func acknowledgeFeatureChange(for feature: Feature.Name) {

    }

    func fetchMarketingConsent(
        completion: @escaping (
            Result<Bool, Error>
        ) -> Void
    ) {

    }

    func setMarketingConsent(
        granted: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {

    }

    func classification(
        users: [UserType],
        conversationDomain: String?
    ) -> SecurityClassification? {
        return .none
    }

    func proxiedRequest(
        path: String,
        method: ZMTransportRequestMethod,
        type: WireSyncEngine.ProxiedRequestType,
        callback: WireSyncEngine.ProxyRequestCallback?
    ) -> WireSyncEngine.ProxyRequest {
        return ProxyRequest(type: type, path: path, method: method, callback: callback)
    }

    func cancelProxiedRequest(_ request: WireSyncEngine.ProxyRequest) {

    }

    var getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol {
        mockGetUserClientFingerprintUseCaseProtocol
    }

    lazy var isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol = {
        let mock = MockIsUserE2EICertifiedUseCaseProtocol()
        mock.invokeConversationUser_MockValue = false
        return mock
    }()

    lazy var isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol = {
        let mock = MockIsSelfUserE2EICertifiedUseCaseProtocol()
        mock.invoke_MockValue = false
        return mock
    }()

    var selfUserClient: UserClient? {
        return nil
    }

    var enrollE2EICertificate: EnrollE2EICertificateUseCaseProtocol {
        MockEnrollE2EICertificateUseCaseProtocol()
    }

    var getIsE2eIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol {
        MockGetIsE2EIdentityEnabledUseCaseProtocol()
    }

    var getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol {
        MockGetE2eIdentityCertificatesUseCaseProtocol()
    }

    func makeConversationSecureGuestLinkUseCase() -> CreateConversationGuestLinkUseCaseProtocol {
        MockCreateConversationGuestLinkUseCaseProtocol()
    }

    func makeSetConversationGuestsAndServicesUseCase() -> SetAllowGuestAndServicesUseCaseProtocol {
        MockSetAllowGuestAndServicesUseCaseProtocol()
    }

    func makeAppendTextMessageUseCase() -> any AppendTextMessageUseCaseProtocol {
        AppendTextMessageUseCase(analyticsSession: nil)
    }

    func makeAppendImageMessageUseCase() -> any AppendImageMessageUseCaseProtocol {
        AppendImageMessageUseCase(analyticsSession: nil)
    }

    func makeAppendKnockMessageUseCase() -> any AppendKnockMessageUseCaseProtocol {
        AppendKnockMessageUseCase(analyticsSession: nil)
    }

    func makeAppendLocationMessageUseCase() -> any AppendLocationMessagekUseCaseProtocol {
        AppendLocationMessageUseCase(analyticsSession: nil)
    }

    func makeAppendFileMessageUseCase() -> any WireSyncEngine.AppendFileMessageUseCaseProtocol {
        AppendFileMessageUseCase(analyticsSession: nil)
    }

    func makeToggleMessageReactionUseCase() -> any ToggleMessageReactionUseCaseProtocol {
        ToggleMessageReactionUseCase(analyticsSession: nil)
    }

    var e2eiFeature: Feature.E2EI = Feature.E2EI(status: .enabled)

    var mlsFeature: Feature.MLS = Feature.MLS(
        status: .enabled,
        config: .init(defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
    )

    func fetchAllClients() {}

    var createTeamOneOnOneWithCompletion_Invocations: [(user: UserType, completion: (Swift.Result<ZMConversation, CreateTeamOneOnOneConversationError>) -> Void)] = []
    var createTeamOneOnOneWithCompletion_MockMethod: ((UserType, @escaping (Swift.Result<ZMConversation, CreateTeamOneOnOneConversationError>) -> Void) -> Void)?

    func createTeamOneOnOne(
        with user: UserType,
        completion: @escaping (Swift.Result<ZMConversation, CreateTeamOneOnOneConversationError>) -> Void
    ) {
        createTeamOneOnOneWithCompletion_Invocations.append((user: user, completion: completion))

        guard let mock = createTeamOneOnOneWithCompletion_MockMethod else {
            fatalError("no mock for `createTeamOneOnOneWithCompletion`")
        }

        mock(user, completion)
    }

    var mockCheckOneOnOneConversationIsReady: MockCheckOneOnOneConversationIsReadyUseCaseProtocol?
    var checkOneOnOneConversationIsReady: CheckOneOnOneConversationIsReadyUseCaseProtocol {
        mockCheckOneOnOneConversationIsReady ?? MockCheckOneOnOneConversationIsReadyUseCaseProtocol()
    }

    // MARK: - Notifications

    var notificationContext: any NotificationContext {
        viewContext.notificationContext
    }

    // MARK: - Context Provider

    var coreDataStack: CoreDataStack?

    var contextProvider: any ContextProvider {
        coreDataStack ?? MockContextProvider()
    }

}

// MARK: - UserSessionMock + ContextProvider

extension UserSessionMock: ContextProvider {

    var account: Account { contextProvider.account }
    var viewContext: NSManagedObjectContext { contextProvider.viewContext }
    var syncContext: NSManagedObjectContext { contextProvider.syncContext }
    var searchContext: NSManagedObjectContext { contextProvider.searchContext }
    var eventContext: NSManagedObjectContext { contextProvider.eventContext }
}
