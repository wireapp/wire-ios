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

import Combine
import Foundation
import WireMessagingDomain
import UIKit // only required for UIPasteboard

extension ShareLinkPasswordView {
    @MainActor
    final class ViewModel: ObservableObject {
        let existingPassword: String?
        
        struct UseCases {
            let updatePublicLinkPassword: WireCellsUpdatePublicLinkPasswordUseCase
            let storePublicLinkPasswordUseCase: WireCellsStorePublicLinkPasswordUseCase
            let deletePublicLinkPasswordUseCase: WireCellsDeletePublicLinkPasswordUseCase
        }

        @Published var isPasswordEnabled: Bool
        @Published var passwordInput = ""
        @Published var isPasswordInputSecured = true
        @Published var isPresentingNoAccessToExistingPasswordConfirmation = false
        @Published var alert: AlertModel?
        
        private let linkID: String?
        private let requiresPassword: Bool
        private let didSave: (Bool) -> Void
        private let useCases: UseCases

        init(
            password: String?,
            requiresPassword: Bool,
            linkID: String?,
            useCases: UseCases,
            didSave: @escaping (Bool) -> Void
        ) {
            self.linkID = linkID
            self.existingPassword = password
            self.requiresPassword = requiresPassword
            self.passwordInput = password ?? ""
            self.isPasswordEnabled = password != nil
            self.useCases = useCases
            self.didSave = didSave
            
//            if requiresPassword && password == nil {
//                alert = .init(title: <#T##String#>, message: <#T##String#>)
//            }
        }

        var currentPassword: String? {
            isPasswordEnabled ? passwordInput : nil
        }

        var hasChanges: Bool {
            existingPassword != currentPassword
        }

        var isCurrentPasswordValid: Bool {
            guard let currentPassword else { return false }
            return !currentPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var canSave: Bool {
            if isPasswordEnabled {
                hasChanges && isCurrentPasswordValid
            } else {
                hasChanges
            }
        }
        
        func save() async {
            guard let linkID else { return }
            
            do {
                let result = try await useCases.updatePublicLinkPassword.invoke(
                    linkID: linkID,
                    password: isPasswordEnabled ? passwordInput : nil
                )
                
                if result.requiresPassword {
                    try await useCases.storePublicLinkPasswordUseCase.invoke(
                        linkID: linkID,
                        password: passwordInput
                    )
                } else {
                    try await useCases.deletePublicLinkPasswordUseCase.invoke(
                        linkID: linkID
                    )
                }
                
                didSave(result.requiresPassword)
            } catch {
                print("HERE: \(String(describing: error))")
            }
        }

        func removePassword() {
            // TODO: ...
            // maybe the new figma design will make this obsolete
        }

        func generatePassword() {
            passwordInput = generateRandomPassword()
        }
        
        private func generateRandomPassword() -> String {
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

        func resetPassword() {
            passwordInput = ""
        }

        func copyPasswordToPasteboard() {
            UIPasteboard.general.string = passwordInput
        }
    }
}
