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

final class UserSessionMock: UserSession {

    var selfUser: ZMUser {
        fatalError("not implemented")
    }

    var isLocked = false
    var requiresScreenCurtain = false
    var shouldNotifyUserOfDisabledAppLock = false
    var isNotificationContentHidden = false
    var encryptMessagesAtRest = false
    var ringingCallConversation: ZMConversation?

    var deleteAppLockPasscodeCalls = 0
    func deleteAppLockPasscode() throws {
        deleteAppLockPasscodeCalls += 1
    }

    func perform(_ changes: @escaping () -> Void) {
        fatalError("not implemented")
    }

    func enqueue(_ changes: @escaping () -> Void) {
        fatalError("not implemented")
    }

    func enqueue(_ changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        fatalError("not implemented")
    }

    func addUserObserver(_ observer: ZMUserObserver, for: UserType) -> NSObjectProtocol? {
        fatalError("not implemented")
    }

    func conversationList() -> ZMConversationList {
        fatalError("not implemented")
    }

}
