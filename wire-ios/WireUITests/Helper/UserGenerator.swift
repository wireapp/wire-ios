//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import XCTest

class UserGenerator {
    static func generateUniqueUserInfo() -> UserInfo {
        let password = generateRandomPassword()
        let time = Int(NSDate().timeIntervalSince1970 * 1000)
        let username = "smoketester\(time)"
        let domain = "wire.engineering"
        let name = "Smoke Tester \(time)"
        return UserInfo(name, username: username, password: password, domain: domain)
    }

    static func generateRandomPassword() -> String {
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let uppercase = lowercase.uppercased()
        let numbers = "0123456789"
        let specials = "!@#$%^&*()"
        var password = ""
        for _ in 1 ... 5 {
            password += randomCharacterFrom(array: lowercase)
        }
        password += randomCharacterFrom(array: uppercase)
        password += randomCharacterFrom(array: specials)
        password += randomCharacterFrom(array: numbers)
        return password
    }

    static func randomCharacterFrom(array: String) -> String {
        let randomIndex = Int.random(in: 0 ..< array.count)
        let character = array[array.index(array.startIndex, offsetBy: randomIndex)]
        return String(character)
    }
}

struct UserInfo {
    let name: String
    let username: String
    let domain: String
    let password: String

    init(_ name: String, username: String, password: String, domain: String) {
        self.name = name
        self.username = username
        self.password = password
        self.domain = domain
    }

    var email: String {
        username+"@"+domain
    }
}
