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
import UIKit

// MARK: - CreatePasswordSecuredLinkViewModelDelegate

// sourcery: AutoMockable
protocol CreatePasswordSecuredLinkViewModelDelegate: AnyObject {
    func generateButtonDidTap(_ password: String)
}

// MARK: - CreatePasswordSecuredLinkViewModel

final class CreatePasswordSecuredLinkViewModel {

    // MARK: - Properties

    weak var delegate: CreatePasswordSecuredLinkViewModelDelegate?

    // MARK: - Methods

    func requestRandomPassword() {
        let randomPassword = generateRandomPassword()
        delegate?.generateButtonDidTap(randomPassword)
    }

    func validatePassword(textfield: UITextField, with string: String) -> Bool {

        let updatedString = (textfield.text as NSString?)?.replacingCharacters(in: NSRange(location: 0, length: 0), with: string) ?? string

        // Ensure at least 8 characters with one lowercase letter, one capital letter, a number, and a special character
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^a-zA-Z\\d]).{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)

        return passwordPredicate.evaluate(with: updatedString)
    }

    func generateRandomPassword() -> String {
        let length = 8
        let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
        let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let specialCharacters = "!@#$%^&*()-_+=<>?/[]{|}"

        let allCharacters = lowercaseLetters + uppercaseLetters + numbers + specialCharacters

        var password = ""

        password += String(lowercaseLetters.randomElement()!)

        password += String(uppercaseLetters.randomElement()!)

        password += String(numbers.randomElement()!)

        password += String(specialCharacters.randomElement()!)

        for _ in 4..<length {
            let randomIndex = Int.random(in: 0..<allCharacters.count)
            let randomCharacter = allCharacters[allCharacters.index(allCharacters.startIndex, offsetBy: randomIndex)]
            password += String(randomCharacter)
        }

        password = String(password.shuffled())

        return password
    }

}
