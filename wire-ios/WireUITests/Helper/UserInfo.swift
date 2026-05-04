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

class UserInfo {

    var name: String
    var username: String
    var email: String
    var domain: String
    var password: String
    var id: String
    var backendDomain: String
    var teamName: String
    var teamID: UUID?

    init(name: String, username: String, password: String, domain: String, teamName: String, teamID: UUID?) {
        self.name = name
        self.username = username
        self.password = password
        self.domain = domain
        self.email = username + "@" + domain
        self.id = ""
        self.backendDomain = ""
        self.teamName = teamName
        self.teamID = teamID
    }

    init(email: String, password: String) {
        self.name = ""
        self.username = ""
        self.password = password
        self.domain = ""
        self.email = email
        self.id = ""
        self.backendDomain = ""
        self.teamName = ""
    }

    init() {
        self.name = ""
        self.username = ""
        self.password = ""
        self.domain = ""
        self.email = ""
        self.id = ""
        self.backendDomain = ""
        self.teamName = ""
        self.teamID = nil
    }

    func updateUserInfo(newInfo: UserInfo) {
        if !newInfo.name.isEmpty {
            name = newInfo.name
        }
        if !newInfo.username.isEmpty {
            username = newInfo.username
        }
        if !newInfo.password.isEmpty {
            password = newInfo.password
        }
        if !newInfo.domain.isEmpty {
            domain = newInfo.domain
        }
        if !newInfo.id.isEmpty {
            id = newInfo.id
        }
        if !newInfo.backendDomain.isEmpty {
            backendDomain = newInfo.backendDomain
        }
    }
}
