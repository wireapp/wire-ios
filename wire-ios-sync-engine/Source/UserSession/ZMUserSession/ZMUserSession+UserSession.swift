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
import WireAnalytics
import WireDataModel

extension ZMUserSession: UserSession {

    // MARK: Properties

    public var lock: SessionLock? {
        if isDatabaseLocked {
            return .database
        } else if appLockController.isLocked {
            return .screen
        } else {
            return nil
        }
    }

    public var isLocked: Bool {
        return isDatabaseLocked || appLockController.isLocked
    }

    public var requiresScreenCurtain: Bool {
        return appLockController.isActive || encryptMessagesAtRest
    }

    public var isAppLockActive: Bool {
        get { appLockController.isActive }
        set { appLockController.isActive = newValue }
    }

    public var isAppLockAvailable: Bool {
        return appLockController.isAvailable
    }

    public var isAppLockForced: Bool {
        return appLockController.isForced
    }

    public var appLockTimeout: UInt {
        return appLockController.timeout
    }

    public var requireCustomAppLockPasscode: Bool {
        appLockController.requireCustomPasscode
    }

    public var isCustomAppLockPasscodeSet: Bool {
        appLockController.isCustomPasscodeSet
    }

    public var shouldNotifyUserOfDisabledAppLock: Bool {
        appLockController.needsToNotifyUser && !appLockController.isActive
    }

    public var needsToNotifyUserOfAppLockConfiguration: Bool {
        get {
            appLockController.needsToNotifyUser
        }
        set {
            appLockController.needsToNotifyUser = newValue
        }
    }

    // MARK: Dependency Injection

    public var searchUsersCache: SearchUsersCache {
        dependencies.caches.searchUsers
    }

    // MARK: Methods

    public func openAppLock() throws {
        try appLockController.open()
    }

    public func evaluateAppLockAuthentication(
        passcodePreference: AppLockPasscodePreference,
        description: String,
        callback: @escaping (AppLockAuthenticationResult) -> Void
    ) {
        return appLockController.evaluateAuthentication(
            passcodePreference: passcodePreference,
            description: description,
            callback: callback
        )
    }

    public func evaluateAuthentication(customPasscode: String) -> AppLockAuthenticationResult {
        appLockController.evaluateAuthentication(customPasscode: customPasscode)
    }

    public func unlockDatabase() throws {
        try earService.unlockDatabase()

        DatabaseEncryptionLockNotification(databaseIsEncrypted: false).post(in: notificationContext)

        processEvents()
    }

    public func deleteAppLockPasscode() throws {
        try appLockController.deletePasscode()
    }

    public var selfUser: any UserType {
        ZMUser.selfUser(inUserSession: self)
    }

    public var selfUserLegalHoldSubject: any SelfUserLegalHoldable {
        ZMUser.selfUser(inUserSession: self)
    }

    public var editableSelfUser: any EditableUserType & UserType {
        ZMUser.selfUser(inUserSession: self)
    }

    public func addUserObserver(
        _ observer: UserObserving,
        for user: UserType
    ) -> NSObjectProtocol? {
        return UserChangeInfo.add(
            observer: observer,
            for: user,
            in: self
        )
    }

    public func addUserObserver(
        _ observer: UserObserving
    ) -> NSObjectProtocol {
        return UserChangeInfo.add(
            userObserver: observer,
            in: self
        )
    }

    public func addMessageObserver(
        _ observer: ZMMessageObserver,
        for message: ZMConversationMessage
    ) -> NSObjectProtocol {
        return MessageChangeInfo.add(
            observer: observer,
            for: message,
            userSession: self
        )
    }

    public func addConferenceCallingUnavailableObserver(
        _ observer: ConferenceCallingUnavailableObserver
    ) -> Any {
        return WireCallCenterV3.addConferenceCallingUnavailableObserver(
            observer: observer,
            userSession: self
        )
    }

    public func addConferenceCallStateObserver(
        _ observer: WireCallCenterCallStateObserver
    ) -> Any {
        return WireCallCenterV3.addCallStateObserver(
            observer: observer,
            userSession: self
        )
    }

    public func addConferenceCallErrorObserver(
        _ observer: WireCallCenterCallErrorObserver
    ) -> Any {
        return WireCallCenterV3.addCallErrorObserver(
            observer: observer,
            userSession: self
        )
    }

    public func addConversationListObserver(
        _ observer: ZMConversationListObserver,
        for list: ConversationList
    ) -> NSObjectProtocol {
        return ConversationListChangeInfo.add(
            observer: observer,
            for: list,
            userSession: self
        )
    }

    public func conversationList() -> ConversationList {
        .conversations(inUserSession: self)!
    }

    public func pendingConnectionConversationsInUserSession() -> ConversationList {
        .pendingConnectionConversations(inUserSession: self)!
    }

    public func archivedConversationsInUserSession() -> ConversationList {
        .archivedConversations(inUserSession: self)!
    }

    public var ringingCallConversation: ZMConversation? {
        guard let callCenter = self.callCenter else {
            return nil
        }

        return callCenter.nonIdleCallConversations(in: self).first { conversation in
            guard let callState = conversation.voiceChannel?.state else {
                return false
            }

            switch callState {
            case .incoming, .outgoing:
                return true

            default:
                return false
            }
        }
    }

    static let MaxVideoWidth: UInt64 = 1920 // FullHD

