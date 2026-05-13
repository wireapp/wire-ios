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

// MARK: - CreateSecureGuestLinkViewModel

final class CreateSecureConversationGuestLinkViewModel {

    enum UserInfoKeys {
        static let link = "link"
    }

    enum LinkCreationError: Error {
        case undefinedLink
    }

    struct State: Equatable {
        var password = ""
        var confirmPassword = ""
        var isPasswordValid = false
        var isLoading = false
        var hasValidationError = false

        var canCreateLink: Bool {
            !password.isEmpty
                && !confirmPassword.isEmpty
                && isPasswordValid
                && password == confirmPassword
                && !isLoading
        }
    }

    enum Action {
        case generatePassword
        case passwordChanged(String, isValid: Bool)
        case confirmPasswordChanged(String)
        case createLink(ZMConversation)
    }

    enum Route {
        case displayGeneratedPassword(String)
        case copyPasswordAndDismiss(String)
        case didCreateLink(String)
        case showError(Error)
    }

    // MARK: - Properties

    weak var delegate: CreatePasswordSecuredLinkViewModelDelegate?
    private(set) var state = State() {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((Route) -> Void)?

    private let conversationGuestLinkUseCase: CreateConversationGuestLinkUseCaseProtocol

    // MARK: - Init

    init(
        delegate: CreatePasswordSecuredLinkViewModelDelegate?,
        conversationGuestLinkUseCase: CreateConversationGuestLinkUseCaseProtocol
    ) {
        self.delegate = delegate
        self.conversationGuestLinkUseCase = conversationGuestLinkUseCase
    }

    // MARK: - Methods

    func send(_ action: Action) {
        switch action {
        case .generatePassword:
            requestRandomPassword()

        case let .passwordChanged(password, isValid):
            state.password = password
            state.isPasswordValid = isValid
            clearValidationErrorIfPasswordChanged()

        case let .confirmPasswordChanged(confirmPassword):
            state.confirmPassword = confirmPassword
            clearValidationErrorIfPasswordChanged()

        case let .createLink(conversation):
            createSecuredGuestLinkIfValid(conversation: conversation)
        }
    }

    func requestRandomPassword() {
        let randomPassword = generateRandomPassword()
        state.password = randomPassword
        state.confirmPassword = randomPassword
        state.isPasswordValid = true
        state.hasValidationError = false
        onRoute?(.displayGeneratedPassword(randomPassword))
        delegate?.viewModel(self, didGeneratePassword: randomPassword)
    }

    func validatePassword(
        password: String?,
        confirmPassword: String?,
        isPasswordValid: Bool
    ) -> Bool {

        guard let enteredPassword = password,
              !enteredPassword.isEmpty,
              isPasswordValid,
              confirmPassword == enteredPassword else {
            return false
        }

        return true
    }

    func createSecuredGuestLinkIfValid(conversation: ZMConversation) {
        guard validatePassword(
            password: state.password,
            confirmPassword: state.confirmPassword,
            isPasswordValid: state.isPasswordValid
        ) else {
            state.hasValidationError = true
            delegate?.viewModel(self, didFailToValidatePasswordWithReason: "Password validation failed.")
            return
        }

        let password = state.password
        state.isLoading = true
        state.hasValidationError = false

        conversationGuestLinkUseCase.invoke(conversation: conversation, password: password) { [weak self] result in
            guard let self else { return }

            DispatchQueue.main.async {
                self.handleLinkCreationResult(result, password: password)
            }
        }
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

    private func clearValidationErrorIfPasswordChanged() {
        guard state.hasValidationError else { return }
        state.hasValidationError = false
    }

    private func handleLinkCreationResult(
        _ result: Result<String?, CreateConversationGuestLinkUseCaseError>,
        password: String
    ) {
        state.isLoading = false

        switch result {
        case let .success(link?):
            onRoute?(.didCreateLink(link))
            onRoute?(.copyPasswordAndDismiss(password))
            delegate?.viewModel(self, didCreateLink: link)

        case .success(nil):
            let error = LinkCreationError.undefinedLink
            onRoute?(.showError(error))
            delegate?.viewModel(self, didFailToCreateLinkWithError: error)

        case let .failure(error):
            onRoute?(.showError(error))
            delegate?.viewModel(self, didFailToCreateLinkWithError: error)
        }
    }

}
