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

public enum Locators {

    public enum WelcomePage: String {

        case emailTextField
        case nextButton
        case onPremInfoButton
    }

    public enum LoginPage: String {

        case emailTextField
        case passwordSecureTextField
        case nextButton
        case createAccountLink
    }

    public enum FirstTimePage: String {

        case okButton
    }

    public enum ConversationsPage: String {

        case bottomBarRecentListButton
        case bottomBarSettingsButton
    }

    public enum SettingsPage: String {

        case accountCell
        case optionsCell
    }

    public enum AccountSettingsPage: String {

        case NameField
        case UsernameField
        case EmailField
        case DomainFieldDisabled
        case BackuporRestoreField = "Back up or RestoreField"
        case ResetPasswordField = "Reset PasswordField"
        case DeleteAccountField = "Delete AccountField"
        case LogOut = "Log Out"

    }

    public enum ActiveConversationPage: String {

        case videoCallBarButton
        case inputField
        case sendButton
        case ConversationBackButton
        case authorName
        case conversationTitleButton
        case conversationDetailsButton
    }

}
