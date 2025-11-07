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
        case savePasswordSheet = "Save Password?"
        case notNowOption = "Not Now"
    }

    public enum ConversationsPage: String {

        case bottomBarRecentListButton
        case bottomBarSettingsButton
        case createGroupOrSearchButton
    }

    public enum SettingsPage: String {

        case accountCell
        case optionsCell
    }

    public enum AccountSettingsPage: String {

        case nameField
        case usernameField
        case emailField
        case domainFieldDisabled
        case backuporRestoreField = "Back up or RestoreField"
        case resetPasswordField = "Reset PasswordField"
        case deleteAccountField = "Delete AccountField"
        case logOut = "Log Out"

    }

    public enum ActiveConversationPage: String {

        case videoCallBarButton
        case inputField
        case sendButton
        case conversationBackButton
        case authorName
        case conversationTitleButton
        case conversationDetailsButton
    }

    public enum BackupOrRestorePage: String {

        case backUpNowButton
        case restoreFromBackupButton
        case browse = "Browse"
    }

    public enum CreatingBackupPage: String {

        case creatingBackupPageLabel
        case progressView
        case backupProgressFinished
        case exportBackupButton
    }

    public enum ConnectionRequestsPage: String {

        case connectRequestButton
        case ignoreRequestButton
        case username
    }

    public enum ConversationDetailsPage: String {

        case addParticipantsButton
        case moreOptionsButton
        case userCellName
        case close

    }

    public enum UserProfilePage: String {

        case name
        case qrCodeButton
        case teamName
        case username
        case createWireTeamButton
        case manageTeamButton
        case addAcccountOrTeamButton
    }

    public enum CreateGroupPage: String {

        case groupNameField
        case newGroupNextButton
    }
    
    public enum EmailUpdatePage: String {

        case emailField
        case newGroupNextButton
        case save
    }
    
    public enum LogOutPage: String {
        
        case ok
    }
    
    public enum NewConversationPage: String {
        
        case createNewGroupButton
        case searchByNameOrUsername
    }
    
    
}



