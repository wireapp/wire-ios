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

@MainActor
final class ShareLinkViewModel: ObservableObject {
    private let fileItem: FilesViewItem
    
    enum SheetNavigation: String, Identifiable {
        case password
        case expiration
        
        var id: String { rawValue }
    }
    
    @Published var sheetNavigation: SheetNavigation?
    
    /// The password that reflects the backend state.
    @Published var existingPassword: String? = nil
    
    @Published var pendingChangePassword: String?

    /// The password entered in the text field.
    @Published var passwordInput = ""
    
    @Published var isPasswordEnabled: Bool = false
    
    /// `true` if the password is obscured by showing only dots instead of the entered characters.
    @Published var isPasswordInputSecured = true
    
    @Published var isPresentingRemovePasswordConfirmation = false
    @Published var isPresentingNoAccessToExistingPasswordConfirmation = false
    
    init(fileItem: FilesViewItem) {
        self.fileItem = fileItem
    }
    
    /// The combined state of the password from the text field and the password-enabled toggle.
    var currentPassword: String? {
        isPasswordEnabled ? passwordInput : nil
    }
    
    var hasPasswordChanges: Bool {
        existingPassword != currentPassword
    }
    
    var isCurrentPasswordValid: Bool {
        guard let currentPassword else { return false }
        return !currentPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSavePassword: Bool {
        if isPasswordEnabled {
            hasPasswordChanges && isCurrentPasswordValid
        } else {
            hasPasswordChanges
        }
    }
    
    var canSaveSharedLink: Bool {
        existingPassword != pendingChangePassword
    }
    
    func removePassword() {
        //TODO: ...
    }
    
    func generatePassword() {
        //TODO: ...
        passwordInput = "TODO: randomly generated password"
    }
    
    func changePassword() {
        //TODO: ...
    }
    
    func copyPasswordToPasteboard() {
        UIPasteboard().string = passwordInput
    }
}