    static let MaxAudioLength: TimeInterval = 1500 // 25 minutes (25 * 60.0)
    private static let MaxTeamAudioLength: TimeInterval = 6000 // 100 minutes (100 * 60.0)
    private static let MaxVideoLength: TimeInterval = 240 // 4 minutes (4.0 * 60.0)
    private static let MaxTeamVideoLength: TimeInterval = 960 // 16 minutes (16.0 * 60.0)

    private var selfUserHasTeam: Bool {
        return selfUser.hasTeam
    }

    public var maxUploadFileSize: UInt64 {
        return UInt64.uploadFileSizeLimit(hasTeam: selfUserHasTeam)
    }

    public var maxAudioMessageLength: TimeInterval {
        return selfUserHasTeam ? ZMUserSession.MaxTeamAudioLength : ZMUserSession.MaxAudioLength
    }

    public var maxVideoLength: TimeInterval {
        return selfUserHasTeam ? ZMUserSession.MaxTeamVideoLength : ZMUserSession.MaxVideoLength
    }

    public func acknowledgeFeatureChange(for feature: Feature.Name) {
        featureRepository.setNeedsToNotifyUser(false, for: feature)
    }

    public func fetchMarketingConsent(
        completion: @escaping (
            Result<Bool, Error>
        ) -> Void
    ) {
        ZMUser.selfUser(inUserSession: self).fetchConsent(
            for: .marketing,
            on: transportSession,
            completion: completion
        )
    }

    public func setMarketingConsent(
        granted: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        ZMUser.selfUser(inUserSession: self).setMarketingConsent(
            to: granted,
            in: self,
            completion: completion
        )
    }

    // MARK: Context provider

    public var contextProvider: any ContextProvider {
        return self
    }

    // MARK: Use Cases

    public var isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol {
        IsUserE2EICertifiedUseCase(
            schedule: .immediate,
            coreCryptoProvider: coreCryptoProvider,
            featureRepository: FeatureRepository(context: syncContext),
            featureRepositoryContext: syncContext
        )
    }

    public var isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol {
        IsSelfUserE2EICertifiedUseCase(
            context: syncContext,
            featureRepository: FeatureRepository(context: syncContext),
            featureRepositoryContext: syncContext,
            isUserE2EICertifiedUseCase: isUserE2EICertifiedUseCase
        )
    }

    public var checkOneOnOneConversationIsReady: CheckOneOnOneConversationIsReadyUseCaseProtocol {
        CheckOneOnOneConversationIsReadyUseCase(
            context: syncContext,
            coreCryptoProvider: coreCryptoProvider
        )
    }

    public func makeGetMLSFeatureUseCase() -> GetMLSFeatureUseCaseProtocol {
        let featureRepository = FeatureRepository(context: syncContext)
        return GetMLSFeatureUseCase(featureRepository: featureRepository)
    }

    public func makeConversationSecureGuestLinkUseCase() -> CreateConversationGuestLinkUseCaseProtocol {
        return CreateConversationGuestLinkUseCase(setGuestsAndServicesUseCase: makeSetConversationGuestsAndServicesUseCase())
    }

    public func makeSetConversationGuestsAndServicesUseCase() -> SetAllowGuestAndServicesUseCaseProtocol {
        return SetAllowGuestAndServicesUseCase()
    }

    @MainActor
    public func fetchSelfConversationMLSGroupID() async -> MLSGroupID? {
        return await syncContext.perform {
            return ZMConversation.fetchSelfMLSConversation(in: self.syncContext)?.mlsGroupID
        }
    }

    @MainActor
    public func e2eIdentityUpdateCertificateUpdateStatus() -> E2EIdentityCertificateUpdateStatusUseCaseProtocol? {
        guard let selfUserClient,
              let selfMLSClientID = MLSClientID(userClient: selfUserClient),
              e2eiFeature.isEnabled
        else {
            return nil
        }

        return E2EIdentityCertificateUpdateStatusUseCase(
            getE2eIdentityCertificates: getE2eIdentityCertificates,
            gracePeriod: TimeInterval(e2eiFeature.config.verificationExpiration), // the feature repository should better be injected into the use case
            mlsClientID: selfMLSClientID,
            context: syncContext,
            lastE2EIUpdateDateRepository: lastE2EIUpdateDateRepository
        )
    }

    public func makeAppendTextMessageUseCase() -> AppendTextMessageUseCaseProtocol {
        return AppendTextMessageUseCase(analyticsEventTracker: analyticsEventTracker)
    }

    public func makeAppendImageMessageUseCase() -> AppendImageMessageUseCaseProtocol {
        return AppendImageMessageUseCase(analyticsEventTracker: analyticsEventTracker)
    }

    public func makeAppendKnockMessageUseCase() -> AppendKnockMessageUseCaseProtocol {
        return AppendKnockMessageUseCase(analyticsEventTracker: analyticsEventTracker)
    }

    public func makeAppendLocationMessageUseCase() -> AppendLocationMessagekUseCaseProtocol {
        return AppendLocationMessageUseCase(analyticsEventTracker: analyticsEventTracker)
    }

    public func makeAppendFileMessageUseCase() -> AppendFileMessageUseCaseProtocol {
        return AppendFileMessageUseCase(analyticsEventTracker: analyticsEventTracker)
    }

}

extension UInt64 {
    private static let MaxFileSize: UInt64 = 26214400 // 25 megabytes (25 * 1024 * 1024)
    private static let MaxTeamFileSize: UInt64 = 104857600 // 100 megabytes (100 * 1024 * 1024)

    public static func uploadFileSizeLimit(hasTeam: Bool) -> UInt64 {
        return hasTeam ? MaxTeamFileSize : MaxFileSize
    }
}
