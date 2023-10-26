//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

/// An abstraction of the user session for use in the presentation
/// layer.

public protocol UserSession: AnyObject {

    /// Whether the session needs to be unlocked by the user
    /// via passcode or biometric authentication.

    var isLocked: Bool { get }

    /// Whether the screen curtain is required.
    ///
    /// The screen curtain hides the contents of the app while it is
    /// not in actvie, such as when it is in the task switcher.

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

    /// Whether the user should be notified of the app lock being disabled.

    var shouldNotifyUserOfDisabledAppLock: Bool { get }

    /// Delete the app lock passcode if it exists.

    func deleteAppLockPasscode() throws

    /// The user who is logged into this session.
    ///
    /// This can only be used on the main thread.

    var selfUser: UserType { get }

    var selfLegalHoldSubject: UserType & SelfLegalHoldSubject { get }

    func perform(_ changes: @escaping () -> Void)

    func enqueue(_ changes: @escaping () -> Void)

    func enqueue(
        _ changes: @escaping () -> Void,
        completionHandler: (() -> Void)?
    )

    // TODO: rename to "shouldHideNotificationContent"
    var isNotificationContentHidden: Bool { get set }

    // TODO: rename to "isEncryptionAtRestEnabled"
    var encryptMessagesAtRest: Bool { get }

    func setEncryptionAtRest(enabled: Bool, skipMigration: Bool) throws

    func addUserObserver(
        _ observer: ZMUserObserver,
        for: UserType
    ) -> NSObjectProtocol?

    func addMessageObserver(
        _ observer: ZMMessageObserver,
        for message: ZMConversationMessage
    ) -> NSObjectProtocol

    func addConferenceCallingUnavailableObserver(_ observer: ConferenceCallingUnavailableObserver) -> Any

    func addConversationListObserver(
        _ observer: ZMConversationListObserver,
        for list: ZMConversationList
    ) -> NSObjectProtocol

    func conversationList() -> ZMConversationList

    var ringingCallConversation: ZMConversation? { get }

    var maxAudioMessageLength: TimeInterval { get }

    var maxUploadFileSize: UInt64 { get }

    func acknowledgeFeatureChange(for feature: Feature.Name)

    func fetchMarketingConsent(completion: @escaping (Result<Bool>) -> Void)

    func setMarketingConsent(
        granted: Bool,
        completion: @escaping (VoidResult) -> Void
    )

}

extension ZMUserSession: UserSession {

    public var isLocked: Bool {
        return isDatabaseLocked || appLockController.isLocked
    }

    public var requiresScreenCurtain: Bool {
        return appLockController.isActive || encryptMessagesAtRest
    }

    public var isAppLockActive: Bool {
        get {
            appLockController.isActive
        }

        set {
            appLockController.isActive = newValue
        }
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

    public var shouldNotifyUserOfDisabledAppLock: Bool {
        return appLockController.needsToNotifyUser && !appLockController.isActive
    }

    public func deleteAppLockPasscode() throws {
        try appLockController.deletePasscode()
    }

    public var selfUser: UserType {
        return ZMUser.selfUser(inUserSession: self)
    }

    public var selfLegalHoldSubject: UserType & SelfLegalHoldSubject {
        return ZMUser.selfUser(inUserSession: self)
    }

    public func addUserObserver(
        _ observer: ZMUserObserver,
        for user: UserType
    ) -> NSObjectProtocol? {
        return UserChangeInfo.add(
            observer: observer,
            for: user,
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

    public func addConversationListObserver(
        _ observer: ZMConversationListObserver,
        for list: ZMConversationList
    ) -> NSObjectProtocol {
        return ConversationListChangeInfo.add(
            observer: observer,
            for: list,
            userSession: self
        )
    }

    public func conversationList() -> ZMConversationList {
        return .conversations(inUserSession: self)
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
            Result<Bool>
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
        completion: @escaping (VoidResult) -> Void
    ) {
        ZMUser.selfUser(inUserSession: self).setMarketingConsent(
            to: granted,
            in: self,
            completion: completion
        )
    }

}

extension UInt64 {
    private static let MaxFileSize: UInt64 = 26214400 // 25 megabytes (25 * 1024 * 1024)
    private static let MaxTeamFileSize: UInt64 = 104857600 // 100 megabytes (100 * 1024 * 1024)

    public static func uploadFileSizeLimit(hasTeam: Bool) -> UInt64 {
        return hasTeam ? MaxTeamFileSize : MaxFileSize
    }
}
