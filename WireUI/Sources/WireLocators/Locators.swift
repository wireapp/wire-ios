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

// NOTE:
// Several identifiers in this file use explicit string values (e.g., UI labels or titles)
// because the current UI tests depend on these exact values.
// We are keeping them as-is for now to avoid breaking existing tests.
//
// TODO: [WPB-21952] Replace these explicit string values with properly camel-cased,
// non-UI-text-based identifiers (e.g., accessibility identifiers) to have this
// unform format and reduce test fragility.

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

    public enum LogOutPage: String {

        case ok = "OK"
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
        case conversationCell
        case blockOptionOnContextMenu = "Block…"
        case blockButtonOnBottomSheet
    }

    public enum SettingsPage: String {

        case accountCell
        case optionsCell
    }

    public enum AccountSettingsPage: String {

        // TODO: [WPB-21952] Improve these identifiers later.
        // We are keeping the current title+field identifiers for now to avoid
        // changing existing references across the app.
        case nameField = "NameField"
        case usernameField = "UsernameField"
        case emailField = "EmailField"
        case domainFieldDisabled = "DomainFieldDisabled"
        case backuporRestoreField = "Back up or RestoreField"
        case resetPasswordField = "Reset Password"
        case deleteAccountField = "Delete AccountField"
        case logOut = "Log Out"
        case ok = "OK"

    }

    public enum ActiveConversationPage: String {

        case videoCallBarButton
        case inputField
        case sendButton
        case conversationBackButton
        case authorName
        case conversationTitleButton
        case conversationDetailsButton
        case message
        case imageCell = "ImageCell"
    }

    public enum BackupOrRestorePage: String {

        case backUpNow
        case restoreFromBackupButton
        case browse = "Browse"
    }

    public enum CreatingBackupPage: String {

        case creatingBackupPageLabel
        case progressView
        case backupCreatedLabel
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
        case addAccountOrTeamButton
    }

    public enum CreateGroupPage: String {

        case groupNameField
        case newGroupNextButton
    }

    public enum CreatePersonalAccountFormPage: String {

        case enterNameField
        case enterPasswordField
        case enterConfirmPasswordField
        case continueButton
        case acceptTermsOfUse = "Accept"
    }

    public enum EmailUpdatePage: String {

        case emailField
        case newGroupNextButton
        case save
    }

    public enum NewConversationPage: String {

        case createNewGroupButton
        case searchByNameOrUsername = "Search by name or username"
        case cancelUserSearch = "Cancel"
        case cancel
        case usernameCell
    }

    public enum OnMyiPhonePage: String {

        case onMyiPhoneLabel = "On My iPhone"
        case save = "Save"
        case search = "Search"

    }

    public enum OptionsOnSettingsPage: String {

        case lockWithPasscode = "Lock With Passcode"
    }

    public enum SaveBackupFileBottomSheetPage: String {

        case saveToFiles = "Save to Files"
    }

    public enum SelectParticipantsPage: String {

        case done
        case skip
        case searchByNameOrUsername
    }

    public enum SetCustomBackendPage: String {

        case proceedButton = "Proceed"
    }

    public enum SetPasscodePage: String {

        case passcodeField
        case createPasscodeButton

    }

    public enum SetPasswordPage: String {

        case passwordInputField
        case backUpNowButton
        case historyRestoredAlert = "Your history is restored."
        case continueButton = "Continue"
        case ok = "OK"

    }

    public enum SetUsernamePage: String {

        case usernameTextField
        case confirmUsernameButton
    }

    public enum TeamSetupStepsPage: String {

        case checkbox
        case confirmUsernameButton
        case teamNameTextField
        case continueButton
        case backToWireButton
    }

    public enum UserDetailsPage: String {

        case close
        case connectLeftButton
        case moreOptionRightButton
        case removeUserFromConversationConfirmation
        case removeFromConversation = "Remove From Conversation…"
    }

    public enum VerificationCodePage: String {

        case verificationCodeTextField
        case confirmButton
    }

    public enum VerifyEmailPage: String {

        case verifyEmailPageLabel = "Verify email"
    }

    public enum WebViewPage: String {

        case resetPassword = "Reset password"
    }

    public enum FileVersioningPage: String {

        case closeButton
    }

    public enum ShareExtensionPage: String {

        case imageTile = "PXGGridLayout-Info"
        case shareButton = "PUOneUpBarButtonItemIdentifierShare"
        case chooseConversations = "chevron"
        case sendButtonOnShareExtension
        case continueButton = "Continue"
    }

}
