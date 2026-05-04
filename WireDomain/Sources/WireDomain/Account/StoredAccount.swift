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
import WireDataModel

struct StoredAccount: Codable {

    var identifier: UUID
    var name: String
    var handle: String?
    var image: Data?
    var team: String?
    var teamImage: Data?
    var backendName: String?
    var loginCredentials: StoredLoginCredentials?
    var unreadConversationCount: Int

    init(_ account: Account) {
        self.identifier = account.userIdentifier
        self.name = account.userName
        self.handle = account.handle
        self.image = account.imageData
        self.team = account.teamName
        self.teamImage = account.teamImageData
        self.backendName = account.backendName
        self.loginCredentials = account.loginCredentials.map {
            StoredLoginCredentials($0)
        }
        self.unreadConversationCount = account.unreadConversationCount
    }

}

struct StoredLoginCredentials: Codable {

    var emailAddress: String?
    var usesCompanyLogin: Bool

    init(_ loginCredentials: LoginCredentials) {
        self.emailAddress = loginCredentials.emailAddress
        self.usesCompanyLogin = loginCredentials.usesCompanyLogin
    }

}

extension Account {

    convenience init(_ storedAccount: StoredAccount) {
        self.init(
            userName: storedAccount.name,
            userIdentifier: storedAccount.identifier,
            teamName: storedAccount.team,
            handle: storedAccount.handle,
            backendName: storedAccount.backendName,
            imageData: storedAccount.image,
            teamImageData: storedAccount.teamImage,
            unreadConversationCount: storedAccount.unreadConversationCount,
            loginCredentials: storedAccount.loginCredentials.map {
                LoginCredentials($0)
            }
        )
    }

}

extension LoginCredentials {

    convenience init(_ loginCredentials: StoredLoginCredentials) {
        self.init(
            emailAddress: loginCredentials.emailAddress,
            usesCompanyLogin: loginCredentials.usesCompanyLogin
        )
    }

}
