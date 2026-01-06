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

import XCTest

enum UserGenerator {

    static func generateUniqueUserInfo() -> UserInfo {
        let password = generateRandomPassword()

        let time = Int(Date().timeIntervalSince1970 * 1000)
        let random = Int.random(in: 100 ... 999)

        let username = "smoketester\(time)\(random)"
        let domain = "wire.engineering"
        let name = "Smoke Tester \(time)\(random)"
        let teamName = "Team-Smoke \(time)\(random)"
        return UserInfo(
            name: name,
            username: username,
            password: password,
            domain: domain,
            teamName: teamName,
            teamID: nil
        )
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

    static func generateRandomGroupName() -> String {
        let timestamp = Int(Date().timeIntervalSince1970) % 100_000
        let hex = String(format: "%03x", Int.random(in: 0 ... 0xFFF))
        return "Group_\(timestamp)\(hex)"
    }

    static func generateRandomMessage() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let random = Int.random(in: 100_000 ... 999_999)
        return "hello! \(timestamp)_\(random)"
    }

    static func generateAppPasscode(length: Int = 8) -> String {
        let sets = [
            "abcdefghijklmnopqrstuvwxyz",
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
            "0123456789",
            "!@#$%^&*()-_=+{}[]|:;,.<>?/`~"
        ]
        var password = sets.compactMap { $0.randomElement() }
        let all = sets.joined()
        while password.count < length {
            password.append(all.randomElement()!)
        }
        return String(password.shuffled())
    }

}
