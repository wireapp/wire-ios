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

extension Account: NotificationContext {}

public extension Notification.Name {
    static let AccountUnreadCountDidChangeNotification = Notification.Name("AccountUnreadCountDidChangeNotification")
}

/// An `Account` holds information related to a single account,
/// such as the accounts users name,
/// team name if there is any, picture and uuid.
public final class Account: NSObject, Codable {

    public var userName: String
    public var teamName: String?
    public let userIdentifier: UUID
    public var handle: String?
    public var backendName: String?
    public var imageData: Data?
    public var teamImageData: Data?
    public var loginCredentials: LoginCredentials?

    public var unreadConversationCount: Int = 0 {
        didSet {
            if oldValue != unreadConversationCount {
                NotificationInContext(name: .AccountUnreadCountDidChangeNotification, context: self).post()
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case userName = "name"
        case teamName = "team"
        case userIdentifier = "identifier"
        case handle
        case backendName
        case imageData = "image"
        case teamImageData = "teamImage"
        case unreadConversationCount
        case loginCredentials

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
        self.userName = userName
        self.userIdentifier = userIdentifier
        self.teamName = teamName
        self.imageData = imageData
        self.teamImageData = teamImageData
        self.unreadConversationCount = unreadConversationCount
        self.loginCredentials = loginCredentials
        self.handle = handle
        self.backendName = backendName
        super.init()
    }

    /// Updates the properties of the receiver with the given account. Use this method
    /// when you wish to update an existing account object with newly fetched properties
    /// from the account store.
    ///
    public func updateWith(_ account: Account) {
        guard userIdentifier == account.userIdentifier else { return }
        userName = account.userName
        teamName = account.teamName
        imageData = account.imageData
        teamImageData = account.teamImageData
        loginCredentials = account.loginCredentials
        handle = account.handle
        backendName = account.backendName
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
