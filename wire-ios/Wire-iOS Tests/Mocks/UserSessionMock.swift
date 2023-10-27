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

    var selfUser: UserType
    var selfLegalHoldSubject: SelfLegalHoldSubject & UserType
    var mockConversationList: ZMConversationList?

    convenience init(mockUser: MockZMEditableUser) {
        self.init(
            selfUser: mockUser,
            selfLegalHoldSubject: mockUser
        )
    }

    convenience init(mockUser: MockUserType = .createDefaultSelfUser()) {
        self.init(
            selfUser: mockUser,
            selfLegalHoldSubject: mockUser
        )
    }

    init(
        selfUser: UserType,
        selfLegalHoldSubject: SelfLegalHoldSubject & UserType
    ) {
        self.selfUser = selfUser
        self.selfLegalHoldSubject = selfLegalHoldSubject
    }

    var isLocked = false
    var requiresScreenCurtain = false
    var isAppLockActive: Bool = false
    var isAppLockAvailable: Bool = false
    var isAppLockForced: Bool = false
    var appLockTimeout: UInt = 60
    var maxAudioMessageLength: TimeInterval = 1500 // 25 minutes (25 * 60.0)
    var maxUploadFileSize: UInt64 = 26214400 // 25 megabytes (25 * 1024 * 1024)

    var shouldNotifyUserOfDisabledAppLock = false
    var isNotificationContentHidden = false
    var encryptMessagesAtRest = false
    var ringingCallConversation: ZMConversation?

    var deleteAppLockPasscodeCalls = 0
    func deleteAppLockPasscode() throws {
        deleteAppLockPasscodeCalls += 1
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

    func addUserObserver(_ observer: ZMUserObserver, for user: UserType) -> NSObjectProtocol? {
        return nil
    }

    func addConversationListObserver(
        _ observer: WireDataModel.ZMConversationListObserver,
        for list: ZMConversationList
    ) -> NSObjectProtocol {
        return NSObject()
    }

    func conversationList() -> ZMConversationList {
        guard let mockConversationList else { fatalError("mockConversationList is not set") }
        return mockConversationList
    }

    func setEncryptionAtRest(enabled: Bool, skipMigration: Bool) throws {

    }

    func addMessageObserver(
        _ observer: ZMMessageObserver,
        for message: ZMConversationMessage
    ) -> NSObjectProtocol {
        return NSObject()
    }

    func addConferenceCallingUnavailableObserver(_ observer: ConferenceCallingUnavailableObserver) -> Any {
        return NSObject()
    }

    func acknowledgeFeatureChange(for feature: Feature.Name) {

    }

    func fetchMarketingConsent(completion: @escaping (Result<Bool>) -> Void) {

    }

    func setMarketingConsent(granted: Bool, completion: @escaping (VoidResult) -> Void) {

    }

    func classification(with users: [UserType], conversationDomain: String?) -> SecurityClassification {
        return .none
    }

}
