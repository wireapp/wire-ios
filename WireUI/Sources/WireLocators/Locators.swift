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

// NOTE:
// Several identifiers in this file use explicit string values (e.g., UI labels or titles)
// because the current UI tests depend on these exact values.
// We are keeping them as-is for now to avoid breaking existing tests.
//
// TODO: [WPB-21952] Replace these explicit string values with properly camelCased,
// non-UI-text-based identifiers (e.g., accessibility identifiers) to have this
// unform format and reduce test fragility.

public enum Locators {

    public enum WelcomePage: AutoPrefixedEnum {

        case emailTextField
        case nextButton
        case onPremInfoButton
    }

    public enum LoginPage: AutoPrefixedEnum {

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
        case bottomBarDriveButton
        case createGroupOrSearchButton
        case conversationSearchBar
        case conversationSearchClearButton = "Clear text"
        case conversationCell
        case blockOptionOnContextMenu = "Block…"
        case clearOptionOnContextMenu = "Clear Content…"
        case clearButtonOnBottomSheet
        case leaveButtonOnBottomSheet
        case leaveAndClearButtonOnBottomSheet
        case blockButtonOnBottomSheet
        case bottomBarArchivedButton
        case accountProfileImageView
        case status
        case loadBar
        case addToFavourite = "Add to Favorites"
        case removeFromFavourite = "Remove from Favorites"
        case moveToFolderOptionOnContextMenu = "Move to…"
        case filterConversations = "Filter conversations"
        case filterByFavourites
        case filterByGroups
        case filterByChannels
        case filterByOneOnOneConversation
        case filterByFolders
        case textFilteredByFavourites
        case textFilteredByGroups
        case textFilteredByChannels
        case textFilteredByOneOnOne
        case userRemovedSystemMessage
        case connectionRequestsCell
        case unreadMessageCount
        case useLeftSystemMessage
    }

    public enum SettingsPage: AutoPrefixedEnum {

        case accountCell
        case optionsCell
        case shareDebugBanner
    }

    public enum ShareDebugReportPage: String {

        case actionSheet = "Having trouble?"
        case shareViaWireButton = "ShareDebugReportPage.shareViaWireButton"
        case sendEmailButton = "ShareDebugReportPage.sendEmailButton"
        case shareButton = "ShareDebugReportPage.shareButton"
        case cancelButton = "ShareDebugReportPage.cancelButton"
    }

    public enum ShareViaWirePage: AutoPrefixedEnum {

        case sendButton
        case closeButton
    }

    public enum ActivitySheetPage: String {

        case sheet = "ActivityListView"
        case saveToFiles = "Save to Files"
    }

    public enum AccountSettingsPage: String {

        // TODO: [WPB-21952] Improve these identifiers later.
        // We are keeping the current title+field identifiers for now to avoid
        // changing existing references across the app.
        case accountHeader = "Account"
        case pictureCell
        case profilePictureImagePreview
        case colorCell
        case conversationBackgroundSwitch = "ConversationBackgroundSwitch"
        case nameField = "NameField"
        case nameFieldDisabled = "NameFieldDisabled"
        case usernameField = "UsernameField"
        case usernameFieldDisabled = "UsernameFieldDisabled"
        case emailField = "EmailField"
        case emailFieldDisabled = "EmailFieldDisabled"
        case domainFieldDisabled = "DomainFieldDisabled"
        case backuporRestoreField = "Back up or RestoreField"
        case resetPasswordField = "Reset Password"
        case deleteAccountField = "Delete AccountField"
        case logOut = "Log Out"
        case ok = "OK"

    }

    public enum ThemeSettingsPage: AutoPrefixedEnum {

        case lightOption
        case darkOption
        case systemOption
    }

    public enum DeviceDetailsPage: String {

        case removeDeviceButton
        case verifiedSwitch
        case ok = "OK"
    }

    public enum DevicesPage: String {

        case deviceNameLabel = "device name"
        case title = "Devices"
    }

    public enum ActiveConversationPage: String {

        case videoCallBarButton
        case inputField
        case sendButton
        case authorName
        case conversationTitleButton
        case conversationDetailsButton
        case sharedDriveButton
        case ephemeralTimeSelectionButton
        case message
        case linkPreviewCell
        case imageCell
        case videoCell
        case videoPlayButton
        case mentionButton
        case userCellName
        case labelSharedDriveON = "Shared Drive is on"
        case labelSelfDeletingMessagesOFF = "Self-deleting messages are off"
        case sharedFileLabel = "FileTransferTopLabel"
        case sharedFileDetailsLabel = "FileTransferBottomLabel"
        case fileTypeIcon = "FileTransferFileTypeIcon"
        case sketchButton
        case canvas
        case canvasSendButton
        case canvasConfirmButton
        case attachmentImagePreview
        case attachmentVideoPreview
        case classifiedBanner = "ClassificationBannerClassified"
        case photoButton
        case uploadFileButton
        case browse = "Browse"
        case open = "Open"
        case allowFullAccess = "Allow Full Access"
        case ok = "OK"
        case audioButton
        case startRecording
        case stopRecording
        case helium = "Helium"
        case sendAudio
        case playAudioFile
        case recordingTime
        case showOtherRowButton
        case pingButton
        case guestsArePresent = "Guests are present"
        case conversationBackground
        case openOngoingCallButton
        case readReceiptsDisabledSystemMessage
        case readReceiptsEnabledSystemMessage

    }

