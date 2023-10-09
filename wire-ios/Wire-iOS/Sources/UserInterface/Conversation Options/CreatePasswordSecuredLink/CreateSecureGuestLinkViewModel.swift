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

// MARK: - CreatePasswordSecuredLinkViewModelDelegate

// sourcery: AutoMockable
protocol CreatePasswordSecuredLinkViewModelDelegate: AnyObject {
    func generateButtonDidTap(_ password: String)
}

// MARK: - CreatePasswordSecuredLinkViewModel

final class CreateSecureGuestLinkViewModel {

    // MARK: - Properties

    weak var delegate: CreatePasswordSecuredLinkViewModelDelegate?

    // MARK: - Methods

    func requestRandomPassword() {
        let randomPassword = generateRandomPassword()
        delegate?.generateButtonDidTap(randomPassword)
    }

    func generateRandomPassword() -> String {
        let length = 8
        let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
        let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let specialCharacters = "!@#$%^&*()-_+=<>?/[]{|}"
        let allCharacters = lowercaseLetters + uppercaseLetters + numbers + specialCharacters

        var characters = [Character]()
        characters.append(lowercaseLetters.randomElement()!)
        characters.append(uppercaseLetters.randomElement()!)
        characters.append(numbers.randomElement()!)
        characters.append(specialCharacters.randomElement()!)

        for _ in 0..<(length - characters.count) {
            characters.append(allCharacters.randomElement()!)
        }

        return String(characters.shuffled())
    }

}
