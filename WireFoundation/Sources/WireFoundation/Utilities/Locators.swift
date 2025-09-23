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

    public enum Buttons {
        public static let next = "Next"
        public static let createAccount = "Create account"
        public static let ok = "OK"
        public static let conversationsNavBar = "bottomBarRecentListButton"
        public static let settings = "Settings"
        public static let videoCallIcon = "videoCallBarButton"
        public static let sendMessage = "sendButton"
        public static let backToConversation = "ConversationBackButton"
        public static let conversationHeader = "conversation_title_button"
        public static let conversationDetails = "Conversation Details"
        public static let backupNow = "Back Up Now"
        public static let restore = "Restore from Backup"
        public static let account = "Account"
        public static let browse = "Browse"
        public static let accept = "accept"
        public static let addParticipants = "OtherUserMetaControllerLeftButton"
        public static let closeDetails = "close"
        public static let settingsNavBar = "bottomBarSettingsButton"
        public static let plusIcon = "create_group_or_search_button"
        public static let conversationTitle = "title"
        public static let blockOption = "Block…"
        public static let blockOnBottomSheet = "Block"
        public static let confirm = "ConfirmButton"
        public static let acceptPopup = "Accept"
        public static let nextOnTopRight = "button.newgroup.next"
        public static let eyeIcon = "eye.slash"
        public static let continueButton = "Continue"
        public static let export = "exportButton"
        public static let newGroup = "New group"
        public static let saveFile = "Save"
        public static let moreOptions = "More"
        public static let sortByDate = "Date"
        public static let addParticipantsOnSelectParticipants = "Add Participants"
        public static let done = "button.addpeople.create"
        public static let backupNowOnPassword = "back up now"
        public static let checkbox = "square"
        public static let backToWire = "Back To Wire"
        public static let qrCode = "QR code button"
        public static let createWireTeam = "Create Wire Team"
        public static let addAnotherAccount = "Add Account or TeamField"
        public static let moreAction = "right_button"
        public static let removeFromConversations = "Remove From Conversation…"
        public static let confirmRemoveFromConversations = "Remove From Conversation"
        public static let confirmOnVerificationCode = "Confirm"
    }

    public enum TextFields {
        public static let emailField = "Email or SSO code"
        public static let enterEmail = "Enter email"
        public static let usernameField = "UsernameField"
        public static let nameFieldValue = "NameField"
        public static let groupNameField = "NameField"
        public static let nameTextField = "Enter your name"
        public static let passwordTextField = "Enter a password"
        public static let confirmPasswordTextField = "Confirm password"
        public static let searchBox = "Search by name or username"
        public static let cancelOnSearchUserPage = "Cancel"
        public static let cancelOnNewConversationPage = "cancel"
        public static let searchParticipantBox = "textViewSearch"
        public static let teamNameField = "Your Team"
        public static let verificationCodeInput = "VerificationCode"
    }

    public enum TextViews {
        public static let messageInput = "inputField"
        public static let message = "Message"
        public static let sender = "author.name"
    }

    public enum Alerts {
        public static let historyRestored = "Your history is restored."
    }

    public enum StaticTexts {
        public static let logout = "Log Out"
        public static let emailFieldValue = "EmailField"
        public static let usernameFieldValue = "UsernameField"
        public static let backUpOrRestore = "Back up or RestoreField"
        public static let deleteAccount = "Delete Account"
        public static let name = "name"
        public static let username = "username"
        public static let userCell = "user_cell.name"
        public static let conversations = "Conversations"
        public static let creatingBackup = "Creating Backup"
        public static let backupSuccessfullyCreated = "Backup successfully created."
        public static let progressView = "progressView"
        public static let onMyiPhone = "On My iPhone"
        public static let teamName = "team name"
        public static let manageTeam = "Manage Team"
        public static let connectUser = "Connect"

    }

    public enum SecureTextFields {
        public static let enterPassword = "Enter password"
        public static let passwordInputBox = "password input"
    }

    public enum Cells {
        public static let account = "Account"
        public static let userCell = "user_cell.username"
        public static let saveToFiles = "Save to Files"
    }
}
