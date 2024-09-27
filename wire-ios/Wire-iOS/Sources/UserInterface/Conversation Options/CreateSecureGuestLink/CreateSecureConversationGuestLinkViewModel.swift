//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireSyncEngine

// MARK: - CreatePasswordSecuredLinkViewModelDelegate

// sourcery: AutoMockable
protocol CreatePasswordSecuredLinkViewModelDelegate: AnyObject {
    func viewModel(_ viewModel: CreateSecureConversationGuestLinkViewModel, didGeneratePassword password: String)
    func viewModelDidValidatePasswordSuccessfully(_ viewModel: CreateSecureConversationGuestLinkViewModel)
    func viewModel(
        _ viewModel: CreateSecureConversationGuestLinkViewModel,
        didFailToValidatePasswordWithReason reason: String
    )
    func viewModel(_ viewModel: CreateSecureConversationGuestLinkViewModel, didCreateLink link: String)
    func viewModel(_ viewModel: CreateSecureConversationGuestLinkViewModel, didFailToCreateLinkWithError error: Error)
}

// MARK: - CreateSecureConversationGuestLinkViewModel

final class CreateSecureConversationGuestLinkViewModel {
    // MARK: Lifecycle

    // MARK: - Init

    init(
        delegate: CreatePasswordSecuredLinkViewModelDelegate?,
        conversationGuestLinkUseCase: CreateConversationGuestLinkUseCaseProtocol
    ) {
        self.delegate = delegate
        self.conversationGuestLinkUseCase = conversationGuestLinkUseCase
    }

    // MARK: Internal

    enum UserInfoKeys {
        static let link = "link"
    }

    enum LinkCreationError: Error {
        case underfinedLink
    }

    // MARK: - Properties

    weak var delegate: CreatePasswordSecuredLinkViewModelDelegate?

    // MARK: - Methods

    func requestRandomPassword() {
        let randomPassword = generateRandomPassword()
        delegate?.viewModel(self, didGeneratePassword: randomPassword)
    }

    func validatePassword(
        for textField: ValidatedTextField,
        against confirmPasswordField: ValidatedTextField
    ) -> Bool {
        guard let enteredPassword = textField.text,
              !enteredPassword.isEmpty,
              textField.isValid,
              confirmPasswordField.text == enteredPassword else {
            return false
        }

        return true
    }

    func createSecuredGuestLinkIfValid(
        conversation: ZMConversation,
        passwordField: ValidatedTextField,
        confirmPasswordField: ValidatedTextField
    ) {
        guard validatePassword(for: passwordField, against: confirmPasswordField) else {
            delegate?.viewModel(self, didFailToValidatePasswordWithReason: "Password validation failed.")
            return
        }

        guard let password = passwordField.text else {
            return
        }

        UIPasteboard.general.string = password

        conversationGuestLinkUseCase.invoke(conversation: conversation, password: password) { [weak self] result in
            guard let self else { return }

            switch result {
            case let .success(link?):
                delegate?.viewModel(self, didCreateLink: link)
                NotificationCenter.default.post(
                    name: ConversationGuestLink.didCreateSecureGuestLinkNotification,
                    object: nil,
                    userInfo: [UserInfoKeys.link: link]
                )

            case .success(nil):
                delegate?.viewModel(self, didFailToCreateLinkWithError: LinkCreationError.underfinedLink)

            case let .failure(error):
                delegate?.viewModel(self, didFailToCreateLinkWithError: error)
            }
        }

        delegate?.viewModelDidValidatePasswordSuccessfully(self)
    }

    func generateRandomPassword() -> String {
        let minLength = 15
        let maxLength = 20
        let selectedLength = Int.random(in: minLength ... maxLength)

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

        for _ in 0 ..< (selectedLength - characters.count) {
            characters.append(allCharacters.randomElement()!)
        }

        return String(characters.shuffled())
    }

    // MARK: Private

    private let conversationGuestLinkUseCase: CreateConversationGuestLinkUseCaseProtocol
}
