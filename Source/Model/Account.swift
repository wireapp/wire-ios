//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension Account : NotificationContext { }

extension Notification.Name {
    public static let AccountUnreadCountDidChangeNotification = Notification.Name("AccountUnreadCountDidChangeNotification")
}

/// An `Account` holds information related to a single account,
/// such as the accounts users name,
/// team name if there is any, picture and uuid.
public final class Account: NSObject {

    public var userName: String
    public var teamName: String?
    public let userIdentifier: UUID
    public var imageData: Data?
    
    public var unreadConversationCount: Int = 0 {
        didSet {
            if oldValue != self.unreadConversationCount {
                NotificationInContext(name: .AccountUnreadCountDidChangeNotification, context: self).post()
            }
        }
    }

    public required init(userName: String,
                         userIdentifier: UUID,
                         teamName: String? = nil,
                         imageData: Data? = nil,
                         unreadConversationCount: Int = 0) {
        self.userName = userName
        self.userIdentifier = userIdentifier
        self.teamName = teamName
        self.imageData = imageData
        self.unreadConversationCount = unreadConversationCount
        super.init()
    }
    
    /// Updates the properties of the receiver with the given account. Use this method
    /// when you wish to update an exisiting account object with newly fetched properties
    /// from the account store.
    ///
    public func updateWith(_ account: Account) {
        guard self.userIdentifier == account.userIdentifier else { return }
        self.userName = account.userName
        self.teamName = account.teamName
        self.imageData = account.imageData
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Account else { return false }
        return userName == other.userName
            && teamName == other.teamName
            && userIdentifier == other.userIdentifier
            && imageData == other.imageData
    }

    public override var hash: Int {
        return userIdentifier.hashValue
    }

    public override var debugDescription: String {
        return "<Account>:\n\tname: \(userName)\n\tid: \(userIdentifier)\n\tteam: \(String(describing: teamName))\n\timage: \(String(describing: imageData?.count))\n"
    }
}

// MARK: - Dictionary Representation

extension Account {

    /// The use of a separate enum, instead of using #keyPath
    /// is intentional here to allow easy renaming of properties.
    private enum Key: String {
        case name, identifier, team, image, unreadConversationCount
    }

    public convenience init?(json: [String: Any]) {
        guard let id = (json[Key.identifier.rawValue] as? String).flatMap(UUID.init),
            let name = json[Key.name.rawValue] as? String else { return nil }
        self.init(
            userName: name,
            userIdentifier: id,
            teamName: json[Key.team.rawValue] as? String,
            imageData: (json[Key.image.rawValue] as? String).flatMap { Data(base64Encoded: $0) },
            unreadConversationCount: (json[Key.unreadConversationCount.rawValue] as? Int) ?? 0
        )
    }

    public func jsonRepresentation() -> [String: Any] {
        var json: [String: Any] = [
            Key.name.rawValue: userName,
            Key.identifier.rawValue: userIdentifier.uuidString
        ]
        if let teamName = teamName {
            json[Key.team.rawValue] = teamName
        }
        if let imageData = imageData {
            json[Key.image.rawValue] = imageData.base64EncodedString()
        }
        json[Key.unreadConversationCount.rawValue] = self.unreadConversationCount
        return json
    }

}

// MARK: - Serialization Helper

extension Account {

    func write(to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: jsonRepresentation())
        try data.write(to: url, options: [.atomic])
    }

    static func load(from url: URL) -> Account? {
        let data = try? Data(contentsOf: url)
        return data.flatMap {
            (try? JSONSerialization.jsonObject(with: $0, options: [])) as? [String: Any]
        }.flatMap(Account.init)
    }

}