    public enum BackupOrRestorePage: String {

        case backUpNow
        case restoreFromBackupButton
        case browse = "Browse"
        case historyRestoredAlert = "Your history is restored."
    }

    public enum CreatingBackupPage: AutoPrefixedEnum {

        case creatingBackupPageLabel
        case progressView
        case backupCreatedLabel
        case exportBackupButton
    }

    public enum ConnectionRequestsPage: AutoPrefixedEnum {

        case connectRequestButton
        case ignoreRequestButton
        case username
    }

    public enum ConversationDetailsPage: AutoPrefixedEnum {
        case title
        case addParticipantsButton
        case moreOptionsButton
        case userCellName
        case adminCell
        case memberCell
        case close
        case readReceiptsSwitch
    }

    public enum ConversationDetailsActions: AutoPrefixedEnum {
        case archive
        case clearContent
        case leaveConversation
        case moveToFolder
    }

    public enum LastAdminLeaveAlert: AutoPrefixedEnum {
        case promoteNewAdmin
        case deleteGroup
    }

    public enum AdminSelectionPage: AutoPrefixedEnum {
        case promoteButton
        case userCell
    }

    public enum UserProfilePage: AutoPrefixedEnum {

        case name
        case qrCodeButton
        case teamName
        case username
        case createWireTeamButton
        case manageTeamButton
        case addAccountOrTeamButton
        case userProfilePicture
        case close
        case status
    }

    public enum UserProfileStatusPicker: String {
        case none
        case available
        case busy
        case away
        case okButton = "OK"
    }

    public enum CreateGroupPage: AutoPrefixedEnum {

        case groupNameField
        case newGroupNextButton
        case sharedDriveSwitch
    }

    public enum CreateChannelPage: String {

        case channelNameField
        case newChannelNextButton
        case sharedDriveSwitch
    }

    public enum CreatePersonalAccountFormPage: String {

        case enterNameField
        case enterPasswordField
        case enterConfirmPasswordField
        case continueButton
        case acceptTermsOfUse = "Accept"
    }

    public enum EmailUpdatePage: AutoPrefixedEnum {

        case emailField
        case newGroupNextButton
        case save
    }

    public enum UsernameUpdatePage: String {

        case usernameField
        case save = "Save"
        case username = "Username"
        case handleTextField
    }

    public enum NewConversationPage: String {

        case createNewGroupButton
        case searchByNameOrUsername = "Search by name or username"
        case cancelUserSearch = "Cancel"
        case cancel
        case usernameCell
        case createNewChannelButton
        case userCellInContactList
    }

    public enum OnMyiPhonePage: String {

        case onMyiPhoneLabel = "On My iPhone"
        case save = "Save"
        case search = "Search"

    }

    public enum FilesAppPage: String {

        case browse = "Browse"
        case done = "Done"
        case onMyIPhone = "On My iPhone"
        case search = "Search"
        case share = "Share"
        case nameContains = "Name Contains"
        case moreOptions = "OverflowBarButtonItem"
        case select = "Select"
    }

    public enum OptionsOnSettingsPage: String {

        case theme = "Theme"
        case themeCell
        case lockWithPasscode = "Lock With Passcode"
        case createLinkPreviews = "Create Link Previews"
    }

    public enum SaveBackupFileBottomSheetPage: String {

        case saveToFiles = "Save to Files"
    }

    public enum SelectParticipantsPage: AutoPrefixedEnum {

        case done
        case skip
        case searchByNameOrUsername
    }

    public enum SetCustomBackendPage: String {

        case proceedButton = "Proceed"
    }

    public enum SetPasscodePage: AutoPrefixedEnum {

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

    public enum SetUsernamePage: AutoPrefixedEnum {

        case usernameTextField
        case confirmUsernameButton
    }

    public enum ManageDevicesPage: String {

        case manageDevices
        case removeDevice = "minus.circle.fill"
        case deleteDevice = "Delete"
        case ok = "OK"
    }

    public enum TeamSetupStepsPage: AutoPrefixedEnum {

        case checkbox
        case confirmUsernameButton
        case teamNameTextField
        case continueButton
        case backToWireButton
    }

    public enum UserDetailsPage: String {

        case connectLeftButton
        case moreOptionRightButton
        case removeUserFromConversationConfirmation
        case removeFromConversation = "Remove From Conversation…"
        case groupAdminToggle
        case close
    }

