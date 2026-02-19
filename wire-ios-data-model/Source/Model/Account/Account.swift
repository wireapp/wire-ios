//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import os

extension Account: NotificationContext {}

public extension Notification.Name {
    static let AccountUnreadCountDidChangeNotification = Notification.Name("AccountUnreadCountDidChangeNotification")
}

/// An `Account` holds information related to a single account,
/// such as the accounts users name,
/// team name if there is any, picture and uuid.
public final class Account: NSObject, Codable, @unchecked Sendable {

    private let lock = OSAllocatedUnfairLock()

    // MARK: - Codable keys

    enum CodingKeys: String, CodingKey {
        case _userName = "name"
        case _teamName = "team"
        case userIdentifier = "identifier"
        case _handle = "handle"
        case _backendName = "backendName"
        case _imageData = "image"
        case _teamImageData = "teamImage"
        case _unreadConversationCount = "unreadConversationCount"
        case _loginCredentials = "loginCredentials"
    }

    // MARK: - Private mutable properties with locked access

    private var _userName: String
    private var _teamName: String?
    private var _handle: String?
    private var _backendName: String?
    private var _imageData: Data?
    private var _teamImageData: Data?
    private var _loginCredentials: LoginCredentials?
    private var _unreadConversationCount: Int = 0

    // MARK: - Public

    public let userIdentifier: UUID

    public var userName: String {
        get { lock.withLock { _userName } }
        set { lock.withLock { _userName = newValue } }
    }

    public var teamName: String? {
        get { lock.withLock { _teamName } }
        set { lock.withLock { _teamName = newValue } }
    }

    public var handle: String? {
        get { lock.withLock { _handle } }
        set { lock.withLock { _handle = newValue } }
    }

    public var backendName: String? {
        get { lock.withLock { _backendName } }
        set { lock.withLock { _backendName = newValue } }
    }

    public var imageData: Data? {
        get { lock.withLock { _imageData } }
        set { lock.withLock { _imageData = newValue } }
    }

    public var teamImageData: Data? {
        get { lock.withLock { _teamImageData } }
        set { lock.withLock { _teamImageData = newValue } }
    }

    public var loginCredentials: LoginCredentials? {
        get { lock.withLock { _loginCredentials } }
        set { lock.withLock { _loginCredentials = newValue } }
    }

    public var unreadConversationCount: Int {
        get { lock.withLock { _unreadConversationCount } }
        set {
            let oldValue = lock.withLock {
                let oldValue = _unreadConversationCount
                _unreadConversationCount = newValue
                return oldValue
            }
            if oldValue != newValue {
                NotificationInContext(name: .AccountUnreadCountDidChangeNotification, context: self).post()
            }
        }
    }

    public required init(
        userName: String,
        userIdentifier: UUID,
        teamName: String? = nil,
        handle: String? = nil,
        backendName: String? = nil,
        imageData: Data? = nil,
        teamImageData: Data? = nil,
        unreadConversationCount: Int = 0,
        loginCredentials: LoginCredentials? = nil
    ) {
        self._userName = userName
        self.userIdentifier = userIdentifier
        self._teamName = teamName
        self._imageData = imageData
        self._teamImageData = teamImageData
        self._unreadConversationCount = unreadConversationCount
        self._loginCredentials = loginCredentials
        self._handle = handle
        self._backendName = backendName
        super.init()
    }

    /// Updates the properties of the receiver with the given account. Use this method
    /// when you wish to update an existing account object with newly fetched properties
    /// from the account store.
    ///
    public func updateWith(_ account: Account) {
        guard userIdentifier == account.userIdentifier else { return }
        lock.withLock {
            _userName = account._userName
            _teamName = account._teamName
            _imageData = account._imageData
            _teamImageData = account._teamImageData
            _loginCredentials = account._loginCredentials
            _handle = account._handle
            _backendName = account._backendName
        }
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Account else { return false }
        return userIdentifier == other.userIdentifier
    }

    public override var hash: Int {
        userIdentifier.hashValue
    }

    public override var debugDescription: String {
        "<Account>:\n\tname: \(userName)\n\tid: \(userIdentifier)\n\tcredentials:\n\t\(String(describing: loginCredentials?.debugDescription))\n\tteam: \(String(describing: teamName))\n\timage: \(String(describing: imageData?.count))\n\tteamImageData: \(String(describing: teamImageData?.count))\n"
    }

}

// MARK: - SafeForLoggingStringConvertible

extension Account: SafeForLoggingStringConvertible {

    public var safeForLoggingDescription: String {
        userIdentifier.uuidString
    }

}
