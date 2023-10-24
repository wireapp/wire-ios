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

    func addUserObserver(
        _ observer: ZMUserObserver,
        for: UserType
    ) -> NSObjectProtocol?

    func conversationList() -> ZMConversationList

    var ringingCallConversation: ZMConversation? { get }
}

extension ZMUserSession: UserSession {

    public var isLocked: Bool {
        return isDatabaseLocked || appLockController.isLocked
    }

    public var requiresScreenCurtain: Bool {
        return appLockController.isActive || encryptMessagesAtRest
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
}