    public enum VerificationCodePage: AutoPrefixedEnum {

        case verificationCodeTextField
        case confirmButton
    }

    public enum VerifyEmailPage: String {

        case verifyEmailPageLabel = "Verify email"
    }

    public enum WebViewPage: String {

        case resetPassword = "Reset password"
    }

    public enum ShareExtensionPage: String {

        case sendButtonOnShareExtension
        case wire = "Wire"
        case chooseConversations = "Choose"
    }

    public enum PhotosAppPage: String {

        case select = "Select"
        case imageTile = "PXGGridLayout-Info"
        case shareButton = "Share"
        case continueButton = "Continue"

    }

    public enum IncomingCallPage: String {

        case acceptCall = "Accept"
        case turnOffMicrophone = "Microphone"
    }

    public enum FileVersioningPage: AutoPrefixedEnum {

        case closeButton
    }

    public enum OngoingCallPage: String {

        case cameraButton = "CallVideoButton"
        case endOngoingCallButton = "EndCallButton"
        case microphoneButton = "CallMuteButton"
        case speakerButton = "CallSpeakerButton"
        case timeLabel
        case minimizeCall
        case sharesScreenDescription = "Shares screen"

        public static func participantIdentifier(_ name: String) -> String {
            "audioView.\(name).minimized.inactive"
        }
    }

    public enum SecurityLevelView: String {

        case classificationBanner = "ClassificationBanner"

    }

    public enum WireDrive {

        public enum FilesFilterPage: String {
            case saveButton
            case cancelButton
            case removeFilterButton
        }

        public enum FilesFilteringPage: String {
            case removeAllFiltersButton

            public static func filter(_ filter: String) -> String {
                "filter.\(filter)"
            }
        }

        public enum ShareLinkPasswordPage: String {
            case togglePassword
            case sharePassword
            case resetPassword
            case savePassword
        }

        public enum ShareLinkPage: String {
            case sharePassword
            case shareLink
        }

        public enum FilesContentPage: String {
            case confirm
            case search

            public static func fileItem(_ index: Int) -> String {
                "fileItem\(index)"
            }
        }

        public enum FileMenu: String {
            case deleteToRecycleBin
            case deletePermanently
            case restore

            public var identifier: String {
                "fileMenu.\(rawValue)"
            }
        }

        public enum FilesPage: String {
            case close
            case createFolder
            case createFile
            case recycleBin
            case sharedDrivePageHeader = "Shared Drive"
            case deleteOnBottomSheet = "Delete"
            case moreOptions = "More"
            case recycleBinPageheader = "Recycle Bin"
        }

        public enum FilesInfoPage: String {
            case preparingFilesTitle
            case preparingFilesMessage
            case noFilesSearchTitle
            case noFilesSearchMessage
            case noFilesTitle
            case noFilesAllConversationsMessage
            case noFilesMessage
            case errorTitle
            case errorMessage
            case retryButton
            case loadMore
        }

        public enum EditFilePage: String {
            case close
        }

        /// UI elements for both file or folder creation.
        public enum CreateFilePage: String {
            case createFolderPageHeader = "Create folder"
            case cancelButton
            case createButton
        }

        public enum FileRenamePage: String {
            case cancel
            case save
        }

        public enum FileVersioningPage: AutoPrefixedEnum {

            case closeButton
            case restoreButton
        }

        public enum TagsEditPage: String {

            case closeButton
            case saveButton
            case textInputField

            public static func currentTag(_ tag: String) -> String {
                "currentTag.\(tag)"
            }

            public static func suggestedTag(_ tag: String) -> String {
                "suggestedTag.\(tag)"
            }
        }

        public enum FilesSortingPage: String {
            case menuButton

            public static func sortOrder(_ order: String) -> String {
                "sortOrder.\(order)"
            }

            public static func sortKey(_ key: String) -> String {
                "sortKey.\(key)"
            }
        }

        public enum FilesItemPage: String {
            case confirmDeleteButton
            case confirmRestoreButton
        }

        public enum RecycleBinPage: String {
            case deletePermanently = "Delete Permanently"
        }

        public enum ConversationDetailsSharedDriveOptionsPage: AutoPrefixedEnum {
            case toggleSectionTitle
            case toggle
            case toggleSectionFooter
            case participantsSectionHeader
            case participantsSectionFooterTitle
            case participantsSectionFooterSubtitle
            case participantName
            case participantHandle
            case participantRole
        }
    }

    public enum BlockerPage: String {

        case mainContent
        case clientObsoleteAlertTitle = "Update required"

    }

    public enum SSOWebLoginPage: String {
        case username = "Username"
        case signInButton = "Sign In"

    }

    public enum AlertActions: AutoPrefixedEnum {
        case confirm
    }

    public enum WireMeetings {

        public enum MeetingDetails: String {
            case attendingLabel = "Attending Label"
        }

    }
}
