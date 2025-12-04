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

import Foundation
import Combine
import UIKit //only required for UIPasteboard

extension ShareLinkPasswordView {
    @MainActor
    final class ViewModel: ObservableObject {
        let existingPassword: String?
        
        @Published var isPasswordEnabled: Bool
        @Published var passwordInput = ""
        @Published var isPasswordInputSecured = true
        
        @Published var isPresentingRemovePasswordConfirmation = false
        @Published var isPresentingNoAccessToExistingPasswordConfirmation = false
        
        init(password: String?) {
            existingPassword = password
            isPasswordEnabled = password != nil
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
        
        func removePassword() {
            //TODO: ...
            // maybe the new figma design will make this obsolete
        }
        
        func generatePassword() {
            //TODO: ...
            // There should be a random password generator somewhere in the code base that we could repurpose for this feature.
            passwordInput = "TODO: randomly generated password"
        }
        
        func changePassword() {
            //TODO: ...
            // maybe the new figma design will make this obsolete
        }
        
        func copyPasswordToPasteboard() {
            // maybe the new figma design will make this obsolete
            UIPasteboard().string = passwordInput
        }
    }
}
