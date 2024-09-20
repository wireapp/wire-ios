// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Accessibility {
    internal enum AboutSettings {
      internal enum BackButton {
        /// Go back to About
        internal static let description = L10n.tr("Accessibility", "aboutSettings.backButton.description", fallback: "Go back to About")
      }
    }
    internal enum AccountPage {
      internal enum AvailabilityStatus {
        /// Status
        internal static let description = L10n.tr("Accessibility", "accountPage.availabilityStatus.description", fallback: "Status")
        /// Double tap to change status
        internal static let hint = L10n.tr("Accessibility", "accountPage.availabilityStatus.hint", fallback: "Double tap to change status")
      }
      internal enum BackButton {
        /// Go back to account overview
        internal static let description = L10n.tr("Accessibility", "accountPage.backButton.description", fallback: "Go back to account overview")
      }
      internal enum CloseButton {
        /// Close account overview
        internal static let description = L10n.tr("Accessibility", "accountPage.closeButton.description", fallback: "Close account overview")
      }
      internal enum Handle {
        /// Username
        internal static let description = L10n.tr("Accessibility", "accountPage.handle.description", fallback: "Username")
      }
      internal enum Name {
        /// Profile name
        internal static let description = L10n.tr("Accessibility", "accountPage.name.description", fallback: "Profile name")
      }
      internal enum ProfilePicture {
        /// Profile picture
        internal static let description = L10n.tr("Accessibility", "accountPage.profilePicture.description", fallback: "Profile picture")
        /// Double tap to change your picture
        internal static let hint = L10n.tr("Accessibility", "accountPage.profilePicture.hint", fallback: "Double tap to change your picture")
      }
      internal enum TeamName {
        /// Team name
        internal static let description = L10n.tr("Accessibility", "accountPage.teamName.description", fallback: "Team name")
      }
    }
    internal enum AccountSettings {
      internal enum BackButton {
        /// Go back to Account
        internal static let description = L10n.tr("Accessibility", "accountSettings.backButton.description", fallback: "Go back to Account")
      }
    }
    internal enum AddParticipantsConversationSettings {
      internal enum CloseButton {
        /// Close add participants option
        internal static let description = L10n.tr("Accessibility", "addParticipantsConversationSettings.closeButton.description", fallback: "Close add participants option")
      }
    }
    internal enum AdvancedSettings {
      internal enum BackButton {
        /// Go back to Advanced
        internal static let description = L10n.tr("Accessibility", "advancedSettings.backButton.description", fallback: "Go back to Advanced")
      }
    }
    internal enum AudioMessage {
      internal enum Pause {
        /// Pause
        internal static let value = L10n.tr("Accessibility", "audioMessage.pause.value", fallback: "Pause")
      }
      internal enum Play {
        /// Play
        internal static let value = L10n.tr("Accessibility", "audioMessage.play.value", fallback: "Play")
      }
    }
    internal enum AudioRecord {
      internal enum AlienEffectButton {
        /// Alien
        internal static let description = L10n.tr("Accessibility", "audioRecord.alienEffectButton.description", fallback: "Alien")
      }
      internal enum CancelButton {
        /// Delete audio recording
        internal static let description = L10n.tr("Accessibility", "audioRecord.cancelButton.description", fallback: "Delete audio recording")
      }
      internal enum DeepVoiceEffectButton {
        /// Deep voice
        internal static let description = L10n.tr("Accessibility", "audioRecord.deepVoiceEffectButton.description", fallback: "Deep voice")
      }
      internal enum HallEffectButton {
        /// Hall effect
        internal static let description = L10n.tr("Accessibility", "audioRecord.hallEffectButton.description", fallback: "Hall effect")
      }
      internal enum HeliumEffectButton {
        /// Helium
        internal static let description = L10n.tr("Accessibility", "audioRecord.heliumEffectButton.description", fallback: "Helium")
      }
      internal enum HighToDeepEffectButton {
        /// High to deep
        internal static let description = L10n.tr("Accessibility", "audioRecord.highToDeepEffectButton.description", fallback: "High to deep")
      }
      internal enum NormalEffectButton {
        /// Normal
        internal static let description = L10n.tr("Accessibility", "audioRecord.normalEffectButton.description", fallback: "Normal")
      }
      internal enum QuickEffectButton {
        /// Quick
        internal static let description = L10n.tr("Accessibility", "audioRecord.quickEffectButton.description", fallback: "Quick")
      }
      internal enum RedoButton {
        /// Redo audio recording
        internal static let description = L10n.tr("Accessibility", "audioRecord.redoButton.description", fallback: "Redo audio recording")
      }
      internal enum RoboticEffectButton {
        /// Robotic
        internal static let description = L10n.tr("Accessibility", "audioRecord.roboticEffectButton.description", fallback: "Robotic")
      }
      internal enum SendButton {
        /// Send
        internal static let description = L10n.tr("Accessibility", "audioRecord.sendButton.description", fallback: "Send")
      }
      internal enum StartButton {
        /// Start recording
        internal static let description = L10n.tr("Accessibility", "audioRecord.startButton.description", fallback: "Start recording")
        /// Double tap to record
        internal static let hint = L10n.tr("Accessibility", "audioRecord.startButton.hint", fallback: "Double tap to record")
      }
      internal enum StopButton {
        /// Stop recording
        internal static let description = L10n.tr("Accessibility", "audioRecord.stopButton.description", fallback: "Stop recording")
      }
    }
    internal enum Authentication {
      internal enum BackButton {
        /// Go back to start screen
        internal static let description = L10n.tr("Accessibility", "authentication.backButton.description", fallback: "Go back to start screen")
      }
      internal enum ForgotPasswordButton {
        /// Change your password
        internal static let description = L10n.tr("Accessibility", "authentication.forgotPasswordButton.description", fallback: "Change your password")
      }
    }
    internal enum Calling {
      internal enum AcceptButton {
        /// Accept
        internal static let description = L10n.tr("Accessibility", "calling.acceptButton.description", fallback: "Accept")
      }
      internal enum ActiveSpeaker {
        /// Active speaker
        internal static let description = L10n.tr("Accessibility", "calling.activeSpeaker.description", fallback: "Active speaker")
      }
      internal enum CameraOff {
        /// Camera off
        internal static let description = L10n.tr("Accessibility", "calling.cameraOff.description", fallback: "Camera off")
      }
      internal enum CameraOn {
        /// Camera on
        internal static let description = L10n.tr("Accessibility", "calling.cameraOn.description", fallback: "Camera on")
      }
      internal enum FlipCameraBackButton {
        /// Flip to back camera
        internal static let description = L10n.tr("Accessibility", "calling.flipCameraBackButton.description", fallback: "Flip to back camera")
      }
      internal enum FlipCameraFrontButton {
        /// Flip to front camera
        internal static let description = L10n.tr("Accessibility", "calling.flipCameraFrontButton.description", fallback: "Flip to front camera")
      }
      internal enum HangUpButton {
        /// End call
        internal static let description = L10n.tr("Accessibility", "calling.hangUpButton.description", fallback: "End call")
      }
      internal enum HeaderBar {
        /// Minimize calling view
        internal static let description = L10n.tr("Accessibility", "calling.headerBar.description", fallback: "Minimize calling view")
      }
      internal enum MicrophoneOff {
        /// Microphone off
        internal static let description = L10n.tr("Accessibility", "calling.microphoneOff.description", fallback: "Microphone off")
      }
      internal enum MicrophoneOffButton {
        /// Turn off microphone
        internal static let description = L10n.tr("Accessibility", "calling.microphoneOffButton.description", fallback: "Turn off microphone")
      }
      internal enum MicrophoneOn {
        /// Microphone on
        internal static let description = L10n.tr("Accessibility", "calling.microphoneOn.description", fallback: "Microphone on")
      }
      internal enum MicrophoneOnButton {
        /// Turn on microphone
        internal static let description = L10n.tr("Accessibility", "calling.microphoneOnButton.description", fallback: "Turn on microphone")
      }
      internal enum SharesScreen {
        /// Shares screen
        internal static let description = L10n.tr("Accessibility", "calling.sharesScreen.description", fallback: "Shares screen")
      }
      internal enum SpeakerOffButton {
        /// Turn off speaker
        internal static let description = L10n.tr("Accessibility", "calling.speakerOffButton.description", fallback: "Turn off speaker")
      }
      internal enum SpeakerOnButton {
        /// Turn on speaker
        internal static let description = L10n.tr("Accessibility", "calling.speakerOnButton.description", fallback: "Turn on speaker")
      }
      internal enum Status {
        /// Connecting
        internal static let connecting = L10n.tr("Accessibility", "calling.status.connecting", fallback: "Connecting")
      }
      internal enum SwipeDownParticipants {
        /// Double tap to swipe down and hide participant’s details
        internal static let hint = L10n.tr("Accessibility", "calling.swipeDownParticipants.hint", fallback: "Double tap to swipe down and hide participant’s details")
      }
      internal enum SwipeUpParticipants {
        /// Double tap to swipe up and view all participant’s details
        internal static let hint = L10n.tr("Accessibility", "calling.swipeUpParticipants.hint", fallback: "Double tap to swipe up and view all participant’s details")
      }
      internal enum UserCellFullscreen {
        /// Quadruple tap for full screen
        internal static let hint = L10n.tr("Accessibility", "calling.userCellFullscreen.hint", fallback: "Quadruple tap for full screen")
      }
      internal enum UserCellMinimize {
        /// Quadruple tap to minimize view
        internal static let hint = L10n.tr("Accessibility", "calling.userCellMinimize.hint", fallback: "Quadruple tap to minimize view")
      }
      internal enum VideoOffButton {
        /// Turn off camera
        internal static let description = L10n.tr("Accessibility", "calling.videoOffButton.description", fallback: "Turn off camera")
      }
      internal enum VideoOnButton {
        /// Turn on camera
        internal static let description = L10n.tr("Accessibility", "calling.videoOnButton.description", fallback: "Turn on camera")
      }
    }
    internal enum ClientsList {
      internal enum BackButton {
        /// Go back to device list
        internal static let description = L10n.tr("Accessibility", "clientsList.backButton.description", fallback: "Go back to device list")
      }
      internal enum DeviceDetails {
        /// Double tap to open device details
        internal static let hint = L10n.tr("Accessibility", "clientsList.deviceDetails.hint", fallback: "Double tap to open device details")
      }
      internal enum DeviceId {
        /// Device ID
        internal static let description = L10n.tr("Accessibility", "clientsList.deviceId.description", fallback: "Device ID")
      }
      internal enum DeviceName {
        /// Device name
        internal static let description = L10n.tr("Accessibility", "clientsList.deviceName.description", fallback: "Device name")
      }
      internal enum DeviceNotVerified {
        /// Not Verified
        internal static let description = L10n.tr("Accessibility", "clientsList.deviceNotVerified.description", fallback: "Not Verified")
      }
      internal enum DeviceVerified {
        /// Verified
        internal static let description = L10n.tr("Accessibility", "clientsList.deviceVerified.description", fallback: "Verified")
      }
      internal enum KeyFingerprint {
        /// Key fingerprint
        internal static let description = L10n.tr("Accessibility", "clientsList.keyFingerprint.description", fallback: "Key fingerprint")
      }
    }
    internal enum Connection {
      internal enum ArchiveButton {
        /// Archive connection
        internal static let description = L10n.tr("Accessibility", "connection.archiveButton.description", fallback: "Archive connection")
      }
      internal enum CancelButton {
        /// Cancel connection
        internal static let description = L10n.tr("Accessibility", "connection.cancelButton.description", fallback: "Cancel connection")
      }
    }
    internal enum ContactsList {
      internal enum CloseButton {
        /// Close contact list
        internal static let description = L10n.tr("Accessibility", "contactsList.closeButton.description", fallback: "Close contact list")
      }
      internal enum ExternalIcon {
        /// External
        internal static let description = L10n.tr("Accessibility", "contactsList.externalIcon.description", fallback: "External")
      }
      internal enum FederatedIcon {
        /// Federated
        internal static let description = L10n.tr("Accessibility", "contactsList.federatedIcon.description", fallback: "Federated")
      }
      internal enum GuestIcon {
        /// Guest
        internal static let description = L10n.tr("Accessibility", "contactsList.guestIcon.description", fallback: "Guest")
      }
      internal enum MemberIcon {
        /// Member
        internal static let description = L10n.tr("Accessibility", "contactsList.memberIcon.description", fallback: "Member")
      }
      internal enum PendingConnection {
        /// Double tap to open profile
        internal static let hint = L10n.tr("Accessibility", "contactsList.pendingConnection.hint", fallback: "Double tap to open profile")
      }
      internal enum UserCell {
        /// Double tap to open conversation
        internal static let hint = L10n.tr("Accessibility", "contactsList.userCell.hint", fallback: "Double tap to open conversation")
      }
    }
    internal enum Conversation {
      internal enum AudioButton {
        /// Record an audio message
        internal static let description = L10n.tr("Accessibility", "conversation.audioButton.description", fallback: "Record an audio message")
      }
      internal enum BackButton {
        /// Go back to conversation list
        internal static let description = L10n.tr("Accessibility", "conversation.backButton.description", fallback: "Go back to conversation list")
      }
      internal enum BoldButton {
        /// Use bolded text
        internal static let description = L10n.tr("Accessibility", "conversation.boldButton.description", fallback: "Use bolded text")
      }
      internal enum BulletListButton {
        /// Use bullet list
        internal static let description = L10n.tr("Accessibility", "conversation.bulletListButton.description", fallback: "Use bullet list")
      }
      internal enum CameraButton {
        /// Take or select a photo
        internal static let description = L10n.tr("Accessibility", "conversation.cameraButton.description", fallback: "Take or select a photo")
      }
      internal enum CodeButton {
        /// Use code format
        internal static let description = L10n.tr("Accessibility", "conversation.codeButton.description", fallback: "Use code format")
      }
      internal enum EmphemeralButton {
        /// Set a timer for self-deleting messages
        internal static let description = L10n.tr("Accessibility", "conversation.emphemeralButton.description", fallback: "Set a timer for self-deleting messages")
      }
      internal enum GifButton {
        /// Select a GIF
        internal static let description = L10n.tr("Accessibility", "conversation.gifButton.description", fallback: "Select a GIF")
      }
      internal enum HeaderButton {
        /// Use a heading
        internal static let description = L10n.tr("Accessibility", "conversation.headerButton.description", fallback: "Use a heading")
      }
      internal enum HideFormattingButton {
        /// Hide formatting options
        internal static let description = L10n.tr("Accessibility", "conversation.hideFormattingButton.description", fallback: "Hide formatting options")
      }
      internal enum ItalicButton {
        /// Use italic text
        internal static let description = L10n.tr("Accessibility", "conversation.italicButton.description", fallback: "Use italic text")
      }
      internal enum LegalHoldIcon {
        /// Legal hold
        internal static let description = L10n.tr("Accessibility", "conversation.legalHoldIcon.description", fallback: "Legal hold")
      }
      internal enum LocationButton {
        /// Share your location
        internal static let description = L10n.tr("Accessibility", "conversation.locationButton.description", fallback: "Share your location")
      }
      internal enum MentionButton {
        /// Mention someone
        internal static let description = L10n.tr("Accessibility", "conversation.mentionButton.description", fallback: "Mention someone")
      }
      internal enum MessageInfo {
        /// Double tap to hide or show message info
        internal static let hint = L10n.tr("Accessibility", "conversation.messageInfo.hint", fallback: "Double tap to hide or show message info")
      }
      internal enum MessageOptions {
        /// Triple tap to open messaging options
        internal static let hint = L10n.tr("Accessibility", "conversation.messageOptions.hint", fallback: "Triple tap to open messaging options")
      }
      internal enum MoreButton {
        /// Open more messaging options
        internal static let description = L10n.tr("Accessibility", "conversation.moreButton.description", fallback: "Open more messaging options")
      }
      internal enum NumberListButton {
        /// Use number list
        internal static let description = L10n.tr("Accessibility", "conversation.numberListButton.description", fallback: "Use number list")
      }
      internal enum OpenFormattingButton {
        /// Open formatting options
        internal static let description = L10n.tr("Accessibility", "conversation.openFormattingButton.description", fallback: "Open formatting options")
      }
      internal enum PingButton {
        /// Send a ping
        internal static let description = L10n.tr("Accessibility", "conversation.pingButton.description", fallback: "Send a ping")
      }
      internal enum ProfileImage {
        /// Profile picture
        internal static let description = L10n.tr("Accessibility", "conversation.profileImage.description", fallback: "Profile picture")
        /// Double tap to open profile
        internal static let hint = L10n.tr("Accessibility", "conversation.profileImage.hint", fallback: "Double tap to open profile")
      }
      internal enum ScrollToBottomButton {
        /// Scroll to the bottom of the conversation
        internal static let description = L10n.tr("Accessibility", "conversation.scrollToBottomButton.description", fallback: "Scroll to the bottom of the conversation")
        /// Tap to scroll to the bottom of the conversation
        internal static let hint = L10n.tr("Accessibility", "conversation.scrollToBottomButton.hint", fallback: "Tap to scroll to the bottom of the conversation")
      }
      internal enum SearchButton {
        /// Open search
        internal static let description = L10n.tr("Accessibility", "conversation.searchButton.description", fallback: "Open search")
      }
      internal enum SendButton {
        /// Send this message
        internal static let description = L10n.tr("Accessibility", "conversation.sendButton.description", fallback: "Send this message")
      }
      internal enum SketchButton {
        /// Open sketch to draw or write
        internal static let description = L10n.tr("Accessibility", "conversation.sketchButton.description", fallback: "Open sketch to draw or write")
      }
      internal enum TimerButton {
        /// Set a timer for self-deleting messages
        internal static let description = L10n.tr("Accessibility", "conversation.timerButton.description", fallback: "Set a timer for self-deleting messages")
      }
      internal enum TimerForSelfDeletingMessagesDay {
        /// %@ day
        internal static func value(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversation.timerForSelfDeletingMessagesDay.value", String(describing: p1), fallback: "%@ day")
        }
      }
      internal enum TimerForSelfDeletingMessagesHour {
        /// %@ hour
        internal static func value(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversation.timerForSelfDeletingMessagesHour.value", String(describing: p1), fallback: "%@ hour")
        }
      }
      internal enum TimerForSelfDeletingMessagesMinutes {
        /// %@ minutes
        internal static func value(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversation.timerForSelfDeletingMessagesMinutes.value", String(describing: p1), fallback: "%@ minutes")
        }
      }
      internal enum TimerForSelfDeletingMessagesSeconds {
        /// %@ seconds
        internal static func value(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversation.timerForSelfDeletingMessagesSeconds.value", String(describing: p1), fallback: "%@ seconds")
        }
      }
      internal enum TimerForSelfDeletingMessagesWeek {
        /// %@ week
        internal static func value(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversation.timerForSelfDeletingMessagesWeek.value", String(describing: p1), fallback: "%@ week")
        }
      }
      internal enum TimerForSelfDeletingMessagesWeeks {
        /// %@ weeks
        internal static func value(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversation.timerForSelfDeletingMessagesWeeks.value", String(describing: p1), fallback: "%@ weeks")
        }
      }
      internal enum TitleViewForGroup {
        /// Double tap to open conversation details
        internal static let hint = L10n.tr("Accessibility", "conversation.titleViewForGroup.hint", fallback: "Double tap to open conversation details")
      }
      internal enum TitleViewForOneToOne {
        /// Double tap to open profile
        internal static let hint = L10n.tr("Accessibility", "conversation.titleViewForOneToOne.hint", fallback: "Double tap to open profile")
      }
      internal enum UploadFileButton {
        /// Share a file
        internal static let description = L10n.tr("Accessibility", "conversation.uploadFileButton.description", fallback: "Share a file")
      }
      internal enum VerifiedIcon {
        /// Verified
        internal static let description = L10n.tr("Accessibility", "conversation.verifiedIcon.description", fallback: "Verified")
      }
      internal enum VideoButton {
        /// Record a video
        internal static let description = L10n.tr("Accessibility", "conversation.videoButton.description", fallback: "Record a video")
      }
    }
    internal enum ConversationAnnouncement {
      internal enum Audio {
        /// Audio message received from %@
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversationAnnouncement.audio.description", String(describing: p1), fallback: "Audio message received from %@")
        }
      }
      internal enum DeletedMessage {
        /// %@ deleted a message
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversationAnnouncement.deletedMessage.description", String(describing: p1), fallback: "%@ deleted a message")
        }
      }
      internal enum EditedMessage {
        /// %@ edited a message
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversationAnnouncement.editedMessage.description", String(describing: p1), fallback: "%@ edited a message")
        }
      }
      internal enum File {
        /// File %@ received from %@
        internal static func description(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Accessibility", "conversationAnnouncement.file.description", String(describing: p1), String(describing: p2), fallback: "File %@ received from %@")
        }
      }
      internal enum Location {
        /// %@ shared location
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversationAnnouncement.location.description", String(describing: p1), fallback: "%@ shared location")
        }
      }
      internal enum Picture {
        /// Picture received from %@
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversationAnnouncement.picture.description", String(describing: p1), fallback: "Picture received from %@")
        }
      }
      internal enum Ping {
        /// %@ pinged
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversationAnnouncement.ping.description", String(describing: p1), fallback: "%@ pinged")
        }
      }
      internal enum Text {
        /// Text message received from %@
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversationAnnouncement.text.description", String(describing: p1), fallback: "Text message received from %@")
        }
      }
      internal enum Video {
        /// Video message received from %@
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversationAnnouncement.video.description", String(describing: p1), fallback: "Video message received from %@")
        }
      }
    }
    internal enum ConversationDetails {
      internal enum CloseButton {
        /// Close conversation details
        internal static let description = L10n.tr("Accessibility", "conversationDetails.closeButton.description", fallback: "Close conversation details")
      }
      internal enum MessageTimeoutState {
        /// Selected
        internal static let description = L10n.tr("Accessibility", "conversationDetails.messageTimeoutState.description", fallback: "Selected")
      }
      internal enum MoreButton {
        /// Open conversation options
        internal static let description = L10n.tr("Accessibility", "conversationDetails.moreButton.description", fallback: "Open conversation options")
      }
      internal enum OptionButton {
        /// Double tap to open settings
        internal static let hint = L10n.tr("Accessibility", "conversationDetails.optionButton.hint", fallback: "Double tap to open settings")
      }
      internal enum ParticipantCell {
        /// Double tap to open profile
        internal static let hint = L10n.tr("Accessibility", "conversationDetails.participantCell.hint", fallback: "Double tap to open profile")
      }
      internal enum ShowParticipantsButton {
        /// Double tap to open participant list
        internal static let hint = L10n.tr("Accessibility", "conversationDetails.showParticipantsButton.hint", fallback: "Double tap to open participant list")
      }
    }
    internal enum ConversationSearch {
      internal enum AudioMessage {
        /// Audio message
        internal static let description = L10n.tr("Accessibility", "conversationSearch.audioMessage.description", fallback: "Audio message")
      }
      internal enum BackButton {
        /// Go back to search
        internal static let description = L10n.tr("Accessibility", "conversationSearch.backButton.description", fallback: "Go back to search")
      }
      internal enum CloseButton {
        /// Close search
        internal static let description = L10n.tr("Accessibility", "conversationSearch.closeButton.description", fallback: "Close search")
      }
      internal enum EmptyResult {
        /// No results
        internal static let description = L10n.tr("Accessibility", "conversationSearch.emptyResult.description", fallback: "No results")
      }
      internal enum FileName {
        /// File name
        internal static let description = L10n.tr("Accessibility", "conversationSearch.fileName.description", fallback: "File name")
      }
      internal enum FileSize {
        /// Size
        internal static let description = L10n.tr("Accessibility", "conversationSearch.fileSize.description", fallback: "Size")
      }
      internal enum FileType {
        /// Type
        internal static let description = L10n.tr("Accessibility", "conversationSearch.fileType.description", fallback: "Type")
      }
      internal enum FilesSection {
        /// Files in this conversation
        internal static let description = L10n.tr("Accessibility", "conversationSearch.filesSection.description", fallback: "Files in this conversation")
      }
      internal enum ImageMessage {
        /// Image
        internal static let description = L10n.tr("Accessibility", "conversationSearch.imageMessage.description", fallback: "Image")
      }
      internal enum ImagesSection {
        /// Pictures in this conversation
        internal static let description = L10n.tr("Accessibility", "conversationSearch.imagesSection.description", fallback: "Pictures in this conversation")
      }
      internal enum Item {
        /// Double tap to open
        internal static let hint = L10n.tr("Accessibility", "conversationSearch.item.hint", fallback: "Double tap to open")
      }
      internal enum ItemPlay {
        /// Double tap to play
        internal static let hint = L10n.tr("Accessibility", "conversationSearch.itemPlay.hint", fallback: "Double tap to play")
      }
      internal enum LinkMessage {
        /// Link
        internal static let description = L10n.tr("Accessibility", "conversationSearch.linkMessage.description", fallback: "Link")
      }
      internal enum LinksSection {
        /// Links in this conversation
        internal static let description = L10n.tr("Accessibility", "conversationSearch.linksSection.description", fallback: "Links in this conversation")
      }
      internal enum NoItems {
        /// No items in collection
        internal static let description = L10n.tr("Accessibility", "conversationSearch.noItems.description", fallback: "No items in collection")
      }
      internal enum Section {
        /// Double tap to open all
        internal static let hint = L10n.tr("Accessibility", "conversationSearch.section.hint", fallback: "Double tap to open all")
      }
      internal enum SentBy {
        /// Sent by %@
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "conversationSearch.sentBy.description", String(describing: p1), fallback: "Sent by %@")
        }
      }
      internal enum VideoMessage {
        /// Video message
        internal static let description = L10n.tr("Accessibility", "conversationSearch.videoMessage.description", fallback: "Video message")
      }
      internal enum VideosSection {
        /// Videos in this conversation
        internal static let description = L10n.tr("Accessibility", "conversationSearch.videosSection.description", fallback: "Videos in this conversation")
      }
    }
    internal enum ConversationsList {
      internal enum AccountButton {
        /// Double tap to open profile and settings
        internal static let hint = L10n.tr("Accessibility", "conversationsList.accountButton.hint", fallback: "Double tap to open profile and settings")
      }
      internal enum BadgeView {
        /// New messages: %d
        internal static func value(_ p1: Int) -> String {
          return L10n.tr("Accessibility", "conversationsList.badgeView.value", p1, fallback: "New messages: %d")
        }
      }
      internal enum ConnectionRequest {
        /// Pending approval of connection request
        internal static let description = L10n.tr("Accessibility", "conversationsList.connectionRequest.description", fallback: "Pending approval of connection request")
        /// Double tap to open profile
        internal static let hint = L10n.tr("Accessibility", "conversationsList.connectionRequest.hint", fallback: "Double tap to open profile")
      }
      internal enum ItemCell {
        /// Double tap to open conversation
        internal static let hint = L10n.tr("Accessibility", "conversationsList.itemCell.hint", fallback: "Double tap to open conversation")
      }
      internal enum JoinButton {
        /// Join
        internal static let description = L10n.tr("Accessibility", "conversationsList.joinButton.description", fallback: "Join")
        /// Double tap to join the call
        internal static let hint = L10n.tr("Accessibility", "conversationsList.joinButton.hint", fallback: "Double tap to join the call")
      }
      internal enum MentionStatus {
        /// You are mentioned
        internal static let value = L10n.tr("Accessibility", "conversationsList.mentionStatus.value", fallback: "You are mentioned")
      }
      internal enum ReplyStatus {
        /// Reply
        internal static let value = L10n.tr("Accessibility", "conversationsList.replyStatus.value", fallback: "Reply")
      }
      internal enum SilencedStatus {
        /// Silenced
        internal static let value = L10n.tr("Accessibility", "conversationsList.silencedStatus.value", fallback: "Silenced")
      }
    }
    internal enum ConversationsListHeader {
      internal enum CollapsedButton {
        /// Collapsed
        internal static let description = L10n.tr("Accessibility", "conversationsListHeader.collapsedButton.description", fallback: "Collapsed")
      }
      internal enum ExpandedButton {
        /// Expanded
        internal static let description = L10n.tr("Accessibility", "conversationsListHeader.expandedButton.description", fallback: "Expanded")
      }
    }
    internal enum CreateConversation {
      internal enum BackButton {
        /// Go back to contact list
        internal static let description = L10n.tr("Accessibility", "createConversation.backButton.description", fallback: "Go back to contact list")
      }
      internal enum HideSettings {
        /// Double tap to hide settings
        internal static let hint = L10n.tr("Accessibility", "createConversation.hideSettings.hint", fallback: "Double tap to hide settings")
      }
      internal enum OpenSettings {
        /// Double tap to open settings
        internal static let hint = L10n.tr("Accessibility", "createConversation.openSettings.hint", fallback: "Double tap to open settings")
      }
      internal enum SearchView {
        /// Type group name
        internal static let description = L10n.tr("Accessibility", "createConversation.searchView.description", fallback: "Type group name")
      }
      internal enum SelectedUser {
        /// Double tap to deselect
        internal static let hint = L10n.tr("Accessibility", "createConversation.selectedUser.hint", fallback: "Double tap to deselect")
      }
      internal enum UnselectedUser {
        /// Double tap to select
        internal static let hint = L10n.tr("Accessibility", "createConversation.unselectedUser.hint", fallback: "Double tap to select")
      }
    }
    internal enum CreateSecureGuestLink {
      internal enum CreateLinkButton {
        /// Create guest link
        internal static let description = L10n.tr("Accessibility", "createSecureGuestLink.CreateLinkButton.description", fallback: "Create guest link")
        /// Tap to create a secure guest link
        internal static let hint = L10n.tr("Accessibility", "createSecureGuestLink.CreateLinkButton.hint", fallback: "Tap to create a secure guest link")
      }
      internal enum GeneratePasswordButton {
        /// Generate password
        internal static let description = L10n.tr("Accessibility", "createSecureGuestLink.GeneratePasswordButton.description", fallback: "Generate password")
        /// Tap to generate a random password
        internal static let hint = L10n.tr("Accessibility", "createSecureGuestLink.GeneratePasswordButton.hint", fallback: "Tap to generate a random password")
      }
      internal enum CloseButton {
        /// Close Secure guest link
        internal static let description = L10n.tr("Accessibility", "createSecureGuestLink.closeButton.description", fallback: "Close Secure guest link")
      }
      internal enum SecuredGuestLinkPasswordTextfield {
        /// Password validation error. Please make sure the password meets the requirements.
        internal static let announcement = L10n.tr("Accessibility", "createSecureGuestLink.securedGuestLinkPasswordTextfield.announcement", fallback: "Password validation error. Please make sure the password meets the requirements.")
        /// Guest link password
        internal static let description = L10n.tr("Accessibility", "createSecureGuestLink.securedGuestLinkPasswordTextfield.description", fallback: "Guest link password")
        /// Enter a new password for the secure guest link
        internal static let hint = L10n.tr("Accessibility", "createSecureGuestLink.securedGuestLinkPasswordTextfield.hint", fallback: "Enter a new password for the secure guest link")
      }
      internal enum SecuredGuestLinkPasswordValidatedTextField {
        /// Password validation error. Please make sure the password matches the one above
        internal static let announcement = L10n.tr("Accessibility", "createSecureGuestLink.securedGuestLinkPasswordValidatedTextField.announcement", fallback: "Password validation error. Please make sure the password matches the one above")
        /// Confirm Guest Link Password
        internal static let description = L10n.tr("Accessibility", "createSecureGuestLink.securedGuestLinkPasswordValidatedTextField.description", fallback: "Confirm Guest Link Password")
        /// Re-enter the password for verification
        internal static let hint = L10n.tr("Accessibility", "createSecureGuestLink.securedGuestLinkPasswordValidatedTextField.hint", fallback: "Re-enter the password for verification")
      }
    }
    internal enum DeveloperOptionsSettings {
      internal enum BackButton {
        /// Go back to Developer options
        internal static let description = L10n.tr("Accessibility", "developerOptionsSettings.backButton.description", fallback: "Go back to Developer options")
      }
    }
    internal enum DeviceDetails {
      internal enum BackButton {
        /// Go back to device overview
        internal static let description = L10n.tr("Accessibility", "deviceDetails.backButton.description", fallback: "Go back to device overview")
      }
      internal enum HowToVerifyFingerprint {
        /// Learn more about fingerprint verification
        internal static let hint = L10n.tr("Accessibility", "deviceDetails.howToVerifyFingerprint.hint", fallback: "Learn more about fingerprint verification")
      }
      internal enum Verified {
        /// Device verified
        internal static let description = L10n.tr("Accessibility", "deviceDetails.verified.description", fallback: "Device verified")
      }
      internal enum WhyVerifyFingerprint {
        /// Double tap to learn more about verifications
        internal static let hint = L10n.tr("Accessibility", "deviceDetails.whyVerifyFingerprint.hint", fallback: "Double tap to learn more about verifications")
      }
    }
    internal enum GroupDetails {
      internal enum Conversation {
        internal enum Participants {
          /// all devices have a valid end-to-end identity certificate
          internal static let allDevicesHaveValidCertificates = L10n.tr("Accessibility", "groupDetails.conversation.participants.allDevicesHaveValidCertificates", fallback: "all devices have a valid end-to-end identity certificate")
          /// all devices are verified (Proteus)
          internal static let allDevicesProteusVerified = L10n.tr("Accessibility", "groupDetails.conversation.participants.allDevicesProteusVerified", fallback: "all devices are verified (Proteus)")
          /// all your devices have a valid end-to-end identity certificate
          internal static let allYourDevicesHaveValidCertificates = L10n.tr("Accessibility", "groupDetails.conversation.participants.allYourDevicesHaveValidCertificates", fallback: "all your devices have a valid end-to-end identity certificate")
          /// all your devices are verified (Proteus)
          internal static let allYourDevicesProteusVerified = L10n.tr("Accessibility", "groupDetails.conversation.participants.allYourDevicesProteusVerified", fallback: "all your devices are verified (Proteus)")
        }
      }
    }
    internal enum GuestConversationSettings {
      internal enum CloseButton {
        /// Close guest settings
        internal static let description = L10n.tr("Accessibility", "guestConversationSettings.closeButton.description", fallback: "Close guest settings")
      }
    }
    internal enum Landing {
      internal enum LoginEnterpriseButton {
        /// Log in with SSO
        internal static let description = L10n.tr("Accessibility", "landing.loginEnterpriseButton.description", fallback: "Log in with SSO")
      }
    }
    internal enum MessageAction {
      internal enum CopyButton {
        /// Copy picture
        internal static let description = L10n.tr("Accessibility", "messageAction.copyButton.description", fallback: "Copy picture")
      }
      internal enum DeleteButton {
        /// Delete picture
        internal static let description = L10n.tr("Accessibility", "messageAction.deleteButton.description", fallback: "Delete picture")
      }
      internal enum EmojiButton {
        /// Sketch emoji over picture
        internal static let description = L10n.tr("Accessibility", "messageAction.emojiButton.description", fallback: "Sketch emoji over picture")
      }
      internal enum LikeButton {
        /// Like the picture
        internal static let description = L10n.tr("Accessibility", "messageAction.likeButton.description", fallback: "Like the picture")
      }
      internal enum MoreButton {
        /// Open more messaging options
        internal static let description = L10n.tr("Accessibility", "messageAction.moreButton.description", fallback: "Open more messaging options")
      }
      internal enum RevealButton {
        /// Reveal in conversation
        internal static let description = L10n.tr("Accessibility", "messageAction.revealButton.description", fallback: "Reveal in conversation")
      }
      internal enum SaveButton {
        /// Save picture
        internal static let description = L10n.tr("Accessibility", "messageAction.saveButton.description", fallback: "Save picture")
      }
      internal enum ShareButton {
        /// Share picture
        internal static let description = L10n.tr("Accessibility", "messageAction.shareButton.description", fallback: "Share picture")
      }
      internal enum SketchButton {
        /// Sketch over picture
        internal static let description = L10n.tr("Accessibility", "messageAction.sketchButton.description", fallback: "Sketch over picture")
      }
      internal enum UnlikeButton {
        /// Unlike the picture
        internal static let description = L10n.tr("Accessibility", "messageAction.unlikeButton.description", fallback: "Unlike the picture")
      }
    }
    internal enum NotificationConversationSettings {
      internal enum CloseButton {
        /// Close notification settings
        internal static let description = L10n.tr("Accessibility", "notificationConversationSettings.closeButton.description", fallback: "Close notification settings")
      }
    }
    internal enum OptionsSettings {
      internal enum BackButton {
        /// Go back to Options
        internal static let description = L10n.tr("Accessibility", "optionsSettings.backButton.description", fallback: "Go back to Options")
      }
    }
    internal enum PictureView {
      internal enum CloseButton {
        /// Close picture view
        internal static let description = L10n.tr("Accessibility", "pictureView.closeButton.description", fallback: "Close picture view")
      }
    }
    internal enum Profile {
      internal enum BackButton {
        /// Go back to conversation details
        internal static let description = L10n.tr("Accessibility", "profile.backButton.description", fallback: "Go back to conversation details")
      }
      internal enum CloseButton {
        /// Close profile
        internal static let description = L10n.tr("Accessibility", "profile.closeButton.description", fallback: "Close profile")
      }
    }
    internal enum ReactionPicker {
      internal enum DismissButton {
        /// Dismiss emoji keyboard
        internal static let description = L10n.tr("Accessibility", "reactionPicker.dismissButton.description", fallback: "Dismiss emoji keyboard")
      }
      internal enum SearchFieldPlaceholder {
        /// Search for emoji
        internal static let description = L10n.tr("Accessibility", "reactionPicker.searchFieldPlaceholder.description", fallback: "Search for emoji")
      }
    }
    internal enum SearchGifs {
      internal enum GifItem {
        /// Tap to select this GIF
        internal static let accessibilityHint = L10n.tr("Accessibility", "searchGifs.gifItem.accessibilityHint", fallback: "Tap to select this GIF")
      }
      internal enum GifItemsLoaded {
        /// Loaded %@ new GIFs
        internal static func announcement(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "searchGifs.gifItems_loaded.announcement", String(describing: p1), fallback: "Loaded %@ new GIFs")
        }
      }
      internal enum NorResultsLabel {
        /// No Gifs found
        internal static let description = L10n.tr("Accessibility", "searchGifs.norResultsLabel.description", fallback: "No Gifs found")
      }
      internal enum SearchBar {
        /// Enter text to search for GIFs
        internal static let accessibilityLabel = L10n.tr("Accessibility", "searchGifs.searchBar.accessibilityLabel", fallback: "Enter text to search for GIFs")
      }
    }
    internal enum SearchView {
      internal enum ClearButton {
        /// Clear
        internal static let description = L10n.tr("Accessibility", "searchView.clearButton.description", fallback: "Clear")
      }
    }
    internal enum SelfDeletingMessagesConversationSettings {
      internal enum CloseButton {
        /// Close settings for self-deleting messages
        internal static let description = L10n.tr("Accessibility", "selfDeletingMessagesConversationSettings.closeButton.description", fallback: "Close settings for self-deleting messages")
      }
    }
    internal enum SendLocation {
      internal enum Address {
        /// Selected address %@
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "sendLocation.address.description", String(describing: p1), fallback: "Selected address %@")
        }
        /// It shows the currently selected address for sending.
        internal static let hint = L10n.tr("Accessibility", "sendLocation.address.hint", fallback: "It shows the currently selected address for sending.")
      }
    }
    internal enum ServiceConversationSettings {
      internal enum CloseButton {
        /// Close service settings
        internal static let description = L10n.tr("Accessibility", "serviceConversationSettings.closeButton.description", fallback: "Close service settings")
      }
    }
    internal enum ServiceDetails {
      internal enum BackButton {
        /// Go back to services list
        internal static let description = L10n.tr("Accessibility", "serviceDetails.backButton.description", fallback: "Go back to services list")
      }
      internal enum CloseButton {
        /// Close service details
        internal static let description = L10n.tr("Accessibility", "serviceDetails.closeButton.description", fallback: "Close service details")
      }
    }
    internal enum ServicesList {
      internal enum ServiceCell {
        /// Double tap to open service details
        internal static let hint = L10n.tr("Accessibility", "servicesList.serviceCell.hint", fallback: "Double tap to open service details")
      }
    }
    internal enum Settings {
      internal enum BackButton {
        /// Go back to Settings
        internal static let description = L10n.tr("Accessibility", "settings.backButton.description", fallback: "Go back to Settings")
      }
      internal enum CloseButton {
        /// Close settings
        internal static let description = L10n.tr("Accessibility", "settings.closeButton.description", fallback: "Close settings")
      }
      internal enum DeviceCount {
        /// %@ devices in use
        internal static func hint(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "settings.deviceCount.hint", String(describing: p1), fallback: "%@ devices in use")
        }
      }
    }
    internal enum Sketch {
      internal enum CloseButton {
        /// Close sketch
        internal static let description = L10n.tr("Accessibility", "sketch.closeButton.description", fallback: "Close sketch")
      }
      internal enum DrawButton {
        /// Draw or write
        internal static let description = L10n.tr("Accessibility", "sketch.drawButton.description", fallback: "Draw or write")
        /// Double tap to enable or disable
        internal static let hint = L10n.tr("Accessibility", "sketch.drawButton.hint", fallback: "Double tap to enable or disable")
      }
      internal enum SelectEmojiButton {
        /// Select emoji
        internal static let description = L10n.tr("Accessibility", "sketch.selectEmojiButton.description", fallback: "Select emoji")
      }
      internal enum SelectPictureButton {
        /// Select picture
        internal static let description = L10n.tr("Accessibility", "sketch.selectPictureButton.description", fallback: "Select picture")
      }
      internal enum SendButton {
        /// Send
        internal static let description = L10n.tr("Accessibility", "sketch.sendButton.description", fallback: "Send")
      }
      internal enum UndoButton {
        /// Undo last step
        internal static let description = L10n.tr("Accessibility", "sketch.undoButton.description", fallback: "Undo last step")
      }
    }
    internal enum SupportSettings {
      internal enum BackButton {
        /// Go back to Support
        internal static let description = L10n.tr("Accessibility", "supportSettings.backButton.description", fallback: "Go back to Support")
      }
    }
    internal enum TabBar {
      internal enum Email {
        /// Log in via email
        internal static let description = L10n.tr("Accessibility", "tabBar.email.description", fallback: "Log in via email")
      }
      internal enum Item {
        /// Selected
        internal static let value = L10n.tr("Accessibility", "tabBar.item.value", fallback: "Selected")
      }
      internal enum Phone {
        /// Log in via phone number
        internal static let description = L10n.tr("Accessibility", "tabBar.phone.description", fallback: "Log in via phone number")
      }
    }
  }
  internal enum InfoPlist {
    /// Allow Wire to access your camera so you can place video calls and send photos.
    internal static let nsCameraUsageDescription = L10n.tr("InfoPlist", "NSCameraUsageDescription", fallback: "Allow Wire to access your camera so you can place video calls and send photos.")
    /// *  Wire
    ///  *  Copyright (C) 2024 Wire Swiss GmbH
    ///  *
    ///  *  This program is free software: you can redistribute it and/or modify
    ///  *  it under the terms of the GNU General Public License as published by
    ///  *  the Free Software Foundation, either version 3 of the License, or
    ///  *  (at your option) any later version.
    ///  *
    ///  *  This program is distributed in the hope that it will be useful,
    ///  *  but WITHOUT ANY WARRANTY; without even the implied warranty of
    ///  *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    ///  *  GNU General Public License for more details.
    ///  *
    ///  *  You should have received a copy of the GNU General Public License
    ///  *  along with this program. If not, see http://www.gnu.org/licenses/.
    internal static let nsContactsUsageDescription = L10n.tr("InfoPlist", "NSContactsUsageDescription", fallback: "Allow Wire to access your contacts to connect you with others. We anonymize all information before uploading it to our server and do not share it with anyone else.")
    /// Is shown to the user when app is locked with AppLock feature on the phone that supports Face ID
    internal static let nsFaceIDUsageDescription = L10n.tr("InfoPlist", "NSFaceIDUsageDescription", fallback: "In order to authenticate in the app allow Wire to access the Face ID feature.")
    /// Allow Wire to access your location so you can send your location to others.
    internal static let nsLocationWhenInUseUsageDescription = L10n.tr("InfoPlist", "NSLocationWhenInUseUsageDescription", fallback: "Allow Wire to access your location so you can send your location to others.")
    /// Allow Wire to access your microphone so you can talk to people and send audio messages.
    internal static let nsMicrophoneUsageDescription = L10n.tr("InfoPlist", "NSMicrophoneUsageDescription", fallback: "Allow Wire to access your microphone so you can talk to people and send audio messages.")
    /// Showed after taking a picture with camera, but only when NSPhotoLibraryUsageDescription permission was declined. Asks permission for only writing to photo library.
    internal static let nsPhotoLibraryAddUsageDescription = L10n.tr("InfoPlist", "NSPhotoLibraryAddUsageDescription", fallback: "Allow Wire to store pictures you take in the photo library.")
    /// Showed when trying to send picture from conversaiton list. Asks permissions for reading and writing to photo library
    internal static let nsPhotoLibraryUsageDescription = L10n.tr("InfoPlist", "NSPhotoLibraryUsageDescription", fallback: "Allow Wire to access pictures stored in photo library so you can send pictures and videos to others.")
  }
  internal enum Localizable {
    /// Connection Request
    internal static let connectionRequestPendingTitle = L10n.tr("Localizable", "connection_request_pending_title", fallback: "Connection Request")
    internal enum About {
      internal enum Copyright {
        /// © Wire Swiss GmbH
        internal static let title = L10n.tr("Localizable", "about.copyright.title", fallback: "© Wire Swiss GmbH")
      }
      internal enum Legal {
        /// Legal
        internal static let title = L10n.tr("Localizable", "about.legal.title", fallback: "Legal")
      }
      internal enum Privacy {
        /// Privacy Policy
        internal static let title = L10n.tr("Localizable", "about.privacy.title", fallback: "Privacy Policy")
      }
      internal enum Tos {
        /// Terms of Use
        internal static let title = L10n.tr("Localizable", "about.tos.title", fallback: "Terms of Use")
      }
      internal enum Website {
        /// Wire Website
        internal static let title = L10n.tr("Localizable", "about.website.title", fallback: "Wire Website")
      }
    }
    internal enum AccountDeletedMissingPasscodeAlert {
      /// In order to use Wire, please set a passcode in your device settings.
      internal static let message = L10n.tr("Localizable", "account_deleted_missing_passcode_alert.message", fallback: "In order to use Wire, please set a passcode in your device settings.")
      /// No device passcode
      internal static let title = L10n.tr("Localizable", "account_deleted_missing_passcode_alert.title", fallback: "No device passcode")
    }
    internal enum AccountDeletedSessionExpiredAlert {
      /// The application did not communicate with the server for a long period of time, or your session has been remotely invalidated.
      internal static let message = L10n.tr("Localizable", "account_deleted_session_expired_alert.message", fallback: "The application did not communicate with the server for a long period of time, or your session has been remotely invalidated.")
      /// Your session expired
      internal static let title = L10n.tr("Localizable", "account_deleted_session_expired_alert.title", fallback: "Your session expired")
    }
    internal enum AddEmailPasswordStep {
      internal enum CtaButton {
        /// Confirm
        internal static let title = L10n.tr("Localizable", "add-email-password-step.cta-button.title", fallback: "Confirm")
      }
    }
    internal enum AddParticipants {
      internal enum Alert {
        /// The group is full
        internal static let title = L10n.tr("Localizable", "add_participants.alert.title", fallback: "The group is full")
        internal enum Message {
          /// Up to %1$d people can join a conversation. Currently there is only room for %2$d more.
          internal static func existingConversation(_ p1: Int, _ p2: Int) -> String {
            return L10n.tr("Localizable", "add_participants.alert.message.existing_conversation", p1, p2, fallback: "Up to %1$d people can join a conversation. Currently there is only room for %2$d more.")
          }
          /// Up to %d people can join a conversation.
          internal static func newConversation(_ p1: Int) -> String {
            return L10n.tr("Localizable", "add_participants.alert.message.new_conversation", p1, fallback: "Up to %d people can join a conversation.")
          }
        }
      }
    }
    internal enum AppLockModule {
      internal enum GoToSettingsButton {
        /// Go to Settings
        internal static let title = L10n.tr("Localizable", "appLockModule.goToSettingsButton.title", fallback: "Go to Settings")
      }
      internal enum Message {
        /// Unlock Wire with Face ID or Passcode
        internal static let faceID = L10n.tr("Localizable", "appLockModule.message.faceID", fallback: "Unlock Wire with Face ID or Passcode")
        /// Unlock Wire with Passcode
        internal static let passcode = L10n.tr("Localizable", "appLockModule.message.passcode", fallback: "Unlock Wire with Passcode")
        /// To unlock Wire, turn on Passcode in your device settings
        internal static let passcodeUnavailable = L10n.tr("Localizable", "appLockModule.message.passcodeUnavailable", fallback: "To unlock Wire, turn on Passcode in your device settings")
        /// Unlock Wire with Touch ID or Passcode
        internal static let touchID = L10n.tr("Localizable", "appLockModule.message.touchID", fallback: "Unlock Wire with Touch ID or Passcode")
      }
      internal enum UnlockButton {
        /// Unlock
        internal static let title = L10n.tr("Localizable", "appLockModule.unlockButton.title", fallback: "Unlock")
      }
    }
    internal enum ArchivedList {
      /// archive
      internal static let title = L10n.tr("Localizable", "archived_list.title", fallback: "archive")
      internal enum EmptyPlaceholder {
        /// Nothing archived yet
        internal static let headline = L10n.tr("Localizable", "archived_list.empty_placeholder.headline", fallback: "Nothing archived yet")
        /// To keep your conversation list tidy, move unused conversations here. You can always unarchive those later.
        internal static let subheadline = L10n.tr("Localizable", "archived_list.empty_placeholder.subheadline", fallback: "To keep your conversation list tidy, move unused conversations here. You can always unarchive those later.")
      }
    }
    internal enum Availability {
      /// Available
      internal static let available = L10n.tr("Localizable", "availability.available", fallback: "Available")
      /// Away
      internal static let away = L10n.tr("Localizable", "availability.away", fallback: "Away")
      /// Busy
      internal static let busy = L10n.tr("Localizable", "availability.busy", fallback: "Busy")
      /// None
      internal static let `none` = L10n.tr("Localizable", "availability.none", fallback: "None")
      internal enum Message {
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "availability.message.cancel", fallback: "Cancel")
        /// Set a status
        internal static let setStatus = L10n.tr("Localizable", "availability.message.set_status", fallback: "Set a status")
      }
      internal enum Reminder {
        internal enum Action {
          /// Do not display this information again
          internal static let dontRemindMe = L10n.tr("Localizable", "availability.reminder.action.dont_remind_me", fallback: "Do not display this information again")
          /// OK
          internal static let ok = L10n.tr("Localizable", "availability.reminder.action.ok", fallback: "OK")
        }
        internal enum Available {
          /// You will appear as Available to other people. You will receive notifications for incoming calls and for messages according to the Notifications setting in each conversation.
          internal static let message = L10n.tr("Localizable", "availability.reminder.available.message", fallback: "You will appear as Available to other people. You will receive notifications for incoming calls and for messages according to the Notifications setting in each conversation.")
          /// You are set to Available
          internal static let title = L10n.tr("Localizable", "availability.reminder.available.title", fallback: "You are set to Available")
        }
        internal enum Away {
          /// You will appear as Away to other people. You will not receive notifications about any incoming calls or messages.
          internal static let message = L10n.tr("Localizable", "availability.reminder.away.message", fallback: "You will appear as Away to other people. You will not receive notifications about any incoming calls or messages.")
          /// You are set to Away
          internal static let title = L10n.tr("Localizable", "availability.reminder.away.title", fallback: "You are set to Away")
        }
        internal enum Busy {
          /// You will appear as Busy to other people. You will only receive notifications for mentions, replies, and calls in conversations that are not muted.
          internal static let message = L10n.tr("Localizable", "availability.reminder.busy.message", fallback: "You will appear as Busy to other people. You will only receive notifications for mentions, replies, and calls in conversations that are not muted.")
          /// You are set to Busy
          internal static let title = L10n.tr("Localizable", "availability.reminder.busy.title", fallback: "You are set to Busy")
        }
        internal enum None {
          /// You will receive notifications for incoming calls and for messages according to the Notifications setting in each conversation.
          internal static let message = L10n.tr("Localizable", "availability.reminder.none.message", fallback: "You will receive notifications for incoming calls and for messages according to the Notifications setting in each conversation.")
          /// No status set
          internal static let title = L10n.tr("Localizable", "availability.reminder.none.title", fallback: "No status set")
        }
      }
    }
    internal enum BackendNotSupported {
      internal enum Alert {
        /// The server version is not supported by this app. Please contact your system administrator.
        internal static let message = L10n.tr("Localizable", "backend_not_supported.alert.message", fallback: "The server version is not supported by this app. Please contact your system administrator.")
        /// Server version not supported
        internal static let title = L10n.tr("Localizable", "backend_not_supported.alert.title", fallback: "Server version not supported")
      }
    }
    internal enum ButtonMessageCell {
      /// Your answer can't be sent, please retry.
      internal static let genericError = L10n.tr("Localizable", "button_message_cell.generic_error", fallback: "Your answer can't be sent, please retry.")
      internal enum State {
        /// confirmed
        internal static let confirmed = L10n.tr("Localizable", "button_message_cell.state.confirmed", fallback: "confirmed")
        /// selected
        internal static let selected = L10n.tr("Localizable", "button_message_cell.state.selected", fallback: "selected")
        /// unselected
        internal static let unselected = L10n.tr("Localizable", "button_message_cell.state.unselected", fallback: "unselected")
      }
    }
    internal enum Call {
      internal enum Actions {
        internal enum Label {
          /// Accept call
          internal static let acceptCall = L10n.tr("Localizable", "call.actions.label.accept_call", fallback: "Accept call")
          /// Switch camera
          internal static let flipCamera = L10n.tr("Localizable", "call.actions.label.flip_camera", fallback: "Switch camera")
          /// Join call
          internal static let joinCall = L10n.tr("Localizable", "call.actions.label.join_call", fallback: "Join call")
          /// Start audio call
          internal static let makeAudioCall = L10n.tr("Localizable", "call.actions.label.make_audio_call", fallback: "Start audio call")
          /// Start video call
          internal static let makeVideoCall = L10n.tr("Localizable", "call.actions.label.make_video_call", fallback: "Start video call")
          /// Minimize call
          internal static let minimizeCall = L10n.tr("Localizable", "call.actions.label.minimize_call", fallback: "Minimize call")
          /// Decline call
          internal static let rejectCall = L10n.tr("Localizable", "call.actions.label.reject_call", fallback: "Decline call")
          /// Switch to back camera
          internal static let switchToBackCamera = L10n.tr("Localizable", "call.actions.label.switch_to_back_camera", fallback: "Switch to back camera")
          /// Switch to front camera
          internal static let switchToFrontCamera = L10n.tr("Localizable", "call.actions.label.switch_to_front_camera", fallback: "Switch to front camera")
          /// End call
          internal static let terminateCall = L10n.tr("Localizable", "call.actions.label.terminate_call", fallback: "End call")
          /// Unmute
          internal static let toggleMuteOff = L10n.tr("Localizable", "call.actions.label.toggle_mute_off", fallback: "Unmute")
          /// Mute
          internal static let toggleMuteOn = L10n.tr("Localizable", "call.actions.label.toggle_mute_on", fallback: "Mute")
          /// Disable speaker
          internal static let toggleSpeakerOff = L10n.tr("Localizable", "call.actions.label.toggle_speaker_off", fallback: "Disable speaker")
          /// Enable speaker
          internal static let toggleSpeakerOn = L10n.tr("Localizable", "call.actions.label.toggle_speaker_on", fallback: "Enable speaker")
          /// Turn off camera
          internal static let toggleVideoOff = L10n.tr("Localizable", "call.actions.label.toggle_video_off", fallback: "Turn off camera")
          /// Turn on camera
          internal static let toggleVideoOn = L10n.tr("Localizable", "call.actions.label.toggle_video_on", fallback: "Turn on camera")
        }
      }
      internal enum Alert {
        internal enum Ongoing {
          /// This will end your other call.
          internal static let alertTitle = L10n.tr("Localizable", "call.alert.ongoing.alert_title", fallback: "This will end your other call.")
          internal enum Join {
            /// Join anyway
            internal static let button = L10n.tr("Localizable", "call.alert.ongoing.join.button", fallback: "Join anyway")
            /// A call is active in another conversation.
            /// Joining this call will hang up the other one.
            internal static let message = L10n.tr("Localizable", "call.alert.ongoing.join.message", fallback: "A call is active in another conversation.\nJoining this call will hang up the other one.")
          }
          internal enum Start {
            /// Call anyway
            internal static let button = L10n.tr("Localizable", "call.alert.ongoing.start.button", fallback: "Call anyway")
            /// A call is active in another conversation.
            /// Calling here will hang up the other call.
            internal static let message = L10n.tr("Localizable", "call.alert.ongoing.start.message", fallback: "A call is active in another conversation.\nCalling here will hang up the other call.")
          }
        }
      }
      internal enum Announcement {
        /// Incoming call from %@
        internal static func incoming(_ p1: Any) -> String {
          return L10n.tr("Localizable", "call.announcement.incoming", String(describing: p1), fallback: "Incoming call from %@")
        }
      }
      internal enum Degraded {
        internal enum Alert {
          /// New Device
          internal static let title = L10n.tr("Localizable", "call.degraded.alert.title", fallback: "New Device")
          internal enum Action {
            /// Call anyway
            internal static let `continue` = L10n.tr("Localizable", "call.degraded.alert.action.continue", fallback: "Call anyway")
          }
          internal enum Message {
            /// You started using a new device.
            internal static let `self` = L10n.tr("Localizable", "call.degraded.alert.message.self", fallback: "You started using a new device.")
            /// Someone started using a new device.
            internal static let unknown = L10n.tr("Localizable", "call.degraded.alert.message.unknown", fallback: "Someone started using a new device.")
            /// %@ started using a new device.
            internal static func user(_ p1: Any) -> String {
              return L10n.tr("Localizable", "call.degraded.alert.message.user", String(describing: p1), fallback: "%@ started using a new device.")
            }
          }
        }
        internal enum Ended {
          internal enum Alert {
            /// Call ended
            internal static let title = L10n.tr("Localizable", "call.degraded.ended.alert.title", fallback: "Call ended")
            internal enum Message {
              /// The call was disconnected because you started using a new device.
              internal static let `self` = L10n.tr("Localizable", "call.degraded.ended.alert.message.self", fallback: "The call was disconnected because you started using a new device.")
              /// The call was disconnected because someone is no longer a verified contact.
              internal static let unknown = L10n.tr("Localizable", "call.degraded.ended.alert.message.unknown", fallback: "The call was disconnected because someone is no longer a verified contact.")
              /// The call was disconnected because %@ is no longer a verified contact.
              internal static func user(_ p1: Any) -> String {
                return L10n.tr("Localizable", "call.degraded.ended.alert.message.user", String(describing: p1), fallback: "The call was disconnected because %@ is no longer a verified contact.")
              }
            }
          }
        }
        internal enum Incoming {
          internal enum Alert {
            internal enum Action {
              /// Join anyway
              internal static let `continue` = L10n.tr("Localizable", "call.degraded.incoming.alert.action.continue", fallback: "Join anyway")
            }
          }
        }
      }
      internal enum Grid {
        /// Connecting
        internal static let connecting = L10n.tr("Localizable", "call.grid.connecting", fallback: "Connecting")
        /// No active video speakers...
        internal static let noActiveSpeakers = L10n.tr("Localizable", "call.grid.no_active_speakers", fallback: "No active video speakers...")
        internal enum Hints {
          /// Double tap on a tile for fullscreen
          internal static let fullscreen = L10n.tr("Localizable", "call.grid.hints.fullscreen", fallback: "Double tap on a tile for fullscreen")
          /// Double tap to go back
          internal static let goBack = L10n.tr("Localizable", "call.grid.hints.go_back", fallback: "Double tap to go back")
          /// Double tap to go back, pinch to zoom
          internal static let goBackOrZoom = L10n.tr("Localizable", "call.grid.hints.go_back_or_zoom", fallback: "Double tap to go back, pinch to zoom")
          /// Pinch to zoom
          internal static let zoom = L10n.tr("Localizable", "call.grid.hints.zoom", fallback: "Pinch to zoom")
        }
      }
      internal enum Mls {
        internal enum Degraded {
          internal enum Alert {
            /// At least one participant started using a new device or has an invalid certificate.
            /// 
            /// Do you still want to start the call?
            internal static let message = L10n.tr("Localizable", "call.mls.degraded.alert.message", fallback: "At least one participant started using a new device or has an invalid certificate.\n\nDo you still want to start the call?")
            /// Conversation no longer verified
            internal static let title = L10n.tr("Localizable", "call.mls.degraded.alert.title", fallback: "Conversation no longer verified")
            internal enum Action {
              /// Call anyway
              internal static let `continue` = L10n.tr("Localizable", "call.mls.degraded.alert.action.continue", fallback: "Call anyway")
            }
          }
          internal enum Ended {
            internal enum Alert {
              /// The call was disconnected as at least one participant started using a new device or has an invalid certificate.
              internal static let message = L10n.tr("Localizable", "call.mls.degraded.ended.alert.message", fallback: "The call was disconnected as at least one participant started using a new device or has an invalid certificate.")
              /// Conversation no longer verified
              internal static let title = L10n.tr("Localizable", "call.mls.degraded.ended.alert.title", fallback: "Conversation no longer verified")
            }
          }
          internal enum Incoming {
            internal enum Alert {
              /// At least one participant started using a new device or has an invalid certificate.
              /// 
              /// Do you still want to join the call?
              internal static let message = L10n.tr("Localizable", "call.mls.degraded.incoming.alert.message", fallback: "At least one participant started using a new device or has an invalid certificate.\n\nDo you still want to join the call?")
              internal enum Action {
                /// Join anyway
                internal static let `continue` = L10n.tr("Localizable", "call.mls.degraded.incoming.alert.action.continue", fallback: "Join anyway")
              }
            }
          }
        }
      }
      internal enum Overlay {
        internal enum SwitchTo {
          /// ALL
          internal static let all = L10n.tr("Localizable", "call.overlay.switch_to.all", fallback: "ALL")
          /// SPEAKERS
          internal static let speakers = L10n.tr("Localizable", "call.overlay.switch_to.speakers", fallback: "SPEAKERS")
        }
      }
      internal enum Participants {
        /// Participants (%d)
        internal static func showAll(_ p1: Int) -> String {
          return L10n.tr("Localizable", "call.participants.show_all", p1, fallback: "Participants (%d)")
        }
        internal enum List {
          /// Participants
          internal static let title = L10n.tr("Localizable", "call.participants.list.title", fallback: "Participants")
        }
      }
      internal enum Quality {
        internal enum Indicator {
          /// Your calling relay is not reachable. This may affect your call experience.
          internal static let message = L10n.tr("Localizable", "call.quality.indicator.message", fallback: "Your calling relay is not reachable. This may affect your call experience.")
          internal enum MoreInfo {
            internal enum Button {
              /// More info
              internal static let text = L10n.tr("Localizable", "call.quality.indicator.more_info.button.text", fallback: "More info")
            }
          }
        }
      }
      internal enum Status {
        /// Connecting…
        internal static let connecting = L10n.tr("Localizable", "call.status.connecting", fallback: "Connecting…")
        /// Constant Bit Rate
        internal static let constantBitrate = L10n.tr("Localizable", "call.status.constant_bitrate", fallback: "Constant Bit Rate")
        /// Calling…
        internal static let incoming = L10n.tr("Localizable", "call.status.incoming", fallback: "Calling…")
        /// Ringing…
        internal static let outgoing = L10n.tr("Localizable", "call.status.outgoing", fallback: "Ringing…")
        /// Reconnecting…
        internal static let reconnecting = L10n.tr("Localizable", "call.status.reconnecting", fallback: "Reconnecting…")
        /// Hanging up…
        internal static let terminating = L10n.tr("Localizable", "call.status.terminating", fallback: "Hanging up…")
        /// Variable Bit Rate
        internal static let variableBitrate = L10n.tr("Localizable", "call.status.variable_bitrate", fallback: "Variable Bit Rate")
        internal enum Incoming {
          /// %@ is calling…
          internal static func user(_ p1: Any) -> String {
            return L10n.tr("Localizable", "call.status.incoming.user", String(describing: p1), fallback: "%@ is calling…")
          }
        }
        internal enum Outgoing {
          /// Calling %@…
          internal static func user(_ p1: Any) -> String {
            return L10n.tr("Localizable", "call.status.outgoing.user", String(describing: p1), fallback: "Calling %@…")
          }
        }
      }
      internal enum Video {
        /// Video paused
        internal static let paused = L10n.tr("Localizable", "call.video.paused", fallback: "Video paused")
        internal enum TooMany {
          internal enum Alert {
            /// Video calls only work in groups of 4 or less.
            internal static let message = L10n.tr("Localizable", "call.video.too_many.alert.message", fallback: "Video calls only work in groups of 4 or less.")
            /// Too many people for Video
            internal static let title = L10n.tr("Localizable", "call.video.too_many.alert.title", fallback: "Too many people for Video")
          }
        }
      }
    }
    internal enum Calling {
      internal enum QualitySurvey {
        /// How do you rate the overall quality of the call?
        internal static let question = L10n.tr("Localizable", "calling.quality_survey.question", fallback: "How do you rate the overall quality of the call?")
        /// Skip
        internal static let skipButtonTitle = L10n.tr("Localizable", "calling.quality_survey.skip_button_title", fallback: "Skip")
        /// Call Quality Feedback
        internal static let title = L10n.tr("Localizable", "calling.quality_survey.title", fallback: "Call Quality Feedback")
        internal enum Answer {
          /// Bad
          internal static let _1 = L10n.tr("Localizable", "calling.quality_survey.answer.1", fallback: "Bad")
          /// Poor
          internal static let _2 = L10n.tr("Localizable", "calling.quality_survey.answer.2", fallback: "Poor")
          /// Fair
          internal static let _3 = L10n.tr("Localizable", "calling.quality_survey.answer.3", fallback: "Fair")
          /// Good
          internal static let _4 = L10n.tr("Localizable", "calling.quality_survey.answer.4", fallback: "Good")
          /// Excellent
          internal static let _5 = L10n.tr("Localizable", "calling.quality_survey.answer.5", fallback: "Excellent")
        }
      }
    }
    internal enum CameraAccess {
      /// Wire needs access to the camera
      internal static let denied = L10n.tr("Localizable", "camera_access.denied", fallback: "Wire needs access to the camera")
      internal enum Denied {
        /// 
        internal static let instruction = L10n.tr("Localizable", "camera_access.denied.instruction", fallback: "")
        /// Enable it in Wire Settings
        internal static let openSettings = L10n.tr("Localizable", "camera_access.denied.open_settings", fallback: "Enable it in Wire Settings")
      }
    }
    internal enum CameraControls {
      /// AE/AF Lock
      internal static let aeafLock = L10n.tr("Localizable", "camera_controls.aeaf_lock", fallback: "AE/AF Lock")
    }
    internal enum Collections {
      internal enum ImageViewer {
        internal enum Copied {
          /// Picture copied
          internal static let title = L10n.tr("Localizable", "collections.image_viewer.copied.title", fallback: "Picture copied")
        }
      }
      internal enum Search {
        /// No results
        internal static let noItems = L10n.tr("Localizable", "collections.search.no_items", fallback: "No results")
        internal enum Field {
          /// Search text messages
          internal static let placeholder = L10n.tr("Localizable", "collections.search.field.placeholder", fallback: "Search text messages")
        }
      }
      internal enum Section {
        /// No items in collection
        internal static let noItems = L10n.tr("Localizable", "collections.section.no_items", fallback: "No items in collection")
        internal enum All {
          /// Show all %d →
          internal static func button(_ p1: Int) -> String {
            return L10n.tr("Localizable", "collections.section.all.button", p1, fallback: "Show all %d →")
          }
        }
        internal enum Files {
          /// Files
          internal static let title = L10n.tr("Localizable", "collections.section.files.title", fallback: "Files")
        }
        internal enum Images {
          /// Images
          internal static let title = L10n.tr("Localizable", "collections.section.images.title", fallback: "Images")
        }
        internal enum Links {
          /// Links
          internal static let title = L10n.tr("Localizable", "collections.section.links.title", fallback: "Links")
        }
        internal enum Videos {
          /// Videos
          internal static let title = L10n.tr("Localizable", "collections.section.videos.title", fallback: "Videos")
        }
      }
    }
    internal enum Compose {
      internal enum Contact {
        /// Conversation
        internal static let title = L10n.tr("Localizable", "compose.contact.title", fallback: "Conversation")
      }
      internal enum Drafts {
        /// Messages
        internal static let title = L10n.tr("Localizable", "compose.drafts.title", fallback: "Messages")
        internal enum Compose {
          /// Type a message
          internal static let title = L10n.tr("Localizable", "compose.drafts.compose.title", fallback: "Type a message")
          internal enum Delete {
            internal enum Confirm {
              /// This action will permanently delete this draft and cannot be undone.
              internal static let message = L10n.tr("Localizable", "compose.drafts.compose.delete.confirm.message", fallback: "This action will permanently delete this draft and cannot be undone.")
              /// Confirm Deletion
              internal static let title = L10n.tr("Localizable", "compose.drafts.compose.delete.confirm.title", fallback: "Confirm Deletion")
              internal enum Action {
                /// Delete
                internal static let title = L10n.tr("Localizable", "compose.drafts.compose.delete.confirm.action.title", fallback: "Delete")
              }
            }
          }
          internal enum Dismiss {
            internal enum Confirm {
              /// Save as draft
              internal static let title = L10n.tr("Localizable", "compose.drafts.compose.dismiss.confirm.title", fallback: "Save as draft")
              internal enum Action {
                /// Save
                internal static let title = L10n.tr("Localizable", "compose.drafts.compose.dismiss.confirm.action.title", fallback: "Save")
              }
            }
            internal enum Delete {
              internal enum Action {
                /// Delete
                internal static let title = L10n.tr("Localizable", "compose.drafts.compose.dismiss.delete.action.title", fallback: "Delete")
              }
            }
          }
          internal enum Subject {
            /// Tap to set a subject
            internal static let placeholder = L10n.tr("Localizable", "compose.drafts.compose.subject.placeholder", fallback: "Tap to set a subject")
          }
        }
        internal enum Empty {
          /// Tap + to compose one
          internal static let subtitle = L10n.tr("Localizable", "compose.drafts.empty.subtitle", fallback: "Tap + to compose one")
          /// No messages
          internal static let title = L10n.tr("Localizable", "compose.drafts.empty.title", fallback: "No messages")
        }
      }
      internal enum Message {
        /// Message
        internal static let title = L10n.tr("Localizable", "compose.message.title", fallback: "Message")
      }
    }
    internal enum ConnectionRequest {
      /// Connect
      internal static let sendButtonTitle = L10n.tr("Localizable", "connection_request.send_button_title", fallback: "Connect")
      /// Connect to %@
      internal static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "connection_request.title", String(describing: p1), fallback: "Connect to %@")
      }
    }
    internal enum ContactsUi {
      /// Requested to connect
      internal static let connectionRequest = L10n.tr("Localizable", "contacts_ui.connection_request", fallback: "Requested to connect")
      /// Invite others
      internal static let inviteOthers = L10n.tr("Localizable", "contacts_ui.invite_others", fallback: "Invite others")
      /// %@ in Contacts
      internal static func nameInContacts(_ p1: Any) -> String {
        return L10n.tr("Localizable", "contacts_ui.name_in_contacts", String(describing: p1), fallback: "%@ in Contacts")
      }
      /// Search by name
      internal static let searchPlaceholder = L10n.tr("Localizable", "contacts_ui.search_placeholder", fallback: "Search by name")
      /// Invite people
      internal static let title = L10n.tr("Localizable", "contacts_ui.title", fallback: "Invite people")
      internal enum ActionButton {
        /// Invite
        internal static let invite = L10n.tr("Localizable", "contacts_ui.action_button.invite", fallback: "Invite")
        /// Open
        internal static let `open` = L10n.tr("Localizable", "contacts_ui.action_button.open", fallback: "Open")
      }
      internal enum InviteSheet {
        /// Cancel
        internal static let cancelButtonTitle = L10n.tr("Localizable", "contacts_ui.invite_sheet.cancel_button_title", fallback: "Cancel")
      }
      internal enum Notification {
        /// Failed to send invitation
        internal static let invitationFailed = L10n.tr("Localizable", "contacts_ui.notification.invitation_failed", fallback: "Failed to send invitation")
        /// Invitation sent
        internal static let invitationSent = L10n.tr("Localizable", "contacts_ui.notification.invitation_sent", fallback: "Invitation sent")
      }
    }
    internal enum Content {
      internal enum File {
        /// Browse
        internal static let browse = L10n.tr("Localizable", "content.file.browse", fallback: "Browse")
        /// Downloading…
        internal static let downloading = L10n.tr("Localizable", "content.file.downloading", fallback: "Downloading…")
        /// Save
        internal static let saveAudio = L10n.tr("Localizable", "content.file.save_audio", fallback: "Save")
        /// Save
        internal static let saveVideo = L10n.tr("Localizable", "content.file.save_video", fallback: "Save")
        /// Record a video
        internal static let takeVideo = L10n.tr("Localizable", "content.file.take_video", fallback: "Record a video")
        /// You can send files up to %@
        internal static func tooBig(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.file.too_big", String(describing: p1), fallback: "You can send files up to %@")
        }
        /// Upload cancelled
        internal static let uploadCancelled = L10n.tr("Localizable", "content.file.upload_cancelled", fallback: "Upload cancelled")
        /// Upload failed
        internal static let uploadFailed = L10n.tr("Localizable", "content.file.upload_failed", fallback: "Upload failed")
        /// Videos
        internal static let uploadVideo = L10n.tr("Localizable", "content.file.upload_video", fallback: "Videos")
        /// Uploading…
        internal static let uploading = L10n.tr("Localizable", "content.file.uploading", fallback: "Uploading…")
      }
      internal enum Image {
        /// Save
        internal static let saveImage = L10n.tr("Localizable", "content.image.save_image", fallback: "Save")
      }
      internal enum Message {
        /// Copy
        internal static let copy = L10n.tr("Localizable", "content.message.copy", fallback: "Copy")
        /// Delete
        internal static let delete = L10n.tr("Localizable", "content.message.delete", fallback: "Delete")
        /// Delete…
        internal static let deleteEllipsis = L10n.tr("Localizable", "content.message.delete_ellipsis", fallback: "Delete…")
        /// Details
        internal static let details = L10n.tr("Localizable", "content.message.details", fallback: "Details")
        /// Download
        internal static let download = L10n.tr("Localizable", "content.message.download", fallback: "Download")
        /// Reveal
        internal static let goToConversation = L10n.tr("Localizable", "content.message.go_to_conversation", fallback: "Reveal")
        /// Like
        internal static let like = L10n.tr("Localizable", "content.message.like", fallback: "Like")
        /// Open
        internal static let `open` = L10n.tr("Localizable", "content.message.open", fallback: "Open")
        /// Original message
        internal static let originalLabel = L10n.tr("Localizable", "content.message.original_label", fallback: "Original message")
        /// Reactions
        internal static let reactions = L10n.tr("Localizable", "content.message.reactions", fallback: "Reactions")
        /// Reply
        internal static let reply = L10n.tr("Localizable", "content.message.reply", fallback: "Reply")
        /// Resend
        internal static let resend = L10n.tr("Localizable", "content.message.resend", fallback: "Resend")
        /// Save
        internal static let save = L10n.tr("Localizable", "content.message.save", fallback: "Save")
        /// Sign
        internal static let sign = L10n.tr("Localizable", "content.message.sign", fallback: "Sign")
        /// Unlike
        internal static let unlike = L10n.tr("Localizable", "content.message.unlike", fallback: "Unlike")
        internal enum AudioMessage {
          /// Play the audio message
          internal static let accessibility = L10n.tr("Localizable", "content.message.audio_message.accessibility", fallback: "Play the audio message")
        }
        internal enum Forward {
          /// Search…
          internal static let to = L10n.tr("Localizable", "content.message.forward.to", fallback: "Search…")
        }
        internal enum LinkAttachment {
          internal enum AccessibilityLabel {
            /// SoundCloud playlist preview
            internal static let soundcloudSet = L10n.tr("Localizable", "content.message.link_attachment.accessibility_label.soundcloud_set", fallback: "SoundCloud playlist preview")
            /// SoundCloud song preview
            internal static let soundcloudSong = L10n.tr("Localizable", "content.message.link_attachment.accessibility_label.soundcloud_song", fallback: "SoundCloud song preview")
            /// YouTube video preview
            internal static let youtube = L10n.tr("Localizable", "content.message.link_attachment.accessibility_label.youtube", fallback: "YouTube video preview")
          }
        }
        internal enum OpenLinkAlert {
          /// This will take you to
          /// %@
          internal static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.message.open_link_alert.message", String(describing: p1), fallback: "This will take you to\n%@")
          }
          /// Open
          internal static let `open` = L10n.tr("Localizable", "content.message.open_link_alert.open", fallback: "Open")
          /// Visit Link
          internal static let title = L10n.tr("Localizable", "content.message.open_link_alert.title", fallback: "Visit Link")
        }
        internal enum Reply {
          /// You cannot see this message.
          internal static let brokenMessage = L10n.tr("Localizable", "content.message.reply.broken_message", fallback: "You cannot see this message.")
          /// Edited
          internal static let editedMessage = L10n.tr("Localizable", "content.message.reply.edited_message", fallback: "Edited")
          internal enum OriginalTimestamp {
            /// Original message from %@
            internal static func date(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.message.reply.original_timestamp.date", String(describing: p1), fallback: "Original message from %@")
            }
            /// Original message from %@
            internal static func time(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.message.reply.original_timestamp.time", String(describing: p1), fallback: "Original message from %@")
            }
          }
        }
      }
      internal enum Ping {
        /// %@ pinged
        internal static func text(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.ping.text", String(describing: p1), fallback: "%@ pinged")
        }
        /// %@ pinged
        internal static func textYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.ping.text-you", String(describing: p1), fallback: "%@ pinged")
        }
        internal enum Text {
          /// You
          internal static let you = L10n.tr("Localizable", "content.ping.text.you", fallback: "You")
        }
      }
      internal enum Player {
        /// UNABLE TO PLAY TRACK
        internal static let unableToPlay = L10n.tr("Localizable", "content.player.unable_to_play", fallback: "UNABLE TO PLAY TRACK")
      }
      internal enum Reactions {
        /// Search for emoji
        internal static let search = L10n.tr("Localizable", "content.reactions.search", fallback: "Search for emoji")
        /// Select reaction
        internal static let title = L10n.tr("Localizable", "content.reactions.title", fallback: "Select reaction")
      }
      internal enum ReactionsList {
        /// Liked by
        internal static let likers = L10n.tr("Localizable", "content.reactions_list.likers", fallback: "Liked by")
      }
      internal enum System {
        /// and you
        internal static let andYouDative = L10n.tr("Localizable", "content.system.and_you_dative", fallback: "and you")
        /// Connected to %@
        /// Start a conversation
        internal static func connectedTo(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.connected_to", String(describing: p1), fallback: "Connected to %@\nStart a conversation")
        }
        /// Connecting to %@.
        /// Start a conversation
        internal static func connectingTo(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.connecting_to", String(describing: p1), fallback: "Connecting to %@.\nStart a conversation")
        }
        /// Start a conversation with %@
        internal static func continuedConversation(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.continued_conversation", String(describing: p1), fallback: "Start a conversation with %@")
        }
        /// Deleted: %@
        internal static func deletedMessagePrefixTimestamp(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.deleted_message_prefix_timestamp", String(describing: p1), fallback: "Deleted: %@")
        }
        /// Edited: %@
        internal static func editedMessagePrefixTimestamp(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.edited_message_prefix_timestamp", String(describing: p1), fallback: "Edited: %@")
        }
        /// %@ left
        internal static func ephemeralTimeRemaining(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.ephemeral_time_remaining", String(describing: p1), fallback: "%@ left")
        }
        /// All fingerprints are verified
        internal static let isVerified = L10n.tr("Localizable", "content.system.is_verified", fallback: "All fingerprints are verified")
        /// Tap to like
        internal static let likeTooltip = L10n.tr("Localizable", "content.system.like_tooltip", fallback: "Tap to like")
        /// Delivered
        internal static let messageDeliveredTimestamp = L10n.tr("Localizable", "content.system.message_delivered_timestamp", fallback: "Delivered")
        /// %@ turned read receipts off for everyone
        internal static func messageReadReceiptOff(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_read_receipt_off", String(describing: p1), fallback: "%@ turned read receipts off for everyone")
        }
        /// %@ turned read receipts off for everyone
        internal static func messageReadReceiptOffYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_read_receipt_off-you", String(describing: p1), fallback: "%@ turned read receipts off for everyone")
        }
        /// %@ turned read receipts on for everyone
        internal static func messageReadReceiptOn(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_read_receipt_on", String(describing: p1), fallback: "%@ turned read receipts on for everyone")
        }
        /// %@ turned read receipts on for everyone
        internal static func messageReadReceiptOnYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_read_receipt_on-you", String(describing: p1), fallback: "%@ turned read receipts on for everyone")
        }
        /// Read receipts are on
        internal static let messageReadReceiptOnAddToGroup = L10n.tr("Localizable", "content.system.message_read_receipt_on_add_to_group", fallback: "Read receipts are on")
        /// Seen
        internal static let messageReadTimestamp = L10n.tr("Localizable", "content.system.message_read_timestamp", fallback: "Seen")
        /// Sent
        internal static let messageSentTimestamp = L10n.tr("Localizable", "content.system.message_sent_timestamp", fallback: "Sent")
        /// %@ set the message timer to %@
        internal static func messageTimerChanges(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_timer_changes", String(describing: p1), String(describing: p2), fallback: "%@ set the message timer to %@")
        }
        /// %@ set the message timer to %@
        internal static func messageTimerChangesYou(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_timer_changes-you", String(describing: p1), String(describing: p2), fallback: "%@ set the message timer to %@")
        }
        /// %@ turned off the message timer
        internal static func messageTimerOff(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_timer_off", String(describing: p1), fallback: "%@ turned off the message timer")
        }
        /// %@ turned off the message timer
        internal static func messageTimerOffYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_timer_off-you", String(describing: p1), fallback: "%@ turned off the message timer")
        }
        /// You haven’t used this device for a while. Some messages may not appear here.
        internal static let missingMessages = L10n.tr("Localizable", "content.system.missing_messages", fallback: "You haven’t used this device for a while. Some messages may not appear here.")
        /// Plural format key: "%#@d_new_devices@"
        internal static func newDevices(_ p1: Int) -> String {
          return L10n.tr("Localizable", "content.system.new_devices", p1, fallback: "Plural format key: \"%#@d_new_devices@\"")
        }
        /// New user joined.
        internal static let newUsers = L10n.tr("Localizable", "content.system.new_users", fallback: "New user joined.")
        /// %@ added %@
        internal static func otherAddedParticipant(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_added_participant", String(describing: p1), String(describing: p2), fallback: "%@ added %@")
        }
        /// %@ added you
        internal static func otherAddedYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_added_you", String(describing: p1), fallback: "%@ added you")
        }
        /// %@ left
        internal static func otherLeft(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_left", String(describing: p1), fallback: "%@ left")
        }
        /// %@ removed %@
        internal static func otherRemovedOther(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_removed_other", String(describing: p1), String(describing: p2), fallback: "%@ removed %@")
        }
        /// %@ removed you
        internal static func otherRemovedYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_removed_you", String(describing: p1), fallback: "%@ removed you")
        }
        /// %@ removed the conversation name
        internal static func otherRenamedConvToNothing(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_renamed_conv_to_nothing", String(describing: p1), fallback: "%@ removed the conversation name")
        }
        /// %@ started a conversation with %@
        internal static func otherStartedConversation(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_started_conversation", String(describing: p1), String(describing: p2), fallback: "%@ started a conversation with %@")
        }
        /// %@ called
        internal static func otherWantedToTalk(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_wanted_to_talk", String(describing: p1), fallback: "%@ called")
        }
        /// %@ and %@
        internal static func participants1Other(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.participants_1_other", String(describing: p1), String(describing: p2), fallback: "%@ and %@")
        }
        /// Plural format key: "%@ %#@and_number_of_others@"
        internal static func participantsNOthers(_ p1: Any, _ p2: Int) -> String {
          return L10n.tr("Localizable", "content.system.participants_n_others", String(describing: p1), p2, fallback: "Plural format key: \"%@ %#@and_number_of_others@\"")
        }
        /// You
        internal static let participantsYou = L10n.tr("Localizable", "content.system.participants_you", fallback: "You")
        /// Sending…
        internal static let pendingMessageTimestamp = L10n.tr("Localizable", "content.system.pending_message_timestamp", fallback: "Sending…")
        /// Plural format key: "%@%#@d_number_of_others@ started using %#@d_new_devices@"
        internal static func peopleStartedUsing(_ p1: Any, _ p2: Int, _ p3: Int) -> String {
          return L10n.tr("Localizable", "content.system.people_started_using", String(describing: p1), p2, p3, fallback: "Plural format key: \"%@%#@d_number_of_others@ started using %#@d_new_devices@\"")
        }
        /// You started using [a new device](%@)
        internal static func selfUserNewClient(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.self_user_new_client", String(describing: p1), fallback: "You started using [a new device](%@)")
        }
        /// You unverified one of [%1$@’s devices](%2$@)
        internal static func unverifiedOtherDevices(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.unverified_other_devices", String(describing: p1), String(describing: p2), fallback: "You unverified one of [%1$@’s devices](%2$@)")
        }
        /// You unverified one of [your devices](%@)
        internal static func unverifiedSelfDevices(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.unverified_self_devices", String(describing: p1), fallback: "You unverified one of [your devices](%@)")
        }
        /// Verify devices
        internal static let verifyDevices = L10n.tr("Localizable", "content.system.verify_devices", fallback: "Verify devices")
        /// you
        internal static let youAccusative = L10n.tr("Localizable", "content.system.you_accusative", fallback: "you")
        /// You added %@
        internal static func youAddedParticipant(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.you_added_participant", String(describing: p1), fallback: "You added %@")
        }
        /// you
        internal static let youDative = L10n.tr("Localizable", "content.system.you_dative", fallback: "you")
        /// You left
        internal static let youLeft = L10n.tr("Localizable", "content.system.you_left", fallback: "You left")
        /// you
        internal static let youNominative = L10n.tr("Localizable", "content.system.you_nominative", fallback: "you")
        /// You removed %@
        internal static func youRemovedOther(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.you_removed_other", String(describing: p1), fallback: "You removed %@")
        }
        /// You removed the conversation name
        internal static let youRenamedConvToNothing = L10n.tr("Localizable", "content.system.you_renamed_conv_to_nothing", fallback: "You removed the conversation name")
        /// You
        internal static let youStarted = L10n.tr("Localizable", "content.system.you_started", fallback: "You")
        /// You started a conversation with %@
        internal static func youStartedConversation(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.you_started_conversation", String(describing: p1), fallback: "You started a conversation with %@")
        }
        /// You called
        internal static let youWantedToTalk = L10n.tr("Localizable", "content.system.you_wanted_to_talk", fallback: "You called")
        internal enum BackendsStopFederating {
          /// The backends **%@** and **%@** stopped federating. [Learn more](%@)
          internal static func otherBackends(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
            return L10n.tr("Localizable", "content.system.backends_stop_federating.other_backends", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "The backends **%@** and **%@** stopped federating. [Learn more](%@)")
          }
          /// **Your backend** stopped federating with **%@**. [Learn more](%@)
          internal static func selfBackend(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "content.system.backends_stop_federating.self_backend", String(describing: p1), String(describing: p2), fallback: "**Your backend** stopped federating with **%@**. [Learn more](%@)")
          }
        }
        internal enum Call {
          /// Plural format key: "%#@missed_call@"
          internal static func missedCall(_ p1: Int) -> String {
            return L10n.tr("Localizable", "content.system.call.missed-call", p1, fallback: "Plural format key: \"%#@missed_call@\"")
          }
          internal enum MissedCall {
            /// Plural format key: "%#@missed_call_from@"
            internal static func groups(_ p1: Int) -> String {
              return L10n.tr("Localizable", "content.system.call.missed-call.groups", p1, fallback: "Plural format key: \"%#@missed_call_from@\"")
            }
          }
        }
        internal enum CannotDecrypt {
          /// (Fixed error: %d ID: %@)
          internal static func errorDetails(_ p1: Int, _ p2: Any) -> String {
            return L10n.tr("Localizable", "content.system.cannot_decrypt.error_details", p1, String(describing: p2), fallback: "(Fixed error: %d ID: %@)")
          }
          /// A message from %@ could not be decrypted.
          internal static func other(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.cannot_decrypt.other", String(describing: p1), fallback: "A message from %@ could not be decrypted.")
          }
          /// Fix future messages
          internal static let resetSession = L10n.tr("Localizable", "content.system.cannot_decrypt.reset_session", fallback: "Fix future messages")
          /// A message from you could not be decrypted.
          internal static let `self` = L10n.tr("Localizable", "content.system.cannot_decrypt.self", fallback: "A message from you could not be decrypted.")
        }
        internal enum CannotDecryptIdentityChanged {
          /// %@’s device identity changed. Undelivered message.
          internal static func other(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.cannot_decrypt_identity_changed.other", String(describing: p1), fallback: "%@’s device identity changed. Undelivered message.")
          }
          /// Your device identity changed. Undelivered message.
          internal static let `self` = L10n.tr("Localizable", "content.system.cannot_decrypt_identity_changed.self", fallback: "Your device identity changed. Undelivered message.")
        }
        internal enum CannotDecryptResolved {
          /// You can now decrypt messages from %1$@. To recover lost messages, ask %1$@ to resend them.
          internal static func other(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.cannot_decrypt_resolved.other", String(describing: p1), fallback: "You can now decrypt messages from %1$@. To recover lost messages, ask %1$@ to resend them.")
          }
          /// You can now decrypt messages from yourself. To recover lost messages, you need to resend them.
          internal static let `self` = L10n.tr("Localizable", "content.system.cannot_decrypt_resolved.self", fallback: "You can now decrypt messages from yourself. To recover lost messages, you need to resend them.")
        }
        internal enum Conversation {
          internal enum Guest {
            /// %@ joined
            internal static func joined(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.guest.joined", String(describing: p1), fallback: "%@ joined")
            }
            /// You joined
            internal static let youJoined = L10n.tr("Localizable", "content.system.conversation.guest.you_joined", fallback: "You joined")
          }
          internal enum Invite {
            /// Invite people
            internal static let button = L10n.tr("Localizable", "content.system.conversation.invite.button", fallback: "Invite people")
            /// People outside your team can join this conversation.
            internal static let title = L10n.tr("Localizable", "content.system.conversation.invite.title", fallback: "People outside your team can join this conversation.")
          }
          internal enum Other {
            /// %@ added %@
            internal static func added(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.other.added", String(describing: p1), String(describing: p2), fallback: "%@ added %@")
            }
            /// %@ left
            internal static func `left`(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.other.left", String(describing: p1), fallback: "%@ left")
            }
            /// %@ removed %@
            internal static func removed(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.other.removed", String(describing: p1), String(describing: p2), fallback: "%@ removed %@")
            }
            /// %@ started a conversation with %@
            internal static func started(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.other.started", String(describing: p1), String(describing: p2), fallback: "%@ started a conversation with %@")
            }
            internal enum Removed {
              /// %@ was removed from this conversation because legal hold has been activated.
              internal static func legalhold(_ p1: Any) -> String {
                return L10n.tr("Localizable", "content.system.conversation.other.removed.legalhold", String(describing: p1), fallback: "%@ was removed from this conversation because legal hold has been activated.")
              }
            }
          }
          internal enum Others {
            internal enum Removed {
              /// %@ were removed from this conversation because legal hold has been activated.
              internal static func legalhold(_ p1: Any) -> String {
                return L10n.tr("Localizable", "content.system.conversation.others.removed.legalhold", String(describing: p1), fallback: "%@ were removed from this conversation because legal hold has been activated.")
              }
            }
          }
          internal enum Team {
            /// %@ was removed from the team.
            internal static func memberLeave(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.team.member-leave", String(describing: p1), fallback: "%@ was removed from the team.")
            }
          }
          internal enum WithName {
            /// with
            internal static let participants = L10n.tr("Localizable", "content.system.conversation.with_name.participants", fallback: "with")
            /// %@ started the conversation
            internal static func title(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.with_name.title", String(describing: p1), fallback: "%@ started the conversation")
            }
            /// %@ started the conversation
            internal static func titleYou(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.with_name.title-you", String(describing: p1), fallback: "%@ started the conversation")
            }
          }
          internal enum You {
            /// %@ added %@
            internal static func added(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.you.added", String(describing: p1), String(describing: p2), fallback: "%@ added %@")
            }
            /// %@ left
            internal static func `left`(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.you.left", String(describing: p1), fallback: "%@ left")
            }
            /// %@ removed %@
            internal static func removed(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.you.removed", String(describing: p1), String(describing: p2), fallback: "%@ removed %@")
            }
            /// %@ started a conversation with %@
            internal static func started(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.you.started", String(describing: p1), String(describing: p2), fallback: "%@ started a conversation with %@")
            }
            internal enum Removed {
              /// %@ were removed from this conversation because legal hold has been activated.
              internal static func legalhold(_ p1: Any) -> String {
                return L10n.tr("Localizable", "content.system.conversation.you.removed.legalhold", String(describing: p1), fallback: "%@ were removed from this conversation because legal hold has been activated.")
              }
            }
          }
        }
        internal enum FailedParticipants {
          /// Learn more
          internal static let learnMore = L10n.tr("Localizable", "content.system.failed_participants.learn_more", fallback: "Learn more")
        }
        internal enum FailedtoaddParticipants {
          /// Plural format key: "%#@number_of_users@"
          internal static func couldNotBeAdded(_ p1: Int) -> String {
            return L10n.tr("Localizable", "content.system.failedtoadd_participants.could_not_be_added", p1, fallback: "Plural format key: \"%#@number_of_users@\"")
          }
          /// **%@ participants** could not be added to the group.
          internal static func count(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.failedtoadd_participants.count", String(describing: p1), fallback: "**%@ participants** could not be added to the group.")
          }
        }
        internal enum FailedtosendMessage {
          /// Message could not be sent as the backend of **%@** could not be reached. [Learn more](%@)
          internal static func federationRemoteErrorReason(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "content.system.failedtosend_message.federation_remote_error_reason", String(describing: p1), String(describing: p2), fallback: "Message could not be sent as the backend of **%@** could not be reached. [Learn more](%@)")
          }
          /// Message could not be sent due to connectivity issues.
          internal static let generalReason = L10n.tr("Localizable", "content.system.failedtosend_message.general_reason", fallback: "Message could not be sent due to connectivity issues.")
          /// Retry
          internal static let retry = L10n.tr("Localizable", "content.system.failedtosend_message.retry", fallback: "Retry")
          /// Message not sent as you canceled the upload.
          internal static let userCancelledUploadReason = L10n.tr("Localizable", "content.system.failedtosend_message.user_cancelled_upload_reason", fallback: "Message not sent as you canceled the upload.")
        }
        internal enum FailedtosendParticipants {
          /// Plural format key: "%#@lu_number_of_participants@"
          internal static func count(_ p1: Int) -> String {
            return L10n.tr("Localizable", "content.system.failedtosend_participants.count", p1, fallback: "Plural format key: \"%#@lu_number_of_participants@\"")
          }
          /// **%@ participants** didn’t get your message.
          internal static func didNotGetMessage(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.failedtosend_participants.did_not_get_message", String(describing: p1), fallback: "**%@ participants** didn’t get your message.")
          }
          /// **%@ from %@**
          internal static func from(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "content.system.failedtosend_participants.from", String(describing: p1), String(describing: p2), fallback: "**%@ from %@**")
          }
          /// Hide Details
          internal static let hideDetails = L10n.tr("Localizable", "content.system.failedtosend_participants.hide_details", fallback: "Hide Details")
          /// Show Details
          internal static let showDetails = L10n.tr("Localizable", "content.system.failedtosend_participants.show_details", fallback: "Show Details")
          /// Plural format key: "%#@number_of_users@"
          internal static func willGetMessageLater(_ p1: Int) -> String {
            return L10n.tr("Localizable", "content.system.failedtosend_participants.will_get_message_later", p1, fallback: "Plural format key: \"%#@number_of_users@\"")
          }
          /// Plural format key: "%#@number_of_users@"
          internal static func willNeverGetMessage(_ p1: Int) -> String {
            return L10n.tr("Localizable", "content.system.failedtosend_participants.will_never_get_message", p1, fallback: "Plural format key: \"%#@number_of_users@\"")
          }
        }
        internal enum FederationTermination {
          /// Plural format key: "%#@lu_number_of_participants@"
          internal static func participantsRemoved(_ p1: Int) -> String {
            return L10n.tr("Localizable", "content.system.federation_termination.participants_removed", p1, fallback: "Plural format key: \"%#@lu_number_of_participants@\"")
          }
        }
        internal enum MessageLegalHold {
          /// Legal hold deactivated for this conversation
          internal static let disabled = L10n.tr("Localizable", "content.system.message_legal_hold.disabled", fallback: "Legal hold deactivated for this conversation")
          /// This conversation is under legal hold [LEARN MORE](%@)
          internal static func enabled(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.message_legal_hold.enabled", String(describing: p1), fallback: "This conversation is under legal hold [LEARN MORE](%@)")
          }
          /// Learn more
          internal static let learnMore = L10n.tr("Localizable", "content.system.message_legal_hold.learn_more", fallback: "Learn more")
        }
        internal enum MissingMessages {
          internal enum UsersAdded {
            /// You haven’t used this device for a while. Some messages may not appear here.
            /// 
            /// Meanwhile, %@ have been added.
            internal static func plural(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.missing_messages.users_added.plural", String(describing: p1), fallback: "You haven’t used this device for a while. Some messages may not appear here.\n\nMeanwhile, %@ have been added.")
            }
            /// You haven’t used this device for a while. Some messages may not appear here.
            /// 
            /// Meanwhile, %@ has been added.
            internal static func singular(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.missing_messages.users_added.singular", String(describing: p1), fallback: "You haven’t used this device for a while. Some messages may not appear here.\n\nMeanwhile, %@ has been added.")
            }
          }
          internal enum UsersAddedAndRemoved {
            /// You haven’t used this device for a while. Some messages may not appear here.
            /// 
            /// Meanwhile, %1$@ have been added. %2$@ have been removed.
            internal static func plural(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.missing_messages.users_added_and_removed.plural", String(describing: p1), String(describing: p2), fallback: "You haven’t used this device for a while. Some messages may not appear here.\n\nMeanwhile, %1$@ have been added. %2$@ have been removed.")
            }
            /// You haven’t used this device for a while. Some messages may not appear here.
            /// 
            /// Meanwhile, %1$@ have been added. %2$@ has been removed.
            internal static func pluralSingular(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.missing_messages.users_added_and_removed.plural_singular", String(describing: p1), String(describing: p2), fallback: "You haven’t used this device for a while. Some messages may not appear here.\n\nMeanwhile, %1$@ have been added. %2$@ has been removed.")
            }
            /// You haven’t used this device for a while. Some messages may not appear here.
            /// 
            /// Meanwhile, %1$@ has been added. %2$@ has been removed.
            internal static func singular(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.missing_messages.users_added_and_removed.singular", String(describing: p1), String(describing: p2), fallback: "You haven’t used this device for a while. Some messages may not appear here.\n\nMeanwhile, %1$@ has been added. %2$@ has been removed.")
            }
            /// You haven’t used this device for a while. Some messages may not appear here.
            /// 
            /// Meanwhile, %1$@ has been added. %2$@ have been removed.
            internal static func singularPlural(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.missing_messages.users_added_and_removed.singular_plural", String(describing: p1), String(describing: p2), fallback: "You haven’t used this device for a while. Some messages may not appear here.\n\nMeanwhile, %1$@ has been added. %2$@ have been removed.")
            }
          }
          internal enum UsersRemoved {
            /// You haven’t used this device for a while. Some messages may not appear here.
            /// 
            /// Meanwhile, %@ have been removed.
            internal static func plural(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.missing_messages.users_removed.plural", String(describing: p1), fallback: "You haven’t used this device for a while. Some messages may not appear here.\n\nMeanwhile, %@ have been removed.")
            }
            /// You haven’t used this device for a while. Some messages may not appear here.
            /// 
            /// Meanwhile, %@ has been removed.
            internal static func singular(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.missing_messages.users_removed.singular", String(describing: p1), fallback: "You haven’t used this device for a while. Some messages may not appear here.\n\nMeanwhile, %@ has been removed.")
            }
          }
        }
        internal enum Mls {
          /// This conversation is no longer verified, as at least one participant started using a new device or has an invalid certificate.
          internal static let conversationIsDegraded = L10n.tr("Localizable", "content.system.mls.conversation_is_degraded", fallback: "This conversation is no longer verified, as at least one participant started using a new device or has an invalid certificate.")
          /// All devices are verified by End-to-end Identity. [Learn more](%@)
          internal static func conversationIsVerified(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.mls.conversation_is_verified", String(describing: p1), fallback: "All devices are verified by End-to-end Identity. [Learn more](%@)")
          }
        }
        internal enum MlsMigration {
          /// You haven’t updated this device for a while. In the meantime, the standard messaging protocol changed from Proteus to Messaging Layer Security (MLS). Due to this change, some messages may not appear here.
          internal static let joinAfterwards = L10n.tr("Localizable", "content.system.mls_migration.join_afterwards", fallback: "You haven’t updated this device for a while. In the meantime, the standard messaging protocol changed from Proteus to Messaging Layer Security (MLS). Due to this change, some messages may not appear here.")
          /// Learn more about MLS
          internal static let learnMore = L10n.tr("Localizable", "content.system.mls_migration.learn_more", fallback: "Learn more about MLS")
          /// You can't communicate with %@ anymore, as you two now use different protocols. When %@ gets an update, you can call and send messages and files again.
          internal static func mlsNotSupportedByOtherUser(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "content.system.mls_migration.mls_not_supported_by_otherUser", String(describing: p1), String(describing: p2), fallback: "You can't communicate with %@ anymore, as you two now use different protocols. When %@ gets an update, you can call and send messages and files again.")
          }
          /// You can’t communicate with %@ anymore, as your device doesn’t support the suitable protocol. [**Download the latest MLS Wire version**](%@) to call, and send messages and files again.
          internal static func mlsNotSupportedByYou(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "content.system.mls_migration.mls_not_supported_by_you", String(describing: p1), String(describing: p2), fallback: "You can’t communicate with %@ anymore, as your device doesn’t support the suitable protocol. [**Download the latest MLS Wire version**](%@) to call, and send messages and files again.")
          }
          /// Due to migration to MLS, you might have issues with your current call. If that's the case, hang up and call again.
          internal static let ongoingCall = L10n.tr("Localizable", "content.system.mls_migration.ongoing_call", fallback: "Due to migration to MLS, you might have issues with your current call. If that's the case, hang up and call again.")
          /// You haven’t updated this device for a while. In the meantime, the standard messaging protocol changed from Proteus to Messaging Layer Security (MLS). Due to this change, some messages may not appear here.
          internal static let potentialGap = L10n.tr("Localizable", "content.system.mls_migration.potentialGap", fallback: "You haven’t updated this device for a while. In the meantime, the standard messaging protocol changed from Proteus to Messaging Layer Security (MLS). Due to this change, some messages may not appear here.")
          internal enum Finalized {
            /// This conversation now uses the new Messaging Layer Security (MLS) protocol. To communicate seamlessly, always use the latest version of Wire on your devices.
            internal static let done = L10n.tr("Localizable", "content.system.mls_migration.finalized.done", fallback: "This conversation now uses the new Messaging Layer Security (MLS) protocol. To communicate seamlessly, always use the latest version of Wire on your devices.")
          }
          internal enum Started {
            /// The standard messaging protocol is changing from Proteus to the new Messaging Layer Security (MLS).
            internal static let description = L10n.tr("Localizable", "content.system.mls_migration.started.description", fallback: "The standard messaging protocol is changing from Proteus to the new Messaging Layer Security (MLS).")
            /// Ensure you use the latest version of Wire to be ready for MLS and continue communicating seamlessly.
            internal static let updateLatestVersion = L10n.tr("Localizable", "content.system.mls_migration.started.update_latest_version", fallback: "Ensure you use the latest version of Wire to be ready for MLS and continue communicating seamlessly.")
            /// Update Wire until %@ to be ready for MLS and continue communicating seamlessly.
            internal static func updateWithDate(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.mls_migration.started.update_with_date", String(describing: p1), fallback: "Update Wire until %@ to be ready for MLS and continue communicating seamlessly.")
            }
          }
        }
        internal enum RenamedConv {
          /// %@ renamed the conversation
          internal static func title(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.renamed_conv.title", String(describing: p1), fallback: "%@ renamed the conversation")
          }
          /// %@ renamed the conversation
          internal static func titleYou(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.renamed_conv.title-you", String(describing: p1), fallback: "%@ renamed the conversation")
          }
          internal enum Title {
            /// You
            internal static let you = L10n.tr("Localizable", "content.system.renamed_conv.title.you", fallback: "You")
          }
        }
        internal enum Services {
          /// Services have access to the content of this conversation
          internal static let warning = L10n.tr("Localizable", "content.system.services.warning", fallback: "Services have access to the content of this conversation")
        }
        internal enum SessionReset {
          /// %@ was unable to decrypt some of your messages but has solved the issue. This affected all conversations you share together.
          internal static func other(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.session_reset.other", String(describing: p1), fallback: "%@ was unable to decrypt some of your messages but has solved the issue. This affected all conversations you share together.")
          }
          /// You were unable to decrypt some of your messages but you solved the issue. This affected all conversations.
          internal static let `self` = L10n.tr("Localizable", "content.system.session_reset.self", fallback: "You were unable to decrypt some of your messages but you solved the issue. This affected all conversations.")
        }
        internal enum StartedConversation {
          /// all team members
          internal static let completeTeam = L10n.tr("Localizable", "content.system.started_conversation.complete_team", fallback: "all team members")
          /// and %@
          internal static func truncatedPeople(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.started_conversation.truncated_people", String(describing: p1), fallback: "and %@")
          }
          internal enum CompleteTeam {
            /// all team members and %@ guests
            internal static func guests(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.started_conversation.complete_team.guests", String(describing: p1), fallback: "all team members and %@ guests")
            }
          }
          internal enum TruncatedPeople {
            /// %@ others
            internal static func others(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.started_conversation.truncated_people.others", String(describing: p1), fallback: "%@ others")
            }
          }
        }
        internal enum UnknownMessage {
          /// This message can’t be displayed. You may be using an older version of Wire.
          internal static let body = L10n.tr("Localizable", "content.system.unknown_message.body", fallback: "This message can’t be displayed. You may be using an older version of Wire.")
        }
      }
    }
    internal enum Conversation {
      internal enum Action {
        /// Search
        internal static let search = L10n.tr("Localizable", "conversation.action.search", fallback: "Search")
      }
      internal enum Alert {
        /// The message is deleted.
        internal static let messageDeleted = L10n.tr("Localizable", "conversation.alert.message_deleted", fallback: "The message is deleted.")
      }
      internal enum Banner {
        /// %@ are active
        internal static func areActive(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.banner.are_active", String(describing: p1), fallback: "%@ are active")
        }
        /// %@ are present
        internal static func arePresent(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.banner.are_present", String(describing: p1), fallback: "%@ are present")
        }
        /// Externals
        internal static let externals = L10n.tr("Localizable", "conversation.banner.externals", fallback: "Externals")
        /// Guests
        internal static let guests = L10n.tr("Localizable", "conversation.banner.guests", fallback: "Guests")
        /// Federated users
        internal static let remotes = L10n.tr("Localizable", "conversation.banner.remotes", fallback: "Federated users")
        ///  and 
        internal static let separator = L10n.tr("Localizable", "conversation.banner.separator", fallback: " and ")
        /// Services
        internal static let services = L10n.tr("Localizable", "conversation.banner.services", fallback: "Services")
      }
      internal enum Call {
        internal enum ManyParticipantsConfirmation {
          /// Call
          internal static let call = L10n.tr("Localizable", "conversation.call.many_participants_confirmation.call", fallback: "Call")
          /// Are you sure you want to call %d people?
          internal static func title(_ p1: Int) -> String {
            return L10n.tr("Localizable", "conversation.call.many_participants_confirmation.title", p1, fallback: "Are you sure you want to call %d people?")
          }
        }
      }
      internal enum ConnectionView {
        /// Communication in Wire is always end-to-end encrypted. Everything you send and receive in this conversation is only accessible to you and your contact.
        internal static let encryptionInfo = L10n.tr("Localizable", "conversation.connection_view.encryption_info", fallback: "Communication in Wire is always end-to-end encrypted. Everything you send and receive in this conversation is only accessible to you and your contact.")
        /// in Contacts
        internal static let inAddressBook = L10n.tr("Localizable", "conversation.connection_view.in_address_book", fallback: "in Contacts")
        /// Please still be careful with who you share sensitive information.
        internal static let sensitiveInformationWarning = L10n.tr("Localizable", "conversation.connection_view.sensitive_information_warning", fallback: "Please still be careful with who you share sensitive information.")
      }
      internal enum Create {
        internal enum GroupName {
          /// Group name
          internal static let placeholder = L10n.tr("Localizable", "conversation.create.group_name.placeholder", fallback: "Group name")
          /// Create group
          internal static let title = L10n.tr("Localizable", "conversation.create.group_name.title", fallback: "Create group")
        }
        internal enum Guests {
          /// Open this conversation to people outside your team.
          internal static let subtitle = L10n.tr("Localizable", "conversation.create.guests.subtitle", fallback: "Open this conversation to people outside your team.")
          /// Allow guests
          internal static let title = L10n.tr("Localizable", "conversation.create.guests.title", fallback: "Allow guests")
        }
        internal enum Guidance {
          /// At least 1 character
          internal static let empty = L10n.tr("Localizable", "conversation.create.guidance.empty", fallback: "At least 1 character")
          /// Too many characters
          internal static let toolong = L10n.tr("Localizable", "conversation.create.guidance.toolong", fallback: "Too many characters")
        }
        internal enum Mls {
          /// Cancel
          internal static let cancel = L10n.tr("Localizable", "conversation.create.mls.cancel", fallback: "Cancel")
          /// Select Protocol
          internal static let pickerTitle = L10n.tr("Localizable", "conversation.create.mls.picker_title", fallback: "Select Protocol")
          /// Select MLS to create a group using the Messaging Layer Security protocol.
          internal static let subtitle = L10n.tr("Localizable", "conversation.create.mls.subtitle", fallback: "Select MLS to create a group using the Messaging Layer Security protocol.")
          /// Protocol
          internal static let title = L10n.tr("Localizable", "conversation.create.mls.title", fallback: "Protocol")
        }
        internal enum NonFederatingDomainsError {
          /// Discard Group Creation
          internal static let abort = L10n.tr("Localizable", "conversation.create.non_federating_domains_error.abort", fallback: "Discard Group Creation")
          /// Edit Participants List
          internal static let editParticipantList = L10n.tr("Localizable", "conversation.create.non_federating_domains_error.edit_participant_list", fallback: "Edit Participants List")
          /// Learn More
          internal static let learnMore = L10n.tr("Localizable", "conversation.create.non_federating_domains_error.learn_more", fallback: "Learn More")
          /// People from backends %@ can't join the same group conversation.
          /// To create the group, remove affected participants.
          internal static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation.create.non_federating_domains_error.message", String(describing: p1), fallback: "People from backends %@ can't join the same group conversation.\nTo create the group, remove affected participants.")
          }
          /// Group can't be created
          internal static let title = L10n.tr("Localizable", "conversation.create.non_federating_domains_error.title", fallback: "Group can't be created")
        }
        internal enum Options {
          /// Guests: %@, Services: %@, Read receipts: %@
          internal static func subtitle(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
            return L10n.tr("Localizable", "conversation.create.options.subtitle", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "Guests: %@, Services: %@, Read receipts: %@")
          }
          /// Conversation options
          internal static let title = L10n.tr("Localizable", "conversation.create.options.title", fallback: "Conversation options")
        }
        internal enum ProtocolSelection {
          /// MLS
          internal static let mls = L10n.tr("Localizable", "conversation.create.protocol_selection.mls", fallback: "MLS")
          /// MLS (default)
          internal static let mlsDefault = L10n.tr("Localizable", "conversation.create.protocol_selection.mls_default", fallback: "MLS (default)")
          /// Proteus
          internal static let proteus = L10n.tr("Localizable", "conversation.create.protocol_selection.proteus", fallback: "Proteus")
          /// Proteus (default)
          internal static let proteusDefault = L10n.tr("Localizable", "conversation.create.protocol_selection.proteus_default", fallback: "Proteus (default)")
        }
        internal enum Receipts {
          /// When this is on, people can see when their messages in this conversation are read.
          internal static let subtitle = L10n.tr("Localizable", "conversation.create.receipts.subtitle", fallback: "When this is on, people can see when their messages in this conversation are read.")
          /// Read receipts
          internal static let title = L10n.tr("Localizable", "conversation.create.receipts.title", fallback: "Read receipts")
        }
        internal enum Services {
          /// Open this conversation to services.
          internal static let subtitle = L10n.tr("Localizable", "conversation.create.services.subtitle", fallback: "Open this conversation to services.")
          /// Allow services
          internal static let title = L10n.tr("Localizable", "conversation.create.services.title", fallback: "Allow services")
        }
      }
      internal enum DeleteRequestDialog {
        /// This will delete the group and all content for all participants on all devices. There is no option to restore the content. All participants will be notified.
        internal static let message = L10n.tr("Localizable", "conversation.delete_request_dialog.message", fallback: "This will delete the group and all content for all participants on all devices. There is no option to restore the content. All participants will be notified.")
        /// Delete group conversation?
        internal static let title = L10n.tr("Localizable", "conversation.delete_request_dialog.title", fallback: "Delete group conversation?")
      }
      internal enum DeleteRequestErrorDialog {
        /// Delete Group
        internal static let buttonDeleteGroup = L10n.tr("Localizable", "conversation.delete_request_error_dialog.button_delete_group", fallback: "Delete Group")
        /// An error occurred while trying to delete the group %@. Please try again.
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.delete_request_error_dialog.title", String(describing: p1), fallback: "An error occurred while trying to delete the group %@. Please try again.")
        }
      }
      internal enum Displayname {
        /// Empty group conversation
        internal static let emptygroup = L10n.tr("Localizable", "conversation.displayname.emptygroup", fallback: "Empty group conversation")
      }
      internal enum InputBar {
        /// Cancel reply
        internal static let closeReply = L10n.tr("Localizable", "conversation.input_bar.close_reply", fallback: "Cancel reply")
        /// Type a message
        internal static let placeholder = L10n.tr("Localizable", "conversation.input_bar.placeholder", fallback: "Type a message")
        /// Self-deleting message
        internal static let placeholderEphemeral = L10n.tr("Localizable", "conversation.input_bar.placeholder_ephemeral", fallback: "Self-deleting message")
        /// Verified
        internal static let verified = L10n.tr("Localizable", "conversation.input_bar.verified", fallback: "Verified")
        internal enum AudioMessage {
          /// Send
          internal static let send = L10n.tr("Localizable", "conversation.input_bar.audio_message.send", fallback: "Send")
          internal enum Keyboard {
            /// Choose a filter above
            internal static let filterTip = L10n.tr("Localizable", "conversation.input_bar.audio_message.keyboard.filter_tip", fallback: "Choose a filter above")
            /// Tap to record
            /// You can  %@  it after that
            internal static func recordTip(_ p1: Any) -> String {
              return L10n.tr("Localizable", "conversation.input_bar.audio_message.keyboard.record_tip", String(describing: p1), fallback: "Tap to record\nYou can  %@  it after that")
            }
          }
          internal enum TooLong {
            /// Audio messages are limited to %@.
            internal static func message(_ p1: Any) -> String {
              return L10n.tr("Localizable", "conversation.input_bar.audio_message.too_long.message", String(describing: p1), fallback: "Audio messages are limited to %@.")
            }
            /// Recording Stopped
            internal static let title = L10n.tr("Localizable", "conversation.input_bar.audio_message.too_long.title", fallback: "Recording Stopped")
          }
          internal enum TooLongSize {
            /// File size for audio messages is limited to %@.
            internal static func message(_ p1: Any) -> String {
              return L10n.tr("Localizable", "conversation.input_bar.audio_message.too_long_size.message", String(describing: p1), fallback: "File size for audio messages is limited to %@.")
            }
          }
          internal enum Tooltip {
            /// Swipe up to send
            internal static let pullSend = L10n.tr("Localizable", "conversation.input_bar.audio_message.tooltip.pull_send", fallback: "Swipe up to send")
            /// Tap to send
            internal static let tapSend = L10n.tr("Localizable", "conversation.input_bar.audio_message.tooltip.tap_send", fallback: "Tap to send")
          }
        }
        internal enum MessagePreview {
          /// Replying to message: %@
          internal static func accessibilityDescription(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility_description", String(describing: p1), fallback: "Replying to message: %@")
          }
          /// Audio Message
          internal static let audio = L10n.tr("Localizable", "conversation.input_bar.message_preview.audio", fallback: "Audio Message")
          /// File
          internal static let file = L10n.tr("Localizable", "conversation.input_bar.message_preview.file", fallback: "File")
          /// Image
          internal static let image = L10n.tr("Localizable", "conversation.input_bar.message_preview.image", fallback: "Image")
          /// Location
          internal static let location = L10n.tr("Localizable", "conversation.input_bar.message_preview.location", fallback: "Location")
          /// Video
          internal static let video = L10n.tr("Localizable", "conversation.input_bar.message_preview.video", fallback: "Video")
          internal enum Accessibility {
            /// Audio message
            internal static let audioMessage = L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.audio_message", fallback: "Audio message")
            /// File message (%@)
            internal static func fileMessage(_ p1: Any) -> String {
              return L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.file_message", String(describing: p1), fallback: "File message (%@)")
            }
            /// Image message
            internal static let imageMessage = L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.image_message", fallback: "Image message")
            /// Location message
            internal static let locationMessage = L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.location_message", fallback: "Location message")
            /// %@ from %@
            internal static func messageFrom(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.message_from", String(describing: p1), String(describing: p2), fallback: "%@ from %@")
            }
            /// Unknown message
            internal static let unknownMessage = L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.unknown_message", fallback: "Unknown message")
            /// Video message
            internal static let videoMessage = L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.video_message", fallback: "Video message")
          }
        }
        internal enum MessageTooLong {
          /// You can send messages up to %d characters long.
          internal static func message(_ p1: Int) -> String {
            return L10n.tr("Localizable", "conversation.input_bar.message_too_long.message", p1, fallback: "You can send messages up to %d characters long.")
          }
          /// Message too long
          internal static let title = L10n.tr("Localizable", "conversation.input_bar.message_too_long.title", fallback: "Message too long")
        }
        internal enum OngoingCallAlert {
          /// Ongoing call
          internal static let title = L10n.tr("Localizable", "conversation.input_bar.ongoing_call_alert.title", fallback: "Ongoing call")
          internal enum Audio {
            /// You can’t record an audio message during a call.
            internal static let message = L10n.tr("Localizable", "conversation.input_bar.ongoing_call_alert.audio.message", fallback: "You can’t record an audio message during a call.")
          }
          internal enum Photo {
            /// You can’t take a picture during a call.
            internal static let message = L10n.tr("Localizable", "conversation.input_bar.ongoing_call_alert.photo.message", fallback: "You can’t take a picture during a call.")
          }
          internal enum Video {
            /// You can’t record a video during a call.
            internal static let message = L10n.tr("Localizable", "conversation.input_bar.ongoing_call_alert.video.message", fallback: "You can’t record a video during a call.")
          }
        }
        internal enum Shortcut {
          /// Cancel
          internal static let cancelEditingMessage = L10n.tr("Localizable", "conversation.input_bar.shortcut.cancel_editing_message", fallback: "Cancel")
          /// Choose next mention
          internal static let chooseNextMention = L10n.tr("Localizable", "conversation.input_bar.shortcut.choose_next_mention", fallback: "Choose next mention")
          /// Choose previous mention
          internal static let choosePreviousMention = L10n.tr("Localizable", "conversation.input_bar.shortcut.choose_previous_mention", fallback: "Choose previous mention")
          /// Edit Last Message
          internal static let editLastMessage = L10n.tr("Localizable", "conversation.input_bar.shortcut.edit_last_message", fallback: "Edit Last Message")
          /// Insert Line Break
          internal static let newline = L10n.tr("Localizable", "conversation.input_bar.shortcut.newline", fallback: "Insert Line Break")
          /// Send Message
          internal static let send = L10n.tr("Localizable", "conversation.input_bar.shortcut.send", fallback: "Send Message")
        }
      }
      internal enum InviteMorePeople {
        /// Add People
        internal static let buttonTitle = L10n.tr("Localizable", "conversation.invite_more_people.button_title", fallback: "Add People")
        /// Add people to this conversation
        internal static let description = L10n.tr("Localizable", "conversation.invite_more_people.description", fallback: "Add people to this conversation")
        /// https://support.wire.com
        internal static let explanationUrl = L10n.tr("Localizable", "conversation.invite_more_people.explanation_url", fallback: "https://support.wire.com")
        /// Spread the word!
        internal static let title = L10n.tr("Localizable", "conversation.invite_more_people.title", fallback: "Spread the word!")
      }
      internal enum Ping {
        internal enum Action {
          /// Ping
          internal static let title = L10n.tr("Localizable", "conversation.ping.action.title", fallback: "Ping")
        }
        internal enum ManyParticipantsConfirmation {
          /// Are you sure you want to ping %d people?
          internal static func title(_ p1: Int) -> String {
            return L10n.tr("Localizable", "conversation.ping.many_participants_confirmation.title", p1, fallback: "Are you sure you want to ping %d people?")
          }
        }
      }
      internal enum Silenced {
        internal enum Status {
          internal enum Message {
            /// Plural format key: "%#@d_number_of_new@"
            internal static func genericMessage(_ p1: Int) -> String {
              return L10n.tr("Localizable", "conversation.silenced.status.message.generic_message", p1, fallback: "Plural format key: \"%#@d_number_of_new@\"")
            }
            /// Plural format key: "%#@d_number_of_new@"
            internal static func knock(_ p1: Int) -> String {
              return L10n.tr("Localizable", "conversation.silenced.status.message.knock", p1, fallback: "Plural format key: \"%#@d_number_of_new@\"")
            }
            /// Plural format key: "%#@d_number_of_new@"
            internal static func mention(_ p1: Int) -> String {
              return L10n.tr("Localizable", "conversation.silenced.status.message.mention", p1, fallback: "Plural format key: \"%#@d_number_of_new@\"")
            }
            /// Plural format key: "%#@d_number_of_new@"
            internal static func missedcall(_ p1: Int) -> String {
              return L10n.tr("Localizable", "conversation.silenced.status.message.missedcall", p1, fallback: "Plural format key: \"%#@d_number_of_new@\"")
            }
            /// Plural format key: "%#@d_number_of_new@"
            internal static func reply(_ p1: Int) -> String {
              return L10n.tr("Localizable", "conversation.silenced.status.message.reply", p1, fallback: "Plural format key: \"%#@d_number_of_new@\"")
            }
          }
        }
      }
      internal enum Status {
        /// Blocked
        internal static let blocked = L10n.tr("Localizable", "conversation.status.blocked", fallback: "Blocked")
        /// %@ is calling…
        internal static func incomingCall(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.status.incoming_call", String(describing: p1), fallback: "%@ is calling…")
        }
        /// Poor connection
        internal static let poorConnection = L10n.tr("Localizable", "conversation.status.poor_connection", fallback: "Poor connection")
        /// Muted
        internal static let silenced = L10n.tr("Localizable", "conversation.status.silenced", fallback: "Muted")
        /// Someone
        internal static let someone = L10n.tr("Localizable", "conversation.status.someone", fallback: "Someone")
        /// %@ started a conversation
        internal static func startedConversation(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.status.started_conversation", String(describing: p1), fallback: "%@ started a conversation")
        }
        /// Typing a message…
        internal static let typing = L10n.tr("Localizable", "conversation.status.typing", fallback: "Typing a message…")
        /// ⚠️ Unsent message
        internal static let unsent = L10n.tr("Localizable", "conversation.status.unsent", fallback: "⚠️ Unsent message")
        /// You
        internal static let you = L10n.tr("Localizable", "conversation.status.you", fallback: "You")
        /// You left
        internal static let youLeft = L10n.tr("Localizable", "conversation.status.you_left", fallback: "You left")
        /// %@ added you
        internal static func youWasAdded(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.status.you_was_added", String(describing: p1), fallback: "%@ added you")
        }
        /// You were removed
        internal static let youWereRemoved = L10n.tr("Localizable", "conversation.status.you_were_removed", fallback: "You were removed")
        internal enum IncomingCall {
          /// Someone is calling…
          internal static let unknown = L10n.tr("Localizable", "conversation.status.incoming_call.unknown", fallback: "Someone is calling…")
        }
        internal enum Message {
          /// Shared an audio message
          internal static let audio = L10n.tr("Localizable", "conversation.status.message.audio", fallback: "Shared an audio message")
          /// Sent a message
          internal static let ephemeral = L10n.tr("Localizable", "conversation.status.message.ephemeral", fallback: "Sent a message")
          /// Shared a file
          internal static let file = L10n.tr("Localizable", "conversation.status.message.file", fallback: "Shared a file")
          /// Shared a picture
          internal static let image = L10n.tr("Localizable", "conversation.status.message.image", fallback: "Shared a picture")
          /// Pinged
          internal static let knock = L10n.tr("Localizable", "conversation.status.message.knock", fallback: "Pinged")
          /// Shared a link
          internal static let link = L10n.tr("Localizable", "conversation.status.message.link", fallback: "Shared a link")
          /// Shared a location
          internal static let location = L10n.tr("Localizable", "conversation.status.message.location", fallback: "Shared a location")
          /// %@
          internal static func mention(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation.status.message.mention", String(describing: p1), fallback: "%@")
          }
          /// Missed call
          internal static let missedcall = L10n.tr("Localizable", "conversation.status.message.missedcall", fallback: "Missed call")
          /// %@
          internal static func reply(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation.status.message.reply", String(describing: p1), fallback: "%@")
          }
          /// %@
          internal static func text(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation.status.message.text", String(describing: p1), fallback: "%@")
          }
          /// Shared a video
          internal static let video = L10n.tr("Localizable", "conversation.status.message.video", fallback: "Shared a video")
          internal enum Ephemeral {
            /// Someone sent a message
            internal static let group = L10n.tr("Localizable", "conversation.status.message.ephemeral.group", fallback: "Someone sent a message")
            /// Pinged
            internal static let knock = L10n.tr("Localizable", "conversation.status.message.ephemeral.knock", fallback: "Pinged")
            /// Mentioned you
            internal static let mention = L10n.tr("Localizable", "conversation.status.message.ephemeral.mention", fallback: "Mentioned you")
            /// Replied to your message
            internal static let reply = L10n.tr("Localizable", "conversation.status.message.ephemeral.reply", fallback: "Replied to your message")
            internal enum Knock {
              /// Someone pinged
              internal static let group = L10n.tr("Localizable", "conversation.status.message.ephemeral.knock.group", fallback: "Someone pinged")
            }
            internal enum Mention {
              /// Someone mentioned you
              internal static let group = L10n.tr("Localizable", "conversation.status.message.ephemeral.mention.group", fallback: "Someone mentioned you")
            }
            internal enum Reply {
              /// Someone replied to your message
              internal static let group = L10n.tr("Localizable", "conversation.status.message.ephemeral.reply.group", fallback: "Someone replied to your message")
            }
          }
          internal enum Missedcall {
            /// Missed call from %@
            internal static func groups(_ p1: Any) -> String {
              return L10n.tr("Localizable", "conversation.status.message.missedcall.groups", String(describing: p1), fallback: "Missed call from %@")
            }
          }
        }
        internal enum SecutityAlert {
          /// New security alert
          internal static let `default` = L10n.tr("Localizable", "conversation.status.secutity_alert.default", fallback: "New security alert")
        }
        internal enum Typing {
          /// %@: typing a message…
          internal static func group(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation.status.typing.group", String(describing: p1), fallback: "%@: typing a message…")
          }
        }
      }
      internal enum Voiceover {
        internal enum Value {
          /// active
          internal static let active = L10n.tr("Localizable", "conversation.voiceover.value.active", fallback: "active")
          /// disabled
          internal static let disabled = L10n.tr("Localizable", "conversation.voiceover.value.disabled", fallback: "disabled")
        }
      }
    }
    internal enum ConversationList {
      internal enum Empty {
        internal enum AllArchived {
          /// Everything archived
          internal static let message = L10n.tr("Localizable", "conversation_list.empty.all_archived.message", fallback: "Everything archived")
        }
        internal enum NoContacts {
          /// Start a conversation or
          /// create a group.
          internal static let message = L10n.tr("Localizable", "conversation_list.empty.no_contacts.message", fallback: "Start a conversation or\ncreate a group.")
        }
      }
      internal enum Header {
        internal enum SelfTeam {
          /// %@ account.
          internal static func accessibilityValue(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation_list.header.self_team.accessibility_value", String(describing: p1), fallback: "%@ account.")
          }
          internal enum AccessibilityValue {
            /// Active now.
            internal static let active = L10n.tr("Localizable", "conversation_list.header.self_team.accessibility_value.active", fallback: "Active now.")
            /// Has new messages.
            internal static let hasNewMessages = L10n.tr("Localizable", "conversation_list.header.self_team.accessibility_value.has_new_messages", fallback: "Has new messages.")
            /// Tap to activate.
            internal static let inactive = L10n.tr("Localizable", "conversation_list.header.self_team.accessibility_value.inactive", fallback: "Tap to activate.")
          }
        }
      }
      internal enum RightAccessory {
        internal enum JoinButton {
          /// Join
          internal static let title = L10n.tr("Localizable", "conversation_list.right_accessory.join_button.title", fallback: "Join")
        }
      }
      internal enum Voiceover {
        internal enum BottomBar {
          internal enum CameraButton {
            /// take picture and send quickly
            internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.camera_button.hint", fallback: "take picture and send quickly")
            /// camera
            internal static let label = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.camera_button.label", fallback: "camera")
          }
          internal enum ComposeButton {
            /// compose messages and save for later
            internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.compose_button.hint", fallback: "compose messages and save for later")
            /// compose
            internal static let label = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.compose_button.label", fallback: "compose")
          }
        }
        internal enum OpenConversation {
          /// Open conversation
          internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.open_conversation.hint", fallback: "Open conversation")
        }
        internal enum Status {
          /// active call
          internal static let activeCall = L10n.tr("Localizable", "conversation_list.voiceover.status.active_call", fallback: "active call")
          /// missed call
          internal static let missedCall = L10n.tr("Localizable", "conversation_list.voiceover.status.missed_call", fallback: "missed call")
          /// pause media
          internal static let pauseMedia = L10n.tr("Localizable", "conversation_list.voiceover.status.pause_media", fallback: "pause media")
          /// pending
          internal static let pendingConnection = L10n.tr("Localizable", "conversation_list.voiceover.status.pending_connection", fallback: "pending")
          /// ping
          internal static let ping = L10n.tr("Localizable", "conversation_list.voiceover.status.ping", fallback: "ping")
          /// play media
          internal static let playMedia = L10n.tr("Localizable", "conversation_list.voiceover.status.play_media", fallback: "play media")
          /// typing
          internal static let typing = L10n.tr("Localizable", "conversation_list.voiceover.status.typing", fallback: "typing")
        }
        internal enum UnreadMessages {
          /// You have unread messages.
          internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.unread_messages.hint", fallback: "You have unread messages.")
        }
      }
    }
    internal enum CreatePasscode {
      /// The app will lock itself after a certain time of inactivity. To unlock the app you need to enter this passcode. Make sure to remember it as there is no way to recover.
      internal static let infoLabel = L10n.tr("Localizable", "create_passcode.info_label", fallback: "The app will lock itself after a certain time of inactivity. To unlock the app you need to enter this passcode. Make sure to remember it as there is no way to recover.")
      /// The app will lock itself after a certain time of inactivity. To unlock the app you need to enter this passcode. Make sure to remember it as there is no way to recover.
      internal static let infoLabelForcedApplock = L10n.tr("Localizable", "create_passcode.info_label_forced_applock", fallback: "The app will lock itself after a certain time of inactivity. To unlock the app you need to enter this passcode. Make sure to remember it as there is no way to recover.")
      /// Set a passcode
      internal static let titleLabel = L10n.tr("Localizable", "create_passcode.title_label", fallback: "Set a passcode")
      internal enum CreateButton {
        /// Set a Passcode
        internal static let title = L10n.tr("Localizable", "create_passcode.create_button.title", fallback: "Set a Passcode")
      }
      internal enum Textfield {
        /// 
        internal static let placeholder = L10n.tr("Localizable", "create_passcode.textfield.placeholder", fallback: "")
      }
      internal enum Validation {
        /// A lowercase letter
        internal static let noLowercaseChar = L10n.tr("Localizable", "create_passcode.validation.no_lowercase_char", fallback: "A lowercase letter")
        /// A number
        internal static let noNumber = L10n.tr("Localizable", "create_passcode.validation.no_number", fallback: "A number")
        /// A special character
        internal static let noSpecialChar = L10n.tr("Localizable", "create_passcode.validation.no_special_char", fallback: "A special character")
        /// An uppercase letter
        internal static let noUppercaseChar = L10n.tr("Localizable", "create_passcode.validation.no_uppercase_char", fallback: "An uppercase letter")
        /// At least eight characters long
        internal static let tooShort = L10n.tr("Localizable", "create_passcode.validation.too_short", fallback: "At least eight characters long")
      }
    }
    internal enum Credentials {
      internal enum GeneralError {
        internal enum Alert {
          /// These account credentials are incorrect. Please verify your details and try again.
          internal static let message = L10n.tr("Localizable", "credentials.general-error.alert.message", fallback: "These account credentials are incorrect. Please verify your details and try again.")
          /// Invalid Information
          internal static let title = L10n.tr("Localizable", "credentials.general-error.alert.title", fallback: "Invalid Information")
        }
      }
    }
    internal enum DarkTheme {
      internal enum Option {
        /// Dark
        internal static let dark = L10n.tr("Localizable", "dark_theme.option.dark", fallback: "Dark")
        /// Light
        internal static let light = L10n.tr("Localizable", "dark_theme.option.light", fallback: "Light")
        /// Sync with system settings
        internal static let system = L10n.tr("Localizable", "dark_theme.option.system", fallback: "Sync with system settings")
      }
    }
    internal enum Databaseloadingfailure {
      internal enum Alert {
        /// Clear my data and continue
        internal static let deleteDatabase = L10n.tr("Localizable", "databaseloadingfailure.alert.delete_database", fallback: "Clear my data and continue")
        /// The database could not be loaded.
        ///  Error: %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "databaseloadingfailure.alert.message", String(describing: p1), fallback: "The database could not be loaded.\n Error: %@")
        }
        /// Retry
        internal static let retry = L10n.tr("Localizable", "databaseloadingfailure.alert.retry", fallback: "Retry")
        /// Save my data
        internal static let saveBackup = L10n.tr("Localizable", "databaseloadingfailure.alert.save-backup", fallback: "Save my data")
        /// Update Data storage
        internal static let title = L10n.tr("Localizable", "databaseloadingfailure.alert.title", fallback: "Update Data storage")
        internal enum DeleteDatabase {
          /// Continue
          internal static let `continue` = L10n.tr("Localizable", "databaseloadingfailure.alert.delete_database.continue", fallback: "Continue")
          /// By deleting the database, all local data and messages for this account will be permanently deleted.
          internal static let message = L10n.tr("Localizable", "databaseloadingfailure.alert.delete_database.message", fallback: "By deleting the database, all local data and messages for this account will be permanently deleted.")
        }
      }
    }
    internal enum Device {
      /// Not Verified
      internal static let notVerified = L10n.tr("Localizable", "device.not_verified", fallback: "Not Verified")
      /// Verified
      internal static let verified = L10n.tr("Localizable", "device.verified", fallback: "Verified")
      internal enum Class {
        /// Desktop
        internal static let desktop = L10n.tr("Localizable", "device.class.desktop", fallback: "Desktop")
        /// Legal Hold
        internal static let legalhold = L10n.tr("Localizable", "device.class.legalhold", fallback: "Legal Hold")
        /// Phone
        internal static let phone = L10n.tr("Localizable", "device.class.phone", fallback: "Phone")
        /// Tablet
        internal static let tablet = L10n.tr("Localizable", "device.class.tablet", fallback: "Tablet")
        /// Unknown
        internal static let unknown = L10n.tr("Localizable", "device.class.unknown", fallback: "Unknown")
      }
      internal enum Details {
        internal enum CertificateDetails {
          /// Copy to Clipboard
          internal static let copyToClipboard = L10n.tr("Localizable", "device.details.certificate_details.copy_to_clipboard", fallback: "Copy to Clipboard")
          /// Certificate Details
          internal static let title = L10n.tr("Localizable", "device.details.certificate_details.title", fallback: "Certificate Details")
        }
        internal enum Section {
          internal enum E2ei {
            /// Get Certificate
            internal static let getCertificate = L10n.tr("Localizable", "device.details.section.e2ei.get_certificate", fallback: "Get Certificate")
            /// Serial Number
            internal static let serialNumber = L10n.tr("Localizable", "device.details.section.e2ei.serial_number", fallback: "Serial Number")
            /// Show Certificate Details
            internal static let showCertificateDetails = L10n.tr("Localizable", "device.details.section.e2ei.show_certificate_details", fallback: "Show Certificate Details")
            /// End-to-end Identity Certificate
            internal static let title = L10n.tr("Localizable", "device.details.section.e2ei.title", fallback: "End-to-end Identity Certificate")
            /// Update Certificate
            internal static let updateCertificate = L10n.tr("Localizable", "device.details.section.e2ei.update_certificate", fallback: "Update Certificate")
            internal enum Status {
              /// Expired
              internal static let expired = L10n.tr("Localizable", "device.details.section.e2ei.status.expired", fallback: "Expired")
              /// Invalid
              internal static let invalid = L10n.tr("Localizable", "device.details.section.e2ei.status.invalid", fallback: "Invalid")
              /// Not activated
              internal static let notActivated = L10n.tr("Localizable", "device.details.section.e2ei.status.not_activated", fallback: "Not activated")
              /// Revoked
              internal static let revoked = L10n.tr("Localizable", "device.details.section.e2ei.status.revoked", fallback: "Revoked")
              /// Status
              internal static let title = L10n.tr("Localizable", "device.details.section.e2ei.status.title", fallback: "Status")
              /// Valid
              internal static let valid = L10n.tr("Localizable", "device.details.section.e2ei.status.valid", fallback: "Valid")
            }
          }
          internal enum Mls {
            /// MLS with %@ Signature
            internal static func signature(_ p1: Any) -> String {
              return L10n.tr("Localizable", "device.details.section.mls.signature", String(describing: p1), fallback: "MLS with %@ Signature")
            }
            /// MLS Thumbprint: %@
            internal static func thumbprint(_ p1: Any) -> String {
              return L10n.tr("Localizable", "device.details.section.mls.thumbprint", String(describing: p1), fallback: "MLS Thumbprint: %@")
            }
            /// MLS Thumbprint
            internal static let title = L10n.tr("Localizable", "device.details.section.mls.title", fallback: "MLS Thumbprint")
          }
          internal enum Proteus {
            /// Activated
            internal static let activated = L10n.tr("Localizable", "device.details.section.proteus.activated", fallback: "Activated")
            /// Proteus ID
            internal static let id = L10n.tr("Localizable", "device.details.section.proteus.id", fallback: "Proteus ID")
            /// Proteus Key Fingerprint
            internal static let keyFingerprint = L10n.tr("Localizable", "device.details.section.proteus.key_fingerprint", fallback: "Proteus Key Fingerprint")
            /// PROTEUS DEVICE DETAILS
            internal static let title = L10n.tr("Localizable", "device.details.section.proteus.title", fallback: "PROTEUS DEVICE DETAILS")
            /// Proteus ID: %@
            internal static func value(_ p1: Any) -> String {
              return L10n.tr("Localizable", "device.details.section.proteus.value", String(describing: p1), fallback: "Proteus ID: %@")
            }
          }
        }
      }
      internal enum `Type` {
        /// Legal Hold
        internal static let legalhold = L10n.tr("Localizable", "device.type.legalhold", fallback: "Legal Hold")
        /// Permanent
        internal static let permanent = L10n.tr("Localizable", "device.type.permanent", fallback: "Permanent")
        /// Temporary
        internal static let temporary = L10n.tr("Localizable", "device.type.temporary", fallback: "Temporary")
        /// Unknown
        internal static let unknown = L10n.tr("Localizable", "device.type.unknown", fallback: "Unknown")
      }
    }
    internal enum DigitalSignature {
      internal enum Alert {
        /// Please save and read the document before signing it.
        internal static let downloadNecessary = L10n.tr("Localizable", "digital_signature.alert.download_necessary", fallback: "Please save and read the document before signing it.")
        /// Unfortunately, your digital signature failed.
        internal static let error = L10n.tr("Localizable", "digital_signature.alert.error", fallback: "Unfortunately, your digital signature failed.")
        internal enum Error {
          /// Unfortunately, the signature form did not open. Please try again.
          internal static let noConsentUrl = L10n.tr("Localizable", "digital_signature.alert.error.no_consent_url", fallback: "Unfortunately, the signature form did not open. Please try again.")
          /// Unfortunately, your digital signature failed. Please try again.
          internal static let noSignature = L10n.tr("Localizable", "digital_signature.alert.error.no_signature", fallback: "Unfortunately, your digital signature failed. Please try again.")
        }
      }
    }
    internal enum Drawing {
      internal enum Colors {
        /// black
        internal static let black = L10n.tr("Localizable", "drawing.colors.black", fallback: "black")
        /// blue
        internal static let blue = L10n.tr("Localizable", "drawing.colors.blue", fallback: "blue")
        /// brown
        internal static let brown = L10n.tr("Localizable", "drawing.colors.brown", fallback: "brown")
        /// chocolate
        internal static let chocolate = L10n.tr("Localizable", "drawing.colors.chocolate", fallback: "chocolate")
        /// coral
        internal static let coral = L10n.tr("Localizable", "drawing.colors.coral", fallback: "coral")
        /// cyan
        internal static let cyan = L10n.tr("Localizable", "drawing.colors.cyan", fallback: "cyan")
        /// gray
        internal static let gray = L10n.tr("Localizable", "drawing.colors.gray", fallback: "gray")
        /// green
        internal static let green = L10n.tr("Localizable", "drawing.colors.green", fallback: "green")
        /// lilac
        internal static let lilac = L10n.tr("Localizable", "drawing.colors.lilac", fallback: "lilac")
        /// lime
        internal static let lime = L10n.tr("Localizable", "drawing.colors.lime", fallback: "lime")
        /// orange
        internal static let orange = L10n.tr("Localizable", "drawing.colors.orange", fallback: "orange")
        /// pink
        internal static let pink = L10n.tr("Localizable", "drawing.colors.pink", fallback: "pink")
        /// purple
        internal static let purple = L10n.tr("Localizable", "drawing.colors.purple", fallback: "purple")
        /// red
        internal static let red = L10n.tr("Localizable", "drawing.colors.red", fallback: "red")
        /// sky
        internal static let sky = L10n.tr("Localizable", "drawing.colors.sky", fallback: "sky")
        /// turquoise
        internal static let turquoise = L10n.tr("Localizable", "drawing.colors.turquoise", fallback: "turquoise")
        /// white
        internal static let white = L10n.tr("Localizable", "drawing.colors.white", fallback: "white")
        /// yellow
        internal static let yellow = L10n.tr("Localizable", "drawing.colors.yellow", fallback: "yellow")
      }
    }
    internal enum Email {
      /// Email
      internal static let placeholder = L10n.tr("Localizable", "email.placeholder", fallback: "Email")
      internal enum Guidance {
        /// Invalid email address
        internal static let invalid = L10n.tr("Localizable", "email.guidance.invalid", fallback: "Invalid email address")
        /// Too many characters
        internal static let toolong = L10n.tr("Localizable", "email.guidance.toolong", fallback: "Too many characters")
        /// Email is too short
        internal static let tooshort = L10n.tr("Localizable", "email.guidance.tooshort", fallback: "Email is too short")
      }
    }
    internal enum EnrollE2eiCertificate {
      /// Certificate Details
      internal static let certificateDetailsButton = L10n.tr("Localizable", "enroll_e2ei_certificate.certificate_details_button", fallback: "Certificate Details")
      /// OK
      internal static let okButton = L10n.tr("Localizable", "enroll_e2ei_certificate.ok_button", fallback: "OK")
      /// The certificate is active and your device is verified.
      internal static let subtitle = L10n.tr("Localizable", "enroll_e2ei_certificate.subtitle", fallback: "The certificate is active and your device is verified.")
      /// Certificate issued
      internal static let title = L10n.tr("Localizable", "enroll_e2ei_certificate.title", fallback: "Certificate issued")
    }
    internal enum Error {
      /// Please enter a valid email address
      internal static let email = L10n.tr("Localizable", "error.email", fallback: "Please enter a valid email address")
      /// Please enter your full name
      internal static let fullName = L10n.tr("Localizable", "error.full_name", fallback: "Please enter your full name")
      /// Please enter your full name and a valid email address
      internal static let nameAndEmail = L10n.tr("Localizable", "error.name_and_email", fallback: "Please enter your full name and a valid email address")
      /// Couldn’t update your password.
      internal static let updatingPassword = L10n.tr("Localizable", "error.updating_password", fallback: "Couldn’t update your password.")
      internal enum Call {
        /// Please try calling again in several minutes.
        internal static let general = L10n.tr("Localizable", "error.call.general", fallback: "Please try calling again in several minutes.")
        /// Please cancel the cellular call before calling on Wire.
        internal static let gsmOngoing = L10n.tr("Localizable", "error.call.gsm_ongoing", fallback: "Please cancel the cellular call before calling on Wire.")
        /// You might experience issues during the call
        internal static let slowConnection = L10n.tr("Localizable", "error.call.slow_connection", fallback: "You might experience issues during the call")
        internal enum General {
          /// Call error
          internal static let title = L10n.tr("Localizable", "error.call.general.title", fallback: "Call error")
        }
        internal enum GsmOngoing {
          /// Cellular call
          internal static let title = L10n.tr("Localizable", "error.call.gsm_ongoing.title", fallback: "Cellular call")
        }
        internal enum SlowConnection {
          /// Call anyway
          internal static let callAnyway = L10n.tr("Localizable", "error.call.slow_connection.call_anyway", fallback: "Call anyway")
          /// Slow connection
          internal static let title = L10n.tr("Localizable", "error.call.slow_connection.title", fallback: "Slow connection")
        }
      }
      internal enum Connection {
        /// Your backend does not federate with the backend of %@. You can not connect with them.
        internal static func federationDeniedMessage(_ p1: Any) -> String {
          return L10n.tr("Localizable", "error.connection.federation_denied_message", String(describing: p1), fallback: "Your backend does not federate with the backend of %@. You can not connect with them.")
        }
        /// Something went wrong, please try again
        internal static let genericError = L10n.tr("Localizable", "error.connection.generic_error", fallback: "Something went wrong, please try again")
        /// You cannot connect to this user due to legal hold.
        internal static let missingLegalholdConsent = L10n.tr("Localizable", "error.connection.missing_legalhold_consent", fallback: "You cannot connect to this user due to legal hold.")
        /// Error
        internal static let title = L10n.tr("Localizable", "error.connection.title", fallback: "Error")
      }
      internal enum Conversation {
        /// Adding the participant failed
        internal static let cannotAdd = L10n.tr("Localizable", "error.conversation.cannot_add", fallback: "Adding the participant failed")
        /// Removing the participant failed
        internal static let cannotRemove = L10n.tr("Localizable", "error.conversation.cannot_remove", fallback: "Removing the participant failed")
        /// Due to legal hold, only team members can be added to this conversation
        internal static let missingLegalholdConsent = L10n.tr("Localizable", "error.conversation.missing_legalhold_consent", fallback: "Due to legal hold, only team members can be added to this conversation")
        /// There seems to be a problem with your Internet connection. Please make sure it’s working.
        internal static let offline = L10n.tr("Localizable", "error.conversation.offline", fallback: "There seems to be a problem with your Internet connection. Please make sure it’s working.")
        /// Error
        internal static let title = L10n.tr("Localizable", "error.conversation.title", fallback: "Error")
        /// The conversation is full
        internal static let tooManyMembers = L10n.tr("Localizable", "error.conversation.too_many_members", fallback: "The conversation is full")
        internal enum Oneonone {
          /// You can't start the conversation with %@ right now. %@ needs to open Wire or log in again first. Please try again later.
          internal static func cannotStart(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "error.conversation.oneonone.cannot_start", String(describing: p1), String(describing: p2), fallback: "You can't start the conversation with %@ right now. %@ needs to open Wire or log in again first. Please try again later.")
          }
        }
      }
      internal enum Email {
        /// Please enter a valid email address
        internal static let invalid = L10n.tr("Localizable", "error.email.invalid", fallback: "Please enter a valid email address")
      }
      internal enum GroupCall {
        /// Calls work in conversations with up to %d people.
        internal static func tooManyMembersInConversation(_ p1: Int) -> String {
          return L10n.tr("Localizable", "error.group_call.too_many_members_in_conversation", p1, fallback: "Calls work in conversations with up to %d people.")
        }
        /// There’s only room for %d participants in here.
        internal static func tooManyParticipantsInTheCall(_ p1: Int) -> String {
          return L10n.tr("Localizable", "error.group_call.too_many_participants_in_the_call", p1, fallback: "There’s only room for %d participants in here.")
        }
        internal enum TooManyMembersInConversation {
          /// Too many people to call
          internal static let title = L10n.tr("Localizable", "error.group_call.too_many_members_in_conversation.title", fallback: "Too many people to call")
        }
        internal enum TooManyParticipantsInTheCall {
          /// The call is full
          internal static let title = L10n.tr("Localizable", "error.group_call.too_many_participants_in_the_call.title", fallback: "The call is full")
        }
      }
      internal enum Input {
        /// Please enter a shorter username
        internal static let tooLong = L10n.tr("Localizable", "error.input.too_long", fallback: "Please enter a shorter username")
        /// Please enter a longer username
        internal static let tooShort = L10n.tr("Localizable", "error.input.too_short", fallback: "Please enter a longer username")
      }
      internal enum Invite {
        /// Please configure your email client to be able to send the invites via email
        internal static let noEmailProvider = L10n.tr("Localizable", "error.invite.no_email_provider", fallback: "Please configure your email client to be able to send the invites via email")
        /// Please configure your SMS to be able to send the invites via SMS
        internal static let noMessagingProvider = L10n.tr("Localizable", "error.invite.no_messaging_provider", fallback: "Please configure your SMS to be able to send the invites via SMS")
      }
      internal enum Message {
        internal enum Send {
          /// You cannot send this message because you have at least one outdated device that does not support legal hold. Please update all your devices or remove them from the app settings
          internal static let missingLegalholdConsent = L10n.tr("Localizable", "error.message.send.missing_legalhold_consent", fallback: "You cannot send this message because you have at least one outdated device that does not support legal hold. Please update all your devices or remove them from the app settings")
          /// Messages cannot be sent
          internal static let title = L10n.tr("Localizable", "error.message.send.title", fallback: "Messages cannot be sent")
        }
      }
      internal enum User {
        /// You can’t add more than 3 accounts.
        internal static let accountLimitReached = L10n.tr("Localizable", "error.user.account_limit_reached", fallback: "You can’t add more than 3 accounts.")
        /// The account you are trying access is pending activation. Please verify your details.
        internal static let accountPendingActivation = L10n.tr("Localizable", "error.user.account_pending_activation", fallback: "The account you are trying access is pending activation. Please verify your details.")
        /// This account is no longer authorized to log in.
        internal static let accountSuspended = L10n.tr("Localizable", "error.user.account_suspended", fallback: "This account is no longer authorized to log in.")
        /// You have been logged out from another device.
        internal static let deviceDeletedRemotely = L10n.tr("Localizable", "error.user.device_deleted_remotely", fallback: "You have been logged out from another device.")
        /// You can't create this account as your email domain is intentionally blocked.
        /// Please ask your team admin to invite you via email.
        internal static let domainBlocked = L10n.tr("Localizable", "error.user.domain_blocked", fallback: "You can't create this account as your email domain is intentionally blocked.\nPlease ask your team admin to invite you via email.")
        /// The email address you provided has already been registered. Please try again.
        internal static let emailIsTaken = L10n.tr("Localizable", "error.user.email_is_taken", fallback: "The email address you provided has already been registered. Please try again.")
        /// Please verify your details and try again.
        internal static let invalidCredentials = L10n.tr("Localizable", "error.user.invalid_credentials", fallback: "Please verify your details and try again.")
        /// An email address is required.
        internal static let lastIdentityCantBeDeleted = L10n.tr("Localizable", "error.user.last_identity_cant_be_deleted", fallback: "An email address is required.")
        /// Please verify your details and try again.
        internal static let needsCredentials = L10n.tr("Localizable", "error.user.needs_credentials", fallback: "Please verify your details and try again.")
        /// There seems to be a problem with your network. Please try again later.
        internal static let networkError = L10n.tr("Localizable", "error.user.network_error", fallback: "There seems to be a problem with your network. Please try again later.")
        /// Something went wrong. Please try again.
        internal static let registrationUnknownError = L10n.tr("Localizable", "error.user.registration_unknown_error", fallback: "Something went wrong. Please try again.")
        /// Something went wrong, please try again
        internal static let unkownError = L10n.tr("Localizable", "error.user.unkown_error", fallback: "Something went wrong, please try again")
        /// Please enter a valid verification code.
        internal static let verificationCodeInvalid = L10n.tr("Localizable", "error.user.verification_code_invalid", fallback: "Please enter a valid verification code.")
        /// We already sent you a verification code. Tap Resend after 10 minutes to get a new one.
        internal static let verificationCodeTooMany = L10n.tr("Localizable", "error.user.verification_code_too_many", fallback: "We already sent you a verification code. Tap Resend after 10 minutes to get a new one.")
      }
    }
    internal enum FailedToGetCertificate {
      internal enum Alert {
        /// Please try again, or reach out to your team admin.
        internal static let forcedMessage = L10n.tr("Localizable", "failed_to_get_certificate.alert.forced_message", fallback: "Please try again, or reach out to your team admin.")
        /// You can retry to get the certificate now, or you will get a reminder later.
        internal static let message = L10n.tr("Localizable", "failed_to_get_certificate.alert.message", fallback: "You can retry to get the certificate now, or you will get a reminder later.")
        /// Certificate couldn’t be issued.
        internal static let title = L10n.tr("Localizable", "failed_to_get_certificate.alert.title", fallback: "Certificate couldn’t be issued.")
      }
      internal enum Button {
        /// OK
        internal static let ok = L10n.tr("Localizable", "failed_to_get_certificate.button.ok", fallback: "OK")
        /// Retry
        internal static let retry = L10n.tr("Localizable", "failed_to_get_certificate.button.retry", fallback: "Retry")
      }
    }
    internal enum FailedToUpdateCertificate {
      internal enum Alert {
        /// You can retry to update the certificate now, or you will get a reminder later.
        internal static let message = L10n.tr("Localizable", "failed_to_update_certificate.alert.message", fallback: "You can retry to update the certificate now, or you will get a reminder later.")
        /// Certificate couldn’t be updated.
        internal static let title = L10n.tr("Localizable", "failed_to_update_certificate.alert.title", fallback: "Certificate couldn’t be updated.")
      }
    }
    internal enum FeatureConfig {
      internal enum Alert {
        /// Team settings changed
        internal static let genericTitle = L10n.tr("Localizable", "feature_config.alert.generic_title", fallback: "Team settings changed")
        internal enum ConversationGuestLinks {
          internal enum Message {
            /// Generating guest links is now disabled for all group admins.
            internal static let disabled = L10n.tr("Localizable", "feature_config.alert.conversation_guest_links.message.disabled", fallback: "Generating guest links is now disabled for all group admins.")
            /// Generating guest links is now enabled for all group admins.
            internal static let enabled = L10n.tr("Localizable", "feature_config.alert.conversation_guest_links.message.enabled", fallback: "Generating guest links is now enabled for all group admins.")
          }
        }
        internal enum MlsE2ei {
          /// As of today, your team uses end-to-end identity to make Wire’s usage more secure and practicable.
          /// Enter your identity provider’s credentials in the next step to automatically get a verification certificate for this device.
          internal static let message = L10n.tr("Localizable", "feature_config.alert.mls_e2ei.message", fallback: "As of today, your team uses end-to-end identity to make Wire’s usage more secure and practicable.\nEnter your identity provider’s credentials in the next step to automatically get a verification certificate for this device.")
          /// You can get the certificate in your 'Wire Settings' during the next %@. Open 'Devices' and select 'Get Certificate' for your current device.
          internal static func reminderMessage(_ p1: Any) -> String {
            return L10n.tr("Localizable", "feature_config.alert.mls_e2ei.reminder_message", String(describing: p1), fallback: "You can get the certificate in your 'Wire Settings' during the next %@. Open 'Devices' and select 'Get Certificate' for your current device.")
          }
          /// End-to-end identity certificate
          internal static let title = L10n.tr("Localizable", "feature_config.alert.mls_e2ei.title", fallback: "End-to-end identity certificate")
          /// The end-to-end identity certificate for this device expires soon. To keep your communication secure, update your certificate now.
          /// Enter your identity provider’s credentials in the next step to update the certificate automatically.
          internal static let updateMessage = L10n.tr("Localizable", "feature_config.alert.mls_e2ei.update_message", fallback: "The end-to-end identity certificate for this device expires soon. To keep your communication secure, update your certificate now.\nEnter your identity provider’s credentials in the next step to update the certificate automatically.")
          internal enum Alert {
            internal enum UpdateCertificate {
              /// End-to-end identity certificate
              internal static let title = L10n.tr("Localizable", "feature_config.alert.mls_e2ei.alert.update_certificate.title", fallback: "End-to-end identity certificate")
            }
          }
          internal enum Button {
            /// Get Certificate
            internal static let getCertificate = L10n.tr("Localizable", "feature_config.alert.mls_e2ei.button.get_certificate", fallback: "Get Certificate")
            /// Learn More
            internal static let learnMore = L10n.tr("Localizable", "feature_config.alert.mls_e2ei.button.learn_more", fallback: "Learn More")
            /// OK
            internal static let ok = L10n.tr("Localizable", "feature_config.alert.mls_e2ei.button.ok", fallback: "OK")
            /// Remind Me Later
            internal static let remindMeLater = L10n.tr("Localizable", "feature_config.alert.mls_e2ei.button.remind_me_later", fallback: "Remind Me Later")
          }
        }
        internal enum SelfDeletingMessages {
          internal enum Message {
            /// Self-deleting messages are disabled.
            internal static let disabled = L10n.tr("Localizable", "feature_config.alert.self_deleting_messages.message.disabled", fallback: "Self-deleting messages are disabled.")
            /// Self-deleting messages are enabled. You can set a timer before writing a message.
            internal static let enabled = L10n.tr("Localizable", "feature_config.alert.self_deleting_messages.message.enabled", fallback: "Self-deleting messages are enabled. You can set a timer before writing a message.")
            /// Self-deleting messages are now mandatory. New messages will self-delete after %@.
            internal static func forcedOn(_ p1: Any) -> String {
              return L10n.tr("Localizable", "feature_config.alert.self_deleting_messages.message.forced_on", String(describing: p1), fallback: "Self-deleting messages are now mandatory. New messages will self-delete after %@.")
            }
          }
        }
      }
      internal enum ConferenceCallingRestrictions {
        internal enum Admins {
          internal enum Alert {
            /// Your team is currently on the free Basic plan. Upgrade to Enterprise to access features such as starting conference calls.
            internal static let message = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.admins.alert.message", fallback: "Your team is currently on the free Basic plan. Upgrade to Enterprise to access features such as starting conference calls.")
            /// Upgrade to Enterprise
            internal static let title = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.admins.alert.title", fallback: "Upgrade to Enterprise")
            internal enum Action {
              /// Upgrade now
              internal static let upgrade = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.admins.alert.action.upgrade", fallback: "Upgrade now")
            }
            internal enum Message {
              /// Learn more about Wire’s pricing
              internal static let learnMore = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.admins.alert.message.learn_more", fallback: "Learn more about Wire’s pricing")
            }
          }
        }
        internal enum Members {
          internal enum Alert {
            /// To start a conference call, your team needs to upgrade to the Enterprise plan.
            internal static let message = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.members.alert.message", fallback: "To start a conference call, your team needs to upgrade to the Enterprise plan.")
            /// Feature unavailable
            internal static let title = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.members.alert.title", fallback: "Feature unavailable")
          }
        }
        internal enum Personal {
          internal enum Alert {
            /// The option to initiate a conference call is only available in the paid version of Wire.
            internal static let message = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.personal.alert.message", fallback: "The option to initiate a conference call is only available in the paid version of Wire.")
            /// Feature unavailable
            internal static let title = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.personal.alert.title", fallback: "Feature unavailable")
          }
        }
      }
      internal enum FileSharingRestrictions {
        /// Receiving audio files is prohibited
        internal static let audio = L10n.tr("Localizable", "feature_config.file_sharing_restrictions.audio", fallback: "Receiving audio files is prohibited")
        /// Receiving files is prohibited
        internal static let file = L10n.tr("Localizable", "feature_config.file_sharing_restrictions.file", fallback: "Receiving files is prohibited")
        /// Receiving images is prohibited
        internal static let picture = L10n.tr("Localizable", "feature_config.file_sharing_restrictions.picture", fallback: "Receiving images is prohibited")
        /// Receiving videos is prohibited
        internal static let video = L10n.tr("Localizable", "feature_config.file_sharing_restrictions.video", fallback: "Receiving videos is prohibited")
      }
      internal enum Update {
        internal enum ConferenceCalling {
          internal enum Alert {
            /// Your team was upgraded to the Enterprise plan. You now have access to features such as starting conference calls.
            internal static let message = L10n.tr("Localizable", "feature_config.update.conference_calling.alert.message", fallback: "Your team was upgraded to the Enterprise plan. You now have access to features such as starting conference calls.")
            /// Enterprise plan
            internal static let title = L10n.tr("Localizable", "feature_config.update.conference_calling.alert.title", fallback: "Enterprise plan")
            internal enum Message {
              /// Learn more about the Enterprise plan
              internal static let learnMore = L10n.tr("Localizable", "feature_config.update.conference_calling.alert.message.learn_more", fallback: "Learn more about the Enterprise plan")
            }
          }
        }
        internal enum FileSharing {
          internal enum Alert {
            /// There has been a change in Wire
            internal static let title = L10n.tr("Localizable", "feature_config.update.file_sharing.alert.title", fallback: "There has been a change in Wire")
            internal enum Message {
              /// Sharing and receiving files of any type is now disabled.
              internal static let disabled = L10n.tr("Localizable", "feature_config.update.file_sharing.alert.message.disabled", fallback: "Sharing and receiving files of any type is now disabled.")
              /// Sharing and receiving files of any type is now enabled.
              internal static let enabled = L10n.tr("Localizable", "feature_config.update.file_sharing.alert.message.enabled", fallback: "Sharing and receiving files of any type is now enabled.")
            }
          }
        }
      }
    }
    internal enum Folder {
      internal enum Creation {
        internal enum Name {
          /// Maximum 64 characters
          internal static let footer = L10n.tr("Localizable", "folder.creation.name.footer", fallback: "Maximum 64 characters")
          /// Move the conversation "%@" to a new folder.
          internal static func header(_ p1: Any) -> String {
            return L10n.tr("Localizable", "folder.creation.name.header", String(describing: p1), fallback: "Move the conversation \"%@\" to a new folder.")
          }
          /// Folder name
          internal static let placeholder = L10n.tr("Localizable", "folder.creation.name.placeholder", fallback: "Folder name")
          /// Create new folder
          internal static let title = L10n.tr("Localizable", "folder.creation.name.title", fallback: "Create new folder")
          internal enum Button {
            /// Create
            internal static let create = L10n.tr("Localizable", "folder.creation.name.button.create", fallback: "Create")
          }
        }
      }
      internal enum Picker {
        /// Move to
        internal static let title = L10n.tr("Localizable", "folder.picker.title", fallback: "Move to")
        internal enum Empty {
          /// Create a new folder by pressing the + button
          internal static let hint = L10n.tr("Localizable", "folder.picker.empty.hint", fallback: "Create a new folder by pressing the + button")
        }
      }
    }
    internal enum Force {
      internal enum Update {
        /// You are missing out on new features.
        /// Get the latest version of Wire in the App Store.
        internal static let message = L10n.tr("Localizable", "force.update.message", fallback: "You are missing out on new features.\nGet the latest version of Wire in the App Store.")
        /// Go to App Store
        internal static let okButton = L10n.tr("Localizable", "force.update.ok_button", fallback: "Go to App Store")
        /// Update necessary
        internal static let title = L10n.tr("Localizable", "force.update.title", fallback: "Update necessary")
      }
    }
    internal enum General {
      /// Accept
      internal static let accept = L10n.tr("Localizable", "general.accept", fallback: "Accept")
      /// Back
      internal static let back = L10n.tr("Localizable", "general.back", fallback: "Back")
      /// Cancel
      internal static let cancel = L10n.tr("Localizable", "general.cancel", fallback: "Cancel")
      /// Close
      internal static let close = L10n.tr("Localizable", "general.close", fallback: "Close")
      /// OK
      internal static let confirm = L10n.tr("Localizable", "general.confirm", fallback: "OK")
      /// No, thanks
      internal static let decline = L10n.tr("Localizable", "general.decline", fallback: "No, thanks")
      /// Done
      internal static let done = L10n.tr("Localizable", "general.done", fallback: "Done")
      /// Edit
      internal static let edit = L10n.tr("Localizable", "general.edit", fallback: "Edit")
      /// Something went wrong
      internal static let failure = L10n.tr("Localizable", "general.failure", fallback: "Something went wrong")
      /// Guest room
      internal static let guestRoomName = L10n.tr("Localizable", "general.guest-room-name", fallback: "Guest room")
      /// Later
      internal static let later = L10n.tr("Localizable", "general.later", fallback: "Later")
      /// Loading…
      internal static let loading = L10n.tr("Localizable", "general.loading", fallback: "Loading…")
      /// Next
      internal static let next = L10n.tr("Localizable", "general.next", fallback: "Next")
      /// Off
      internal static let off = L10n.tr("Localizable", "general.off", fallback: "Off")
      /// OK
      internal static let ok = L10n.tr("Localizable", "general.ok", fallback: "OK")
      /// On
      internal static let on = L10n.tr("Localizable", "general.on", fallback: "On")
      /// Open Wire Settings
      internal static let openSettings = L10n.tr("Localizable", "general.open_settings", fallback: "Open Wire Settings")
      /// Paste
      internal static let paste = L10n.tr("Localizable", "general.paste", fallback: "Paste")
      /// Service
      internal static let service = L10n.tr("Localizable", "general.service", fallback: "Service")
      /// Not Now
      internal static let skip = L10n.tr("Localizable", "general.skip", fallback: "Not Now")
      ///  
      internal static let spaceBetweenWords = L10n.tr("Localizable", "general.space_between_words", fallback: " ")
      internal enum Failure {
        /// Please try again.
        internal static let tryAgain = L10n.tr("Localizable", "general.failure.try_again", fallback: "Please try again.")
      }
    }
    internal enum Giphy {
      /// cancel
      internal static let cancel = L10n.tr("Localizable", "giphy.cancel", fallback: "cancel")
      /// send
      internal static let confirm = L10n.tr("Localizable", "giphy.confirm", fallback: "send")
      /// Search Giphy
      internal static let searchPlaceholder = L10n.tr("Localizable", "giphy.search_placeholder", fallback: "Search Giphy")
      internal enum Conversation {
        /// %@ · via giphy.com
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "giphy.conversation.message", String(describing: p1), fallback: "%@ · via giphy.com")
        }
        /// via giphy.com
        internal static let randomMessage = L10n.tr("Localizable", "giphy.conversation.random_message", fallback: "via giphy.com")
      }
      internal enum Error {
        /// no more gifs
        internal static let noMoreResults = L10n.tr("Localizable", "giphy.error.no_more_results", fallback: "no more gifs")
        /// No gif found
        internal static let noResult = L10n.tr("Localizable", "giphy.error.no_result", fallback: "No gif found")
      }
    }
    internal enum GroupDetails {
      internal enum ConversationAdminsHeader {
        /// Group admins
        internal static let title = L10n.tr("Localizable", "group_details.conversation_admins_header.title", fallback: "Group admins")
      }
      internal enum ConversationMembersHeader {
        /// Group members
        internal static let title = L10n.tr("Localizable", "group_details.conversation_members_header.title", fallback: "Group members")
      }
      internal enum ConversationVerificationStatus {
        /// Verified (End-to-end Identity)
        internal static let e2ei = L10n.tr("Localizable", "group_details.conversation_verification_status.e2ei", fallback: "Verified (End-to-end Identity)")
        /// Verified (Proteus)
        internal static let proteus = L10n.tr("Localizable", "group_details.conversation_verification_status.proteus", fallback: "Verified (Proteus)")
      }
      internal enum GuestOptionsCell {
        /// Off
        internal static let disabled = L10n.tr("Localizable", "group_details.guest_options_cell.disabled", fallback: "Off")
        /// On
        internal static let enabled = L10n.tr("Localizable", "group_details.guest_options_cell.enabled", fallback: "On")
        /// Guests
        internal static let title = L10n.tr("Localizable", "group_details.guest_options_cell.title", fallback: "Guests")
      }
      internal enum MessageProtocol {
        /// Cipher Suite
        internal static let cipherSuite = L10n.tr("Localizable", "group_details.message_protocol.cipher_suite", fallback: "Cipher Suite")
        /// Protocol details
        internal static let sectionTile = L10n.tr("Localizable", "group_details.message_protocol.section_tile", fallback: "Protocol details")
        /// Protocol
        internal static let title = L10n.tr("Localizable", "group_details.message_protocol.title", fallback: "Protocol")
      }
      internal enum NotificationOptionsCell {
        /// You can be notified about everything (including audio and video calls) or only when someone mentions you or replies to one of your messages.
        internal static let description = L10n.tr("Localizable", "group_details.notification_options_cell.description", fallback: "You can be notified about everything (including audio and video calls) or only when someone mentions you or replies to one of your messages.")
        /// Notifications
        internal static let title = L10n.tr("Localizable", "group_details.notification_options_cell.title", fallback: "Notifications")
      }
      internal enum ReceiptOptionsCell {
        /// When this is on, people can see when their messages in this conversation are read.
        internal static let description = L10n.tr("Localizable", "group_details.receipt_options_cell.description", fallback: "When this is on, people can see when their messages in this conversation are read.")
        /// Read receipts
        internal static let title = L10n.tr("Localizable", "group_details.receipt_options_cell.title", fallback: "Read receipts")
      }
      internal enum ServicesOptionsCell {
        /// Off
        internal static let disabled = L10n.tr("Localizable", "group_details.services_options_cell.disabled", fallback: "Off")
        /// On
        internal static let enabled = L10n.tr("Localizable", "group_details.services_options_cell.enabled", fallback: "On")
        /// Services
        internal static let title = L10n.tr("Localizable", "group_details.services_options_cell.title", fallback: "Services")
      }
      internal enum TimeoutOptionsCell {
        /// Self-deleting messages
        internal static let title = L10n.tr("Localizable", "group_details.timeout_options_cell.title", fallback: "Self-deleting messages")
      }
    }
    internal enum GuestRoom {
      internal enum Actions {
        /// Link Copied!
        internal static let copiedLink = L10n.tr("Localizable", "guest_room.actions.copied_link", fallback: "Link Copied!")
        /// Copy Link
        internal static let copyLink = L10n.tr("Localizable", "guest_room.actions.copy_link", fallback: "Copy Link")
        /// Revoke Link…
        internal static let revokeLink = L10n.tr("Localizable", "guest_room.actions.revoke_link", fallback: "Revoke Link…")
        /// Share Link
        internal static let shareLink = L10n.tr("Localizable", "guest_room.actions.share_link", fallback: "Share Link")
      }
      internal enum AllowGuests {
        /// Open this conversation to people outside your team.
        internal static let subtitle = L10n.tr("Localizable", "guest_room.allow_guests.subtitle", fallback: "Open this conversation to people outside your team.")
        /// Allow guests
        internal static let title = L10n.tr("Localizable", "guest_room.allow_guests.title", fallback: "Allow guests")
      }
      internal enum Create {
        internal enum LinkWithPassword {
          /// Create password secured link
          internal static let action = L10n.tr("Localizable", "guest_room.create.link_with_password.action", fallback: "Create password secured link")
        }
        internal enum LinkWithoutPassword {
          /// Create link without password
          internal static let action = L10n.tr("Localizable", "guest_room.create.link_without_password.action", fallback: "Create link without password")
        }
      }
      internal enum Error {
        internal enum Generic {
          /// Check your connection and try again
          internal static let message = L10n.tr("Localizable", "guest_room.error.generic.message", fallback: "Check your connection and try again")
          /// Something went wrong
          internal static let title = L10n.tr("Localizable", "guest_room.error.generic.title", fallback: "Something went wrong")
        }
      }
      internal enum Expiration {
        /// %@h left
        internal static func hoursLeft(_ p1: Any) -> String {
          return L10n.tr("Localizable", "guest_room.expiration.hours_left", String(describing: p1), fallback: "%@h left")
        }
        /// Less than %@m left
        internal static func lessThanMinutesLeft(_ p1: Any) -> String {
          return L10n.tr("Localizable", "guest_room.expiration.less_than_minutes_left", String(describing: p1), fallback: "Less than %@m left")
        }
      }
      internal enum Link {
        internal enum Button {
          /// Create Link
          internal static let title = L10n.tr("Localizable", "guest_room.link.button.title", fallback: "Create Link")
        }
        internal enum Disabled {
          internal enum ForOtherTeam {
            /// You can't disable the guest option in this conversation, as it has been created by someone from another team.
            internal static let explanation = L10n.tr("Localizable", "guest_room.link.disabled.for_other_team.explanation", fallback: "You can't disable the guest option in this conversation, as it has been created by someone from another team.")
          }
        }
        internal enum Header {
          /// Invite others with a link to this conversation. Anyone with the link can join the conversation, even if they don’t have Wire.
          internal static let subtitle = L10n.tr("Localizable", "guest_room.link.header.subtitle", fallback: "Invite others with a link to this conversation. Anyone with the link can join the conversation, even if they don’t have Wire.")
          /// Guest Links
          internal static let title = L10n.tr("Localizable", "guest_room.link.header.title", fallback: "Guest Links")
        }
        internal enum NotAllowed {
          internal enum ForOtherTeam {
            /// You can't generate a guest link in this conversation, as it has been created by someone from another team and this team is not allowed to use guest links.
            internal static let explanation = L10n.tr("Localizable", "guest_room.link.not_allowed.for_other_team.explanation", fallback: "You can't generate a guest link in this conversation, as it has been created by someone from another team and this team is not allowed to use guest links.")
          }
          internal enum ForSelfTeam {
            /// Generating guest links is not allowed in your team.
            internal static let explanation = L10n.tr("Localizable", "guest_room.link.not_allowed.for_self_team.explanation", fallback: "Generating guest links is not allowed in your team.")
          }
        }
      }
      internal enum RemoveGuests {
        /// Remove
        internal static let action = L10n.tr("Localizable", "guest_room.remove_guests.action", fallback: "Remove")
        /// Current guests will be removed from the conversation. New guests will not be allowed.
        internal static let message = L10n.tr("Localizable", "guest_room.remove_guests.message", fallback: "Current guests will be removed from the conversation. New guests will not be allowed.")
      }
      internal enum RevokeLink {
        /// Revoke Link
        internal static let action = L10n.tr("Localizable", "guest_room.revoke_link.action", fallback: "Revoke Link")
        /// New guests will not be able to join with this link. Current guests will still have access.
        internal static let message = L10n.tr("Localizable", "guest_room.revoke_link.message", fallback: "New guests will not be able to join with this link. Current guests will still have access.")
      }
      internal enum SecureLink {
        internal enum Header {
          /// People who want to join the conversation via the guest link need to enter this password first. 
          /// 
          /// Forgot password? Revoke the link and create a new one.
          internal static let subtitle = L10n.tr("Localizable", "guest_room.secure_link.header.subtitle", fallback: "People who want to join the conversation via the guest link need to enter this password first. \n\nForgot password? Revoke the link and create a new one.")
          /// Link is password secured
          internal static let title = L10n.tr("Localizable", "guest_room.secure_link.header.title", fallback: "Link is password secured")
        }
      }
      internal enum Share {
        /// Join me in a conversation on Wire:
        /// %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "guest_room.share.message", String(describing: p1), fallback: "Join me in a conversation on Wire:\n%@")
        }
      }
    }
    internal enum Image {
      /// Add an emoji
      internal static let addEmoji = L10n.tr("Localizable", "image.add_emoji", fallback: "Add an emoji")
      /// Add a sketch
      internal static let addSketch = L10n.tr("Localizable", "image.add_sketch", fallback: "Add a sketch")
      /// Edit image
      internal static let editImage = L10n.tr("Localizable", "image.edit_image", fallback: "Edit image")
    }
    internal enum ImageConfirmer {
      /// Cancel
      internal static let cancel = L10n.tr("Localizable", "image_confirmer.cancel", fallback: "Cancel")
      /// OK
      internal static let confirm = L10n.tr("Localizable", "image_confirmer.confirm", fallback: "OK")
    }
    internal enum Inbox {
      /// Connection Requests
      internal static let title = L10n.tr("Localizable", "inbox.title", fallback: "Connection Requests")
      internal enum ConnectionRequest {
        /// Connect
        internal static let connectButtonTitle = L10n.tr("Localizable", "inbox.connection_request.connect_button_title", fallback: "Connect")
        /// Ignore
        internal static let ignoreButtonTitle = L10n.tr("Localizable", "inbox.connection_request.ignore_button_title", fallback: "Ignore")
      }
    }
    internal enum Input {
      internal enum Ephemeral {
        /// Set a time for the message to disappear
        internal static let title = L10n.tr("Localizable", "input.ephemeral.title", fallback: "Set a time for the message to disappear")
        internal enum Timeout {
          /// Off
          internal static let `none` = L10n.tr("Localizable", "input.ephemeral.timeout.none", fallback: "Off")
        }
      }
    }
    internal enum InviteBanner {
      /// Invite more people
      internal static let inviteButtonTitle = L10n.tr("Localizable", "invite_banner.invite_button_title", fallback: "Invite more people")
      /// Enjoy calls, messages, sketches, GIFs and more in private or with groups.
      internal static let message = L10n.tr("Localizable", "invite_banner.message", fallback: "Enjoy calls, messages, sketches, GIFs and more in private or with groups.")
      /// Bring your friends to Wire!
      internal static let title = L10n.tr("Localizable", "invite_banner.title", fallback: "Bring your friends to Wire!")
    }
    internal enum Jailbrokendevice {
      internal enum Alert {
        /// For security reasons, Wire can't be used on this device. Any existing Wire data has been erased.
        internal static let message = L10n.tr("Localizable", "jailbrokendevice.alert.message", fallback: "For security reasons, Wire can't be used on this device. Any existing Wire data has been erased.")
        /// Jailbreak detected
        internal static let title = L10n.tr("Localizable", "jailbrokendevice.alert.title", fallback: "Jailbreak detected")
      }
    }
    internal enum Join {
      internal enum Group {
        internal enum Conversation {
          internal enum Alert {
            /// This conversation is password protected
            internal static let message = L10n.tr("Localizable", "join.group.conversation.alert.message", fallback: "This conversation is password protected")
            /// %@ 
            ///  Enter Password
            internal static func title(_ p1: Any) -> String {
              return L10n.tr("Localizable", "join.group.conversation.alert.title", String(describing: p1), fallback: "%@ \n Enter Password")
            }
            internal enum JoinAction {
              /// Join conversation
              internal static let title = L10n.tr("Localizable", "join.group.conversation.alert.joinAction.title", fallback: "Join conversation")
            }
            internal enum LearnMoreAction {
              /// Learn more about guest links
              internal static let title = L10n.tr("Localizable", "join.group.conversation.alert.learnMoreAction.title", fallback: "Learn more about guest links")
            }
            internal enum Textfield {
              /// Enter conversation password
              internal static let placeholder = L10n.tr("Localizable", "join.group.conversation.alert.textfield.placeholder", fallback: "Enter conversation password")
            }
          }
        }
      }
    }
    internal enum KeyboardPhotosAccess {
      internal enum Denied {
        internal enum Keyboard {
          /// Wire needs access to your camera.
          internal static let camera = L10n.tr("Localizable", "keyboard_photos_access.denied.keyboard.camera", fallback: "Wire needs access to your camera.")
          /// Wire needs access to your
          /// camera and photos.
          internal static let cameraAndPhotos = L10n.tr("Localizable", "keyboard_photos_access.denied.keyboard.camera_and_photos", fallback: "Wire needs access to your\ncamera and photos.")
          /// You can’t access the camera while you are on a video call.
          internal static let ongoingCall = L10n.tr("Localizable", "keyboard_photos_access.denied.keyboard.ongoing_call", fallback: "You can’t access the camera while you are on a video call.")
          /// Wire needs access to your photos.
          internal static let photos = L10n.tr("Localizable", "keyboard_photos_access.denied.keyboard.photos", fallback: "Wire needs access to your photos.")
          /// Settings
          internal static let settings = L10n.tr("Localizable", "keyboard_photos_access.denied.keyboard.settings", fallback: "Settings")
        }
      }
    }
    internal enum Keyboardshortcut {
      /// Conversation Details...
      internal static let conversationDetail = L10n.tr("Localizable", "keyboardshortcut.conversationDetail", fallback: "Conversation Details...")
      /// People
      internal static let openPeople = L10n.tr("Localizable", "keyboardshortcut.openPeople", fallback: "People")
      /// Scroll to Bottom
      internal static let scrollToBottom = L10n.tr("Localizable", "keyboardshortcut.scrollToBottom", fallback: "Scroll to Bottom")
      /// Search in Conversation...
      internal static let searchInConversation = L10n.tr("Localizable", "keyboardshortcut.searchInConversation", fallback: "Search in Conversation...")
    }
    internal enum Landing {
      /// Wire. Log in or create a personal account.
      internal static let header = L10n.tr("Localizable", "landing.header", fallback: "Wire. Log in or create a personal account.")
      /// Trying to create a Pro or Enterprise account for your business or organization?
      internal static let welcomeMessage = L10n.tr("Localizable", "landing.welcome_message", fallback: "Trying to create a Pro or Enterprise account for your business or organization?")
      /// Unfortunately, that's not possible in the app - once you have created your team, you can log in here
      internal static let welcomeSubmessage = L10n.tr("Localizable", "landing.welcome_submessage", fallback: "Unfortunately, that's not possible in the app - once you have created your team, you can log in here")
      internal enum Alert {
        internal enum CreateNewAccount {
          internal enum NotSupported {
            /// You can't create a personal account on an on-premises backend with proxy support.
            internal static let message = L10n.tr("Localizable", "landing.alert.create-new-account.not-supported.message", fallback: "You can't create a personal account on an on-premises backend with proxy support.")
            /// Not supported
            internal static let title = L10n.tr("Localizable", "landing.alert.create-new-account.not-supported.title", fallback: "Not supported")
          }
        }
        internal enum Sso {
          internal enum NotSupported {
            /// You can't log in via SSO on an on-premises backend with proxy support.
            internal static let message = L10n.tr("Localizable", "landing.alert.sso.not-supported.message", fallback: "You can't log in via SSO on an on-premises backend with proxy support.")
            /// Not supported
            internal static let title = L10n.tr("Localizable", "landing.alert.sso.not-supported.title", fallback: "Not supported")
          }
        }
      }
      internal enum CreateAccount {
        /// Chat with friends and family?
        internal static let infotitle = L10n.tr("Localizable", "landing.create_account.infotitle", fallback: "Chat with friends and family?")
        /// Chat privately with groups of friends and family
        internal static let subtitle = L10n.tr("Localizable", "landing.create_account.subtitle", fallback: "Chat privately with groups of friends and family")
        /// Create a Wire personal account
        internal static let title = L10n.tr("Localizable", "landing.create_account.title", fallback: "Create a Wire personal account")
      }
      internal enum CreateTeam {
        /// Secure collaboration for businesses, institutions and professional organizations
        internal static let subtitle = L10n.tr("Localizable", "landing.create_team.subtitle", fallback: "Secure collaboration for businesses, institutions and professional organizations")
        /// Pro
        internal static let title = L10n.tr("Localizable", "landing.create_team.title", fallback: "Pro")
      }
      internal enum CustomBackend {
        /// Connected to "%@"
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "landing.custom_backend.title", String(describing: p1), fallback: "Connected to \"%@\"")
        }
        internal enum Alert {
          /// On-premises Backend
          internal static let title = L10n.tr("Localizable", "landing.custom_backend.alert.title", fallback: "On-premises Backend")
          internal enum Message {
            /// Backend name:
            internal static let backendName = L10n.tr("Localizable", "landing.custom_backend.alert.message.backend-name", fallback: "Backend name:")
            /// Backend URL:
            internal static let backendUrl = L10n.tr("Localizable", "landing.custom_backend.alert.message.backend-url", fallback: "Backend URL:")
          }
        }
        internal enum MoreInfo {
          internal enum Alert {
            ///  You are connected to a third-party server: %@
            internal static func title(_ p1: Any) -> String {
              return L10n.tr("Localizable", "landing.custom_backend.more_info.alert.title", String(describing: p1), fallback: " You are connected to a third-party server: %@")
            }
          }
          internal enum Button {
            /// Show more
            internal static let title = L10n.tr("Localizable", "landing.custom_backend.more_info.button.title", fallback: "Show more")
          }
        }
      }
      internal enum Login {
        /// Already have an account?
        internal static let hints = L10n.tr("Localizable", "landing.login.hints", fallback: "Already have an account?")
        internal enum Button {
          /// Log in
          internal static let title = L10n.tr("Localizable", "landing.login.button.title", fallback: "Log in")
        }
        internal enum Email {
          internal enum Button {
            /// Log in with email
            internal static let title = L10n.tr("Localizable", "landing.login.email.button.title", fallback: "Log in with email")
          }
        }
        internal enum Enterprise {
          internal enum Button {
            /// Enterprise log in
            internal static let title = L10n.tr("Localizable", "landing.login.enterprise.button.title", fallback: "Enterprise log in")
          }
        }
        internal enum Sso {
          internal enum Button {
            /// Log in with SSO
            internal static let title = L10n.tr("Localizable", "landing.login.sso.button.title", fallback: "Log in with SSO")
          }
        }
      }
    }
    internal enum LegalHold {
      internal enum Deactivated {
        /// Future messages will not be recorded.
        internal static let message = L10n.tr("Localizable", "legal_hold.deactivated.message", fallback: "Future messages will not be recorded.")
        /// Legal Hold Deactivated
        internal static let title = L10n.tr("Localizable", "legal_hold.deactivated.title", fallback: "Legal Hold Deactivated")
      }
    }
    internal enum Legalhold {
      /// Legal hold details
      internal static let accessibility = L10n.tr("Localizable", "legalhold.accessibility", fallback: "Legal hold details")
      internal enum Header {
        /// Legal Hold has been activated for at least one person in this conversation.
        /// All messages will be preserved for future access, including deleted, edited, and self-deleting messages.
        internal static let otherDescription = L10n.tr("Localizable", "legalhold.header.other_description", fallback: "Legal Hold has been activated for at least one person in this conversation.\nAll messages will be preserved for future access, including deleted, edited, and self-deleting messages.")
        /// Legal Hold has been activated for your account.
        /// All messages will be preserved for future access, including deleted, edited, and self-deleting messages.
        /// Your conversation partners will be aware of the recording.
        internal static let selfDescription = L10n.tr("Localizable", "legalhold.header.self_description", fallback: "Legal Hold has been activated for your account.\nAll messages will be preserved for future access, including deleted, edited, and self-deleting messages.\nYour conversation partners will be aware of the recording.")
        /// Legal Hold
        internal static let title = L10n.tr("Localizable", "legalhold.header.title", fallback: "Legal Hold")
      }
      internal enum Participants {
        internal enum Section {
          /// Legal hold subjects %@
          internal static func title(_ p1: Any) -> String {
            return L10n.tr("Localizable", "legalhold.participants.section.title", String(describing: p1), fallback: "Legal hold subjects %@")
          }
        }
      }
    }
    internal enum LegalholdActive {
      internal enum Alert {
        /// Learn More
        internal static let learnMore = L10n.tr("Localizable", "legalhold_active.alert.learn_more", fallback: "Learn More")
        /// Legal Hold has been activated for your account. All messages will be preserved for future access, including deleted, edited, and self-deleting messages.
        /// 
        /// Your conversation partners will be aware of the recording.
        internal static let message = L10n.tr("Localizable", "legalhold_active.alert.message", fallback: "Legal Hold has been activated for your account. All messages will be preserved for future access, including deleted, edited, and self-deleting messages.\n\nYour conversation partners will be aware of the recording.")
        /// Legal Hold is Active
        internal static let title = L10n.tr("Localizable", "legalhold_active.alert.title", fallback: "Legal Hold is Active")
      }
    }
    internal enum LegalholdRequest {
      internal enum Alert {
        /// All future messages will be recorded by the device with fingerprint:
        /// 
        /// %@
        /// 
        /// This includes deleted, edited, and self-deleting messages in all conversations.
        internal static func detail(_ p1: Any) -> String {
          return L10n.tr("Localizable", "legalhold_request.alert.detail", String(describing: p1), fallback: "All future messages will be recorded by the device with fingerprint:\n\n%@\n\nThis includes deleted, edited, and self-deleting messages in all conversations.")
        }
        /// Wrong Password
        internal static let errorWrongPassword = L10n.tr("Localizable", "legalhold_request.alert.error_wrong_password", fallback: "Wrong Password")
        /// Legal Hold Requested
        internal static let title = L10n.tr("Localizable", "legalhold_request.alert.title", fallback: "Legal Hold Requested")
        internal enum Detail {
          /// Enter your password to confirm.
          internal static let enterPassword = L10n.tr("Localizable", "legalhold_request.alert.detail.enter_password", fallback: "Enter your password to confirm.")
        }
      }
      internal enum Button {
        /// Pending approval.
        internal static let accessibility = L10n.tr("Localizable", "legalhold_request.button.accessibility", fallback: "Pending approval.")
      }
    }
    internal enum Library {
      internal enum Alert {
        internal enum PermissionWarning {
          /// Wire needs access to your Photos
          internal static let title = L10n.tr("Localizable", "library.alert.permission_warning.title", fallback: "Wire needs access to your Photos")
          internal enum NotAllowed {
            /// Go to Settings and allow Wire to access your photos.
            internal static let explaination = L10n.tr("Localizable", "library.alert.permission_warning.not_allowed.explaination", fallback: "Go to Settings and allow Wire to access your photos.")
          }
          internal enum Restrictions {
            /// Wire cannot access your library because restrictions are enabled.
            internal static let explaination = L10n.tr("Localizable", "library.alert.permission_warning.restrictions.explaination", fallback: "Wire cannot access your library because restrictions are enabled.")
          }
        }
      }
    }
    internal enum List {
      /// ARCHIVE
      internal static let archivedConversations = L10n.tr("Localizable", "list.archived_conversations", fallback: "ARCHIVE")
      /// Close archive
      internal static let archivedConversationsClose = L10n.tr("Localizable", "list.archived_conversations_close", fallback: "Close archive")
      /// Conversations
      internal static let title = L10n.tr("Localizable", "list.title", fallback: "Conversations")
      internal enum ConnectRequest {
        /// Plural format key: "%#@d_number_of_people@ waiting"
        internal static func peopleWaiting(_ p1: Int) -> String {
          return L10n.tr("Localizable", "list.connect_request.people_waiting", p1, fallback: "Plural format key: \"%#@d_number_of_people@ waiting\"")
        }
      }
      internal enum Section {
        /// People
        internal static let contacts = L10n.tr("Localizable", "list.section.contacts", fallback: "People")
        /// Favorites
        internal static let favorites = L10n.tr("Localizable", "list.section.favorites", fallback: "Favorites")
        /// Groups
        internal static let groups = L10n.tr("Localizable", "list.section.groups", fallback: "Groups")
        /// Requests
        internal static let requests = L10n.tr("Localizable", "list.section.requests", fallback: "Requests")
      }
    }
    internal enum Location {
      internal enum Error {
        internal enum Alert {
          /// Wire can’t get your location at the moment. Check if you allowed Wire to access your location in your device settings.
          internal static let description = L10n.tr("Localizable", "location.error.alert.description", fallback: "Wire can’t get your location at the moment. Check if you allowed Wire to access your location in your device settings.")
          /// Location can’t be sent.
          internal static let title = L10n.tr("Localizable", "location.error.alert.title", fallback: "Location can’t be sent.")
        }
      }
      internal enum SendButton {
        /// Send
        internal static let title = L10n.tr("Localizable", "location.send_button.title", fallback: "Send")
      }
      internal enum UnauthorizedAlert {
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "location.unauthorized_alert.cancel", fallback: "Cancel")
        /// To send your location, enable Location Services and allow Wire to access your location.
        internal static let message = L10n.tr("Localizable", "location.unauthorized_alert.message", fallback: "To send your location, enable Location Services and allow Wire to access your location.")
        /// Settings
        internal static let settings = L10n.tr("Localizable", "location.unauthorized_alert.settings", fallback: "Settings")
        /// Enable Location Services
        internal static let title = L10n.tr("Localizable", "location.unauthorized_alert.title", fallback: "Enable Location Services")
      }
    }
    internal enum Login {
      internal enum Sso {
        /// This link is not valid. Please contact your administrator to resolve the issue.
        internal static let linkErrorMessage = L10n.tr("Localizable", "login.sso.link_error_message", fallback: "This link is not valid. Please contact your administrator to resolve the issue.")
        /// Cannot Start Enterprise Login
        internal static let startErrorTitle = L10n.tr("Localizable", "login.sso.start_error_title", fallback: "Cannot Start Enterprise Login")
        internal enum Alert {
          /// Log in
          internal static let action = L10n.tr("Localizable", "login.sso.alert.action", fallback: "Log in")
          /// Enterprise Login
          internal static let title = L10n.tr("Localizable", "login.sso.alert.title", fallback: "Enterprise Login")
          internal enum Message {
            /// Please enter your email or SSO code. If your email matches an enterprise installation of Wire, this app will connect to that server.
            internal static let ssoAndEmail = L10n.tr("Localizable", "login.sso.alert.message.sso_and_email", fallback: "Please enter your email or SSO code. If your email matches an enterprise installation of Wire, this app will connect to that server.")
            /// Please enter your SSO code:
            internal static let ssoOnly = L10n.tr("Localizable", "login.sso.alert.message.sso_only", fallback: "Please enter your SSO code:")
          }
          internal enum TextField {
            internal enum Placeholder {
              /// email or SSO access code
              internal static let ssoAndEmail = L10n.tr("Localizable", "login.sso.alert.text_field.placeholder.sso_and_email", fallback: "email or SSO access code")
              /// SSO access code
              internal static let ssoOnly = L10n.tr("Localizable", "login.sso.alert.text_field.placeholder.sso_only", fallback: "SSO access code")
            }
          }
        }
        internal enum BackendSwitch {
          /// Provide credentials only if you're sure this is your organization's log in.
          internal static let information = L10n.tr("Localizable", "login.sso.backend_switch.information", fallback: "Provide credentials only if you're sure this is your organization's log in.")
          /// You are being redirected to your dedicated enterprise service.
          internal static let subtitle = L10n.tr("Localizable", "login.sso.backend_switch.subtitle", fallback: "You are being redirected to your dedicated enterprise service.")
          /// Redirecting...
          internal static let title = L10n.tr("Localizable", "login.sso.backend_switch.title", fallback: "Redirecting...")
        }
        internal enum Error {
          internal enum Alert {
            /// Please contact your team administrator for details (error %@).
            internal static func message(_ p1: Any) -> String {
              return L10n.tr("Localizable", "login.sso.error.alert.message", String(describing: p1), fallback: "Please contact your team administrator for details (error %@).")
            }
            internal enum DomainAssociatedWithWrongServer {
              /// This email is linked to a different server, but the app can only be connected to one server at a time. Please log out of all Wire accounts on this device and try to login again.
              internal static let message = L10n.tr("Localizable", "login.sso.error.alert.domain_associated_with_wrong_server.message", fallback: "This email is linked to a different server, but the app can only be connected to one server at a time. Please log out of all Wire accounts on this device and try to login again.")
            }
            internal enum DomainNotRegistered {
              /// This email cannot be used for enterprise login. Please enter the SSO code to proceed.
              internal static let message = L10n.tr("Localizable", "login.sso.error.alert.domain_not_registered.message", fallback: "This email cannot be used for enterprise login. Please enter the SSO code to proceed.")
            }
            internal enum InvalidCode {
              /// Please verify your company SSO access code and try again.
              internal static let message = L10n.tr("Localizable", "login.sso.error.alert.invalid_code.message", fallback: "Please verify your company SSO access code and try again.")
            }
            internal enum InvalidFormat {
              internal enum Message {
                /// Please enter a valid email or SSO access code
                internal static let ssoAndEmail = L10n.tr("Localizable", "login.sso.error.alert.invalid_format.message.sso_and_email", fallback: "Please enter a valid email or SSO access code")
                /// Please enter a valid SSO access code
                internal static let ssoOnly = L10n.tr("Localizable", "login.sso.error.alert.invalid_format.message.sso_only", fallback: "Please enter a valid SSO access code")
              }
            }
            internal enum InvalidStatus {
              /// Please try again later (error %@).
              internal static func message(_ p1: Any) -> String {
                return L10n.tr("Localizable", "login.sso.error.alert.invalid_status.message", String(describing: p1), fallback: "Please try again later (error %@).")
              }
            }
            internal enum Unknown {
              /// Please try again later.
              internal static let message = L10n.tr("Localizable", "login.sso.error.alert.unknown.message", fallback: "Please try again later.")
            }
          }
          internal enum Offline {
            internal enum Alert {
              /// Please check your Internet connection and try again.
              internal static let message = L10n.tr("Localizable", "login.sso.error.offline.alert.message", fallback: "Please check your Internet connection and try again.")
            }
          }
        }
      }
    }
    internal enum Message {
      internal enum DeleteDialog {
        /// This cannot be undone.
        internal static let message = L10n.tr("Localizable", "message.delete_dialog.message", fallback: "This cannot be undone.")
        internal enum Action {
          /// Cancel
          internal static let cancel = L10n.tr("Localizable", "message.delete_dialog.action.cancel", fallback: "Cancel")
          /// Delete for Everyone
          internal static let delete = L10n.tr("Localizable", "message.delete_dialog.action.delete", fallback: "Delete for Everyone")
          /// Delete for Me
          internal static let hide = L10n.tr("Localizable", "message.delete_dialog.action.hide", fallback: "Delete for Me")
        }
      }
      internal enum Menu {
        internal enum Edit {
          /// Edit
          internal static let title = L10n.tr("Localizable", "message.menu.edit.title", fallback: "Edit")
        }
      }
    }
    internal enum MessageDetails {
      /// Message Details
      internal static let combinedTitle = L10n.tr("Localizable", "message_details.combined_title", fallback: "Message Details")
      /// No one has reacted to this message yet.
      internal static let emptyLikes = L10n.tr("Localizable", "message_details.empty_likes", fallback: "No one has reacted to this message yet.")
      /// No one has read this message yet.
      internal static let emptyReadReceipts = L10n.tr("Localizable", "message_details.empty_read_receipts", fallback: "No one has read this message yet.")
      /// Reactions
      internal static let reactionsTitle = L10n.tr("Localizable", "message_details.reactions_title", fallback: "Reactions")
      /// Read receipts were not on when this message was sent.
      internal static let readReceiptsDisabled = L10n.tr("Localizable", "message_details.read_receipts_disabled", fallback: "Read receipts were not on when this message was sent.")
      /// Read
      internal static let receiptsTitle = L10n.tr("Localizable", "message_details.receipts_title", fallback: "Read")
      /// Edited: %@
      internal static func subtitleEditDate(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message_details.subtitle_edit_date", String(describing: p1), fallback: "Edited: %@")
      }
      /// Message Details
      internal static let subtitleLabelVoiceOver = L10n.tr("Localizable", "message_details.subtitle_label_voiceOver", fallback: "Message Details")
      /// Sent: %@
      internal static func subtitleSendDate(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message_details.subtitle_send_date", String(describing: p1), fallback: "Sent: %@")
      }
      /// Username
      internal static let userHandleSubtitleLabel = L10n.tr("Localizable", "message_details.user_handle_subtitle_label", fallback: "Username")
      /// Read at
      internal static let userReadTimestampSubtitleLabel = L10n.tr("Localizable", "message_details.user_read_timestamp_subtitle_label", fallback: "Read at")
      internal enum Tabs {
        /// Reactions (%d)
        internal static func reactions(_ p1: Int) -> String {
          return L10n.tr("Localizable", "message_details.tabs.reactions", p1, fallback: "Reactions (%d)")
        }
        /// Read (%d)
        internal static func seen(_ p1: Int) -> String {
          return L10n.tr("Localizable", "message_details.tabs.seen", p1, fallback: "Read (%d)")
        }
      }
    }
    internal enum Meta {
      /// Cancel
      internal static let leaveConversationButtonCancel = L10n.tr("Localizable", "meta.leave_conversation_button_cancel", fallback: "Cancel")
      /// Leave
      internal static let leaveConversationButtonLeave = L10n.tr("Localizable", "meta.leave_conversation_button_leave", fallback: "Leave")
      /// Leave and clear content
      internal static let leaveConversationButtonLeaveAndDelete = L10n.tr("Localizable", "meta.leave_conversation_button_leave_and_delete", fallback: "Leave and clear content")
      /// The participants will be notified and the conversation will be removed from your list.
      internal static let leaveConversationDialogMessage = L10n.tr("Localizable", "meta.leave_conversation_dialog_message", fallback: "The participants will be notified and the conversation will be removed from your list.")
      /// Leave conversation?
      internal static let leaveConversationDialogTitle = L10n.tr("Localizable", "meta.leave_conversation_dialog_title", fallback: "Leave conversation?")
      internal enum Degraded {
        /// Cancel
        internal static let cancelSendingButton = L10n.tr("Localizable", "meta.degraded.cancel_sending_button", fallback: "Cancel")
        /// Do you still want to send your message?
        internal static let dialogMessage = L10n.tr("Localizable", "meta.degraded.dialog_message", fallback: "Do you still want to send your message?")
        /// Send Anyway
        internal static let sendAnywayButton = L10n.tr("Localizable", "meta.degraded.send_anyway_button", fallback: "Send Anyway")
        /// Verify Devices…
        internal static let verifyDevicesButton = L10n.tr("Localizable", "meta.degraded.verify_devices_button", fallback: "Verify Devices…")
        internal enum DegradationReasonMessage {
          /// %@ started using new devices.
          internal static func plural(_ p1: Any) -> String {
            return L10n.tr("Localizable", "meta.degraded.degradation_reason_message.plural", String(describing: p1), fallback: "%@ started using new devices.")
          }
          /// %@ started using a new device.
          internal static func singular(_ p1: Any) -> String {
            return L10n.tr("Localizable", "meta.degraded.degradation_reason_message.singular", String(describing: p1), fallback: "%@ started using a new device.")
          }
          /// Someone started using a new device.
          internal static let someone = L10n.tr("Localizable", "meta.degraded.degradation_reason_message.someone", fallback: "Someone started using a new device.")
        }
      }
      internal enum LeaveConversation {
        /// Also clear the content
        internal static let deleteContentAsWellMessage = L10n.tr("Localizable", "meta.leave_conversation.delete_content_as_well_message", fallback: "Also clear the content")
      }
      internal enum Legalhold {
        /// What Is Legal Hold?
        internal static let infoButton = L10n.tr("Localizable", "meta.legalhold.info_button", fallback: "What Is Legal Hold?")
        /// The conversation is now subject to legal hold.
        internal static let sendAlertTitle = L10n.tr("Localizable", "meta.legalhold.send_alert_title", fallback: "The conversation is now subject to legal hold.")
      }
      internal enum Menu {
        /// More actions
        internal static let accessibilityMoreOptionsButton = L10n.tr("Localizable", "meta.menu.accessibility_more_options_button", fallback: "More actions")
        /// Archive
        internal static let archive = L10n.tr("Localizable", "meta.menu.archive", fallback: "Archive")
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "meta.menu.cancel", fallback: "Cancel")
        /// Cancel Request
        internal static let cancelConnectionRequest = L10n.tr("Localizable", "meta.menu.cancel_connection_request", fallback: "Cancel Request")
        /// Clear Content…
        internal static let clearContent = L10n.tr("Localizable", "meta.menu.clear_content", fallback: "Clear Content…")
        /// Notifications…
        internal static let configureNotifications = L10n.tr("Localizable", "meta.menu.configure_notifications", fallback: "Notifications…")
        /// Delete Group…
        internal static let delete = L10n.tr("Localizable", "meta.menu.delete", fallback: "Delete Group…")
        /// Leave Group…
        internal static let leave = L10n.tr("Localizable", "meta.menu.leave", fallback: "Leave Group…")
        /// Mark as Read
        internal static let markRead = L10n.tr("Localizable", "meta.menu.mark_read", fallback: "Mark as Read")
        /// Mark as Unread
        internal static let markUnread = L10n.tr("Localizable", "meta.menu.mark_unread", fallback: "Mark as Unread")
        /// Move to…
        internal static let moveToFolder = L10n.tr("Localizable", "meta.menu.move_to_folder", fallback: "Move to…")
        /// Open Profile
        internal static let openSelfProfile = L10n.tr("Localizable", "meta.menu.open_self_profile", fallback: "Open Profile")
        /// Remove from "%@"
        internal static func removeFromFolder(_ p1: Any) -> String {
          return L10n.tr("Localizable", "meta.menu.remove_from_folder", String(describing: p1), fallback: "Remove from \"%@\"")
        }
        /// Rename
        internal static let rename = L10n.tr("Localizable", "meta.menu.rename", fallback: "Rename")
        /// Unarchive
        internal static let unarchive = L10n.tr("Localizable", "meta.menu.unarchive", fallback: "Unarchive")
        internal enum ConfigureNotification {
          /// Cancel
          internal static let buttonCancel = L10n.tr("Localizable", "meta.menu.configure_notification.button_cancel", fallback: "Cancel")
          /// Everything
          internal static let buttonEverything = L10n.tr("Localizable", "meta.menu.configure_notification.button_everything", fallback: "Everything")
          /// Mentions and Replies
          internal static let buttonMentionsAndReplies = L10n.tr("Localizable", "meta.menu.configure_notification.button_mentions_and_replies", fallback: "Mentions and Replies")
          /// Nothing
          internal static let buttonNothing = L10n.tr("Localizable", "meta.menu.configure_notification.button_nothing", fallback: "Nothing")
          /// Notify me about:
          internal static let dialogMessage = L10n.tr("Localizable", "meta.menu.configure_notification.dialog_message", fallback: "Notify me about:")
        }
        internal enum DeleteContent {
          /// Cancel
          internal static let buttonCancel = L10n.tr("Localizable", "meta.menu.delete_content.button_cancel", fallback: "Cancel")
          /// Clear
          internal static let buttonDelete = L10n.tr("Localizable", "meta.menu.delete_content.button_delete", fallback: "Clear")
          /// Clear and leave
          internal static let buttonDeleteAndLeave = L10n.tr("Localizable", "meta.menu.delete_content.button_delete_and_leave", fallback: "Clear and leave")
          /// This will clear the conversation history on all your devices.
          internal static let dialogMessage = L10n.tr("Localizable", "meta.menu.delete_content.dialog_message", fallback: "This will clear the conversation history on all your devices.")
          /// Clear content?
          internal static let dialogTitle = L10n.tr("Localizable", "meta.menu.delete_content.dialog_title", fallback: "Clear content?")
          /// Also leave the conversation
          internal static let leaveAsWellMessage = L10n.tr("Localizable", "meta.menu.delete_content.leave_as_well_message", fallback: "Also leave the conversation")
        }
        internal enum Silence {
          /// Mute
          internal static let mute = L10n.tr("Localizable", "meta.menu.silence.mute", fallback: "Mute")
          /// Unmute
          internal static let unmute = L10n.tr("Localizable", "meta.menu.silence.unmute", fallback: "Unmute")
        }
      }
      internal enum Mls {
        internal enum Degraded {
          internal enum Alert {
            /// At least one participant started using a new device or has an invalid certificate.
            /// 
            /// Do you still want to send the message?
            internal static let message = L10n.tr("Localizable", "meta.mls.degraded.alert.message", fallback: "At least one participant started using a new device or has an invalid certificate.\n\nDo you still want to send the message?")
            /// Conversation no longer verified
            internal static let title = L10n.tr("Localizable", "meta.mls.degraded.alert.title", fallback: "Conversation no longer verified")
          }
        }
      }
    }
    internal enum Migration {
      /// One moment, please
      internal static let pleaseWaitMessage = L10n.tr("Localizable", "migration.please_wait_message", fallback: "One moment, please")
    }
    internal enum Missive {
      internal enum ConnectionRequest {
        /// Hi %@,
        /// Let’s connect on Wire.
        /// %@
        internal static func defaultMessage(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "missive.connection_request.default_message", String(describing: p1), String(describing: p2), fallback: "Hi %@,\nLet’s connect on Wire.\n%@")
        }
      }
    }
    internal enum Name {
      /// Your full name
      internal static let placeholder = L10n.tr("Localizable", "name.placeholder", fallback: "Your full name")
      internal enum Guidance {
        /// Too many characters
        internal static let toolong = L10n.tr("Localizable", "name.guidance.toolong", fallback: "Too many characters")
        /// At least 2 characters
        internal static let tooshort = L10n.tr("Localizable", "name.guidance.tooshort", fallback: "At least 2 characters")
      }
    }
    internal enum NewsOffers {
      internal enum Consent {
        /// You can unsubscribe at any time.
        internal static let message = L10n.tr("Localizable", "news_offers.consent.message", fallback: "You can unsubscribe at any time.")
        /// Do you want to receive news and product updates from Wire via email?
        internal static let title = L10n.tr("Localizable", "news_offers.consent.title", fallback: "Do you want to receive news and product updates from Wire via email?")
        internal enum Button {
          internal enum PrivacyPolicy {
            /// Privacy Policy
            internal static let title = L10n.tr("Localizable", "news_offers.consent.button.privacy_policy.title", fallback: "Privacy Policy")
          }
        }
      }
    }
    internal enum Notifications {
      /// %@ - %@
      internal static func inConversation(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "notifications.in_conversation", String(describing: p1), String(describing: p2), fallback: "%@ - %@")
      }
      /// pinged
      internal static let pinged = L10n.tr("Localizable", "notifications.pinged", fallback: "pinged")
      /// shared an audio
      internal static let sentAudio = L10n.tr("Localizable", "notifications.sent_audio", fallback: "shared an audio")
      /// shared a file
      internal static let sentFile = L10n.tr("Localizable", "notifications.sent_file", fallback: "shared a file")
      /// shared a location
      internal static let sentLocation = L10n.tr("Localizable", "notifications.sent_location", fallback: "shared a location")
      /// shared a video
      internal static let sentVideo = L10n.tr("Localizable", "notifications.sent_video", fallback: "shared a video")
      /// shared a picture
      internal static let sharedAPhoto = L10n.tr("Localizable", "notifications.shared_a_photo", fallback: "shared a picture")
      /// %@ in this conversation
      internal static func thisConversation(_ p1: Any) -> String {
        return L10n.tr("Localizable", "notifications.this_conversation", String(describing: p1), fallback: "%@ in this conversation")
      }
    }
    internal enum OpenLink {
      internal enum Browser {
        internal enum Option {
          /// Brave
          internal static let brave = L10n.tr("Localizable", "open_link.browser.option.brave", fallback: "Brave")
          /// Chrome
          internal static let chrome = L10n.tr("Localizable", "open_link.browser.option.chrome", fallback: "Chrome")
          /// Firefox
          internal static let firefox = L10n.tr("Localizable", "open_link.browser.option.firefox", fallback: "Firefox")
          /// Safari
          internal static let safari = L10n.tr("Localizable", "open_link.browser.option.safari", fallback: "Safari")
          /// SnowHaze
          internal static let snowhaze = L10n.tr("Localizable", "open_link.browser.option.snowhaze", fallback: "SnowHaze")
        }
      }
      internal enum Maps {
        /// Some location links will always open in Apple Maps.
        internal static let footer = L10n.tr("Localizable", "open_link.maps.footer", fallback: "Some location links will always open in Apple Maps.")
        internal enum Option {
          /// Maps
          internal static let apple = L10n.tr("Localizable", "open_link.maps.option.apple", fallback: "Maps")
          /// Google Maps
          internal static let google = L10n.tr("Localizable", "open_link.maps.option.google", fallback: "Google Maps")
        }
      }
      internal enum Twitter {
        internal enum Option {
          /// Browser / Twitter
          internal static let `default` = L10n.tr("Localizable", "open_link.twitter.option.default", fallback: "Browser / Twitter")
          /// Tweetbot
          internal static let tweetbot = L10n.tr("Localizable", "open_link.twitter.option.tweetbot", fallback: "Tweetbot")
          /// Twitterrific
          internal static let twitterrific = L10n.tr("Localizable", "open_link.twitter.option.twitterrific", fallback: "Twitterrific")
        }
      }
    }
    internal enum Participants {
      /// Add
      internal static let addPeopleButtonTitle = L10n.tr("Localizable", "participants.add_people_button_title", fallback: "Add")
      /// Details
      internal static let title = L10n.tr("Localizable", "participants.title", fallback: "Details")
      internal enum All {
        /// People
        internal static let title = L10n.tr("Localizable", "participants.all.title", fallback: "People")
      }
      internal enum Avatar {
        internal enum Guest {
          /// Guest
          internal static let title = L10n.tr("Localizable", "participants.avatar.guest.title", fallback: "Guest")
        }
      }
      internal enum Footer {
        /// Add Participants
        internal static let addTitle = L10n.tr("Localizable", "participants.footer.add_title", fallback: "Add Participants")
      }
      internal enum People {
        /// Plural format key: "%#@lu_number_of_people@"
        internal static func count(_ p1: Int) -> String {
          return L10n.tr("Localizable", "participants.people.count", p1, fallback: "Plural format key: \"%#@lu_number_of_people@\"")
        }
      }
      internal enum Section {
        /// People (%d)
        internal static func participants(_ p1: Int) -> String {
          return L10n.tr("Localizable", "participants.section.participants", p1, fallback: "People (%d)")
        }
        /// Services (%d)
        internal static func services(_ p1: Int) -> String {
          return L10n.tr("Localizable", "participants.section.services", p1, fallback: "Services (%d)")
        }
        /// Options
        internal static let settings = L10n.tr("Localizable", "participants.section.settings", fallback: "Options")
        internal enum Admins {
          /// There are no admins.
          internal static let footer = L10n.tr("Localizable", "participants.section.admins.footer", fallback: "There are no admins.")
        }
        internal enum Members {
          /// There are no members.
          internal static let footer = L10n.tr("Localizable", "participants.section.members.footer", fallback: "There are no members.")
        }
        internal enum Name {
          /// Up to %1$d participants can join a group conversation.
          internal static func footer(_ p1: Int) -> String {
            return L10n.tr("Localizable", "participants.section.name.footer", p1, fallback: "Up to %1$d participants can join a group conversation.")
          }
        }
      }
      internal enum Services {
        internal enum RemoveIntegration {
          /// Remove service
          internal static let button = L10n.tr("Localizable", "participants.services.remove_integration.button", fallback: "Remove service")
        }
      }
    }
    internal enum Passcode {
      /// Passcode
      internal static let hintLabel = L10n.tr("Localizable", "passcode.hint_label", fallback: "Passcode")
    }
    internal enum Password {
      /// Password
      internal static let placeholder = L10n.tr("Localizable", "password.placeholder", fallback: "Password")
      internal enum Guidance {
        /// Too many characters
        internal static let toolong = L10n.tr("Localizable", "password.guidance.toolong", fallback: "Too many characters")
      }
    }
    internal enum Peoplepicker {
      /// Hide
      internal static let hideSearchResult = L10n.tr("Localizable", "peoplepicker.hide_search_result", fallback: "Hide")
      /// Hiding…
      internal static let hideSearchResultProgress = L10n.tr("Localizable", "peoplepicker.hide_search_result_progress", fallback: "Hiding…")
      /// Invite more people
      internal static let inviteMorePeople = L10n.tr("Localizable", "peoplepicker.invite_more_people", fallback: "Invite more people")
      /// Invite people to join the team
      internal static let inviteTeamMembers = L10n.tr("Localizable", "peoplepicker.invite_team_members", fallback: "Invite people to join the team")
      /// No Contacts.
      internal static let noContactsTitle = L10n.tr("Localizable", "peoplepicker.no_contacts_title", fallback: "No Contacts.")
      /// No results.
      internal static let noMatchingResultsAfterAddressBookUploadTitle = L10n.tr("Localizable", "peoplepicker.no_matching_results_after_address_book_upload_title", fallback: "No results.")
      /// No matching results. Try entering a different name.
      internal static let noSearchResults = L10n.tr("Localizable", "peoplepicker.no_search_results", fallback: "No matching results. Try entering a different name.")
      /// Search by name or username
      internal static let searchPlaceholder = L10n.tr("Localizable", "peoplepicker.search_placeholder", fallback: "Search by name or username")
      internal enum Button {
        /// Add Participants
        internal static let addToConversation = L10n.tr("Localizable", "peoplepicker.button.add_to_conversation", fallback: "Add Participants")
        /// Create group
        internal static let createConversation = L10n.tr("Localizable", "peoplepicker.button.create_conversation", fallback: "Create group")
      }
      internal enum Federation {
        /// The federated domain is currently not available. [Learn more](%@)
        internal static func domainUnvailable(_ p1: Any) -> String {
          return L10n.tr("Localizable", "peoplepicker.federation.domain_unvailable", String(describing: p1), fallback: "The federated domain is currently not available. [Learn more](%@)")
        }
      }
      internal enum Group {
        /// Create
        internal static let create = L10n.tr("Localizable", "peoplepicker.group.create", fallback: "Create")
        /// Done
        internal static let done = L10n.tr("Localizable", "peoplepicker.group.done", fallback: "Done")
        /// Skip
        internal static let skip = L10n.tr("Localizable", "peoplepicker.group.skip", fallback: "Skip")
        internal enum Title {
          /// Add Participants (%d)
          internal static func plural(_ p1: Int) -> String {
            return L10n.tr("Localizable", "peoplepicker.group.title.plural", p1, fallback: "Add Participants (%d)")
          }
          /// Add Participants
          internal static let singular = L10n.tr("Localizable", "peoplepicker.group.title.singular", fallback: "Add Participants")
        }
      }
      internal enum Header {
        /// Contacts
        internal static let contacts = L10n.tr("Localizable", "peoplepicker.header.contacts", fallback: "Contacts")
        /// Personal Contacts
        internal static let contactsPersonal = L10n.tr("Localizable", "peoplepicker.header.contacts_personal", fallback: "Personal Contacts")
        /// Groups
        internal static let conversations = L10n.tr("Localizable", "peoplepicker.header.conversations", fallback: "Groups")
        /// Connect
        internal static let directory = L10n.tr("Localizable", "peoplepicker.header.directory", fallback: "Connect")
        /// Connect with other domain
        internal static let federation = L10n.tr("Localizable", "peoplepicker.header.federation", fallback: "Connect with other domain")
        /// People
        internal static let people = L10n.tr("Localizable", "peoplepicker.header.people", fallback: "People")
        /// Invite
        internal static let sendInvitation = L10n.tr("Localizable", "peoplepicker.header.send_invitation", fallback: "Invite")
        /// Services
        internal static let services = L10n.tr("Localizable", "peoplepicker.header.services", fallback: "Services")
        /// %@ Groups
        internal static func teamConversations(_ p1: Any) -> String {
          return L10n.tr("Localizable", "peoplepicker.header.team_conversations", String(describing: p1), fallback: "%@ Groups")
        }
        /// Top people
        internal static let topPeople = L10n.tr("Localizable", "peoplepicker.header.top_people", fallback: "Top people")
      }
      internal enum NoMatchingResults {
        internal enum Action {
          /// Learn more
          internal static let learnMore = L10n.tr("Localizable", "peoplepicker.no_matching_results.action.learn_more", fallback: "Learn more")
          /// Manage Services
          internal static let manageServices = L10n.tr("Localizable", "peoplepicker.no_matching_results.action.manage_services", fallback: "Manage Services")
          /// Send an invitation
          internal static let sendInvite = L10n.tr("Localizable", "peoplepicker.no_matching_results.action.send_invite", fallback: "Send an invitation")
          /// Share contacts
          internal static let shareContacts = L10n.tr("Localizable", "peoplepicker.no_matching_results.action.share_contacts", fallback: "Share contacts")
        }
        internal enum Message {
          /// No results.
          internal static let services = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.services", fallback: "No results.")
          /// Services are helpers that can improve your workflow. To enable them, ask your administrator.
          internal static let servicesNotEnabled = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.services_not_enabled", fallback: "Services are helpers that can improve your workflow. To enable them, ask your administrator.")
          /// Services are helpers that can improve your workflow.
          internal static let servicesNotEnabledAdmin = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.services_not_enabled_admin", fallback: "Services are helpers that can improve your workflow.")
          /// Find people in Wire by name or @username
          internal static let users = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.users", fallback: "Find people in Wire by name or @username")
          /// Everyone’s here.
          internal static let usersAllAdded = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.users_all_added", fallback: "Everyone’s here.")
          /// Find people in Wire by name or @username
          /// 
          /// Find people on another domain by @username@domainname
          internal static let usersAndFederation = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.usersAndFederation", fallback: "Find people in Wire by name or @username\n\nFind people on another domain by @username@domainname")
        }
      }
      internal enum QuickAction {
        /// Manage Services
        internal static let adminServices = L10n.tr("Localizable", "peoplepicker.quick-action.admin-services", fallback: "Manage Services")
        /// Create group
        internal static let createConversation = L10n.tr("Localizable", "peoplepicker.quick-action.create-conversation", fallback: "Create group")
        /// Create guest room
        internal static let createGuestRoom = L10n.tr("Localizable", "peoplepicker.quick-action.create-guest-room", fallback: "Create guest room")
        /// Open
        internal static let openConversation = L10n.tr("Localizable", "peoplepicker.quick-action.open-conversation", fallback: "Open")
      }
      internal enum SendInvitation {
        internal enum Dialog {
          /// It can be used for 2 weeks. Send a new one if it expires.
          internal static let message = L10n.tr("Localizable", "peoplepicker.send_invitation.dialog.message", fallback: "It can be used for 2 weeks. Send a new one if it expires.")
          /// OK
          internal static let ok = L10n.tr("Localizable", "peoplepicker.send_invitation.dialog.ok", fallback: "OK")
          /// Invitation sent
          internal static let title = L10n.tr("Localizable", "peoplepicker.send_invitation.dialog.title", fallback: "Invitation sent")
        }
      }
      internal enum Services {
        internal enum AddService {
          /// Add service
          internal static let button = L10n.tr("Localizable", "peoplepicker.services.add_service.button", fallback: "Add service")
          internal enum Error {
            /// The service is unavailable at the moment
            internal static let `default` = L10n.tr("Localizable", "peoplepicker.services.add_service.error.default", fallback: "The service is unavailable at the moment")
            /// The conversation is full
            internal static let full = L10n.tr("Localizable", "peoplepicker.services.add_service.error.full", fallback: "The conversation is full")
            /// The service can’t be added
            internal static let title = L10n.tr("Localizable", "peoplepicker.services.add_service.error.title", fallback: "The service can’t be added")
          }
        }
        internal enum OpenConversation {
          /// Open conversation
          internal static let item = L10n.tr("Localizable", "peoplepicker.services.open_conversation.item", fallback: "Open conversation")
        }
      }
      internal enum Suggested {
        /// Plural format key: "Knows %@ and %#@d_number_of_others@"
        internal static func knowsMore(_ p1: Any, _ p2: Int) -> String {
          return L10n.tr("Localizable", "peoplepicker.suggested.knows_more", String(describing: p1), p2, fallback: "Plural format key: \"Knows %@ and %#@d_number_of_others@\"")
        }
        /// Knows %@
        internal static func knowsOne(_ p1: Any) -> String {
          return L10n.tr("Localizable", "peoplepicker.suggested.knows_one", String(describing: p1), fallback: "Knows %@")
        }
        /// Knows %@ and %@
        internal static func knowsTwo(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "peoplepicker.suggested.knows_two", String(describing: p1), String(describing: p2), fallback: "Knows %@ and %@")
        }
      }
      internal enum Title {
        /// Add participants
        internal static let addToConversation = L10n.tr("Localizable", "peoplepicker.title.add_to_conversation", fallback: "Add participants")
        /// Create group
        internal static let createConversation = L10n.tr("Localizable", "peoplepicker.title.create_conversation", fallback: "Create group")
      }
    }
    internal enum Profile {
      /// Block…
      internal static let blockButtonTitle = L10n.tr("Localizable", "profile.block_button_title", fallback: "Block…")
      /// Block
      internal static let blockButtonTitleAction = L10n.tr("Localizable", "profile.block_button_title_action", fallback: "Block")
      /// Cancel Request
      internal static let cancelConnectionButtonTitle = L10n.tr("Localizable", "profile.cancel_connection_button_title", fallback: "Cancel Request")
      /// Create group
      internal static let createConversationButtonTitle = L10n.tr("Localizable", "profile.create_conversation_button_title", fallback: "Create group")
      /// Add to Favorites
      internal static let favoriteButtonTitle = L10n.tr("Localizable", "profile.favorite_button_title", fallback: "Add to Favorites")
      /// Open conversation
      internal static let openConversationButtonTitle = L10n.tr("Localizable", "profile.open_conversation_button_title", fallback: "Open conversation")
      /// Cancel
      internal static let removeDialogButtonCancel = L10n.tr("Localizable", "profile.remove_dialog_button_cancel", fallback: "Cancel")
      /// Remove From Group…
      internal static let removeDialogButtonRemove = L10n.tr("Localizable", "profile.remove_dialog_button_remove", fallback: "Remove From Group…")
      /// Remove From Group
      internal static let removeDialogButtonRemoveConfirm = L10n.tr("Localizable", "profile.remove_dialog_button_remove_confirm", fallback: "Remove From Group")
      /// %@ won’t be able to send or receive messages in this conversation.
      internal static func removeDialogMessage(_ p1: Any) -> String {
        return L10n.tr("Localizable", "profile.remove_dialog_message", String(describing: p1), fallback: "%@ won’t be able to send or receive messages in this conversation.")
      }
      /// Remove?
      internal static let removeDialogTitle = L10n.tr("Localizable", "profile.remove_dialog_title", fallback: "Remove?")
      /// Start conversation
      internal static let startConversationButtonTitle = L10n.tr("Localizable", "profile.start_conversation_button_title", fallback: "Start conversation")
      /// Unblock…
      internal static let unblockButtonTitle = L10n.tr("Localizable", "profile.unblock_button_title", fallback: "Unblock…")
      /// Unblock
      internal static let unblockButtonTitleAction = L10n.tr("Localizable", "profile.unblock_button_title_action", fallback: "Unblock")
      /// Remove from Favorites
      internal static let unfavoriteButtonTitle = L10n.tr("Localizable", "profile.unfavorite_button_title", fallback: "Remove from Favorites")
      internal enum BlockDialog {
        /// Block
        internal static let buttonBlock = L10n.tr("Localizable", "profile.block_dialog.button_block", fallback: "Block")
        /// Cancel
        internal static let buttonCancel = L10n.tr("Localizable", "profile.block_dialog.button_cancel", fallback: "Cancel")
        /// %@ won’t be able to contact you or add you to group conversations.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "profile.block_dialog.message", String(describing: p1), fallback: "%@ won’t be able to contact you or add you to group conversations.")
        }
        /// Block?
        internal static let title = L10n.tr("Localizable", "profile.block_dialog.title", fallback: "Block?")
      }
      internal enum CancelConnectionRequestDialog {
        /// Cancel
        internal static let buttonCancel = L10n.tr("Localizable", "profile.cancel_connection_request_dialog.button_cancel", fallback: "Cancel")
        /// Yes
        internal static let buttonYes = L10n.tr("Localizable", "profile.cancel_connection_request_dialog.button_yes", fallback: "Yes")
        /// Remove connection request to %@.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "profile.cancel_connection_request_dialog.message", String(describing: p1), fallback: "Remove connection request to %@.")
        }
        /// Cancel Request?
        internal static let title = L10n.tr("Localizable", "profile.cancel_connection_request_dialog.title", fallback: "Cancel Request?")
      }
      internal enum ConnectionRequestDialog {
        /// Ignore
        internal static let buttonCancel = L10n.tr("Localizable", "profile.connection_request_dialog.button_cancel", fallback: "Ignore")
        /// Connect
        internal static let buttonConnect = L10n.tr("Localizable", "profile.connection_request_dialog.button_connect", fallback: "Connect")
        /// This will connect you and open the conversation with %@.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "profile.connection_request_dialog.message", String(describing: p1), fallback: "This will connect you and open the conversation with %@.")
        }
        /// Accept?
        internal static let title = L10n.tr("Localizable", "profile.connection_request_dialog.title", fallback: "Accept?")
      }
      internal enum ConnectionRequestState {
        /// BLOCKED
        internal static let blocked = L10n.tr("Localizable", "profile.connection_request_state.blocked", fallback: "BLOCKED")
      }
      internal enum Details {
        /// This user is blocked due to legal hold. [LEARN MORE](%@)
        internal static func blockingReason(_ p1: Any) -> String {
          return L10n.tr("Localizable", "profile.details.blocking_reason", String(describing: p1), fallback: "This user is blocked due to legal hold. [LEARN MORE](%@)")
        }
        /// Federated
        internal static let federated = L10n.tr("Localizable", "profile.details.federated", fallback: "Federated")
        /// Group admin
        internal static let groupAdmin = L10n.tr("Localizable", "profile.details.group_admin", fallback: "Group admin")
        /// Guest
        internal static let guest = L10n.tr("Localizable", "profile.details.guest", fallback: "Guest")
        /// Get certainty about %@’s identity before connecting.
        internal static func identityWarning(_ p1: Any) -> String {
          return L10n.tr("Localizable", "profile.details.identity_warning", String(describing: p1), fallback: "Get certainty about %@’s identity before connecting.")
        }
        /// external
        internal static let partner = L10n.tr("Localizable", "profile.details.partner", fallback: "external")
        /// Please verify the person's identity before accepting the connection request.
        internal static let requestedIdentityWarning = L10n.tr("Localizable", "profile.details.requested_identity_warning", fallback: "Please verify the person's identity before accepting the connection request.")
        /// Details
        internal static let title = L10n.tr("Localizable", "profile.details.title", fallback: "Details")
        internal enum Title {
          /// Name not available
          internal static let unavailable = L10n.tr("Localizable", "profile.details.title.unavailable", fallback: "Name not available")
        }
      }
      internal enum Devices {
        /// %@ is using an old version of Wire. No devices are shown here.
        internal static func fingerprintMessageUnencrypted(_ p1: Any) -> String {
          return L10n.tr("Localizable", "profile.devices.fingerprint_message_unencrypted", String(describing: p1), fallback: "%@ is using an old version of Wire. No devices are shown here.")
        }
        /// No device data available.
        internal static let noDeviceData = L10n.tr("Localizable", "profile.devices.no_device_data", fallback: "No device data available.")
        /// Devices
        internal static let title = L10n.tr("Localizable", "profile.devices.title", fallback: "Devices")
        internal enum Detail {
          /// Verify that this matches the fingerprint shown on %@’s device.
          internal static func verifyMessage(_ p1: Any) -> String {
            return L10n.tr("Localizable", "profile.devices.detail.verify_message", String(describing: p1), fallback: "Verify that this matches the fingerprint shown on %@’s device.")
          }
          internal enum ResetSession {
            /// Reset Session
            internal static let title = L10n.tr("Localizable", "profile.devices.detail.reset_session.title", fallback: "Reset Session")
          }
          internal enum ShowMyDevice {
            /// Show my device fingerprint
            internal static let title = L10n.tr("Localizable", "profile.devices.detail.show_my_device.title", fallback: "Show my device fingerprint")
          }
          internal enum VerifyMessage {
            /// How do I do that?
            internal static let link = L10n.tr("Localizable", "profile.devices.detail.verify_message.link", fallback: "How do I do that?")
          }
        }
        internal enum FingerprintMessage {
          /// Why verify conversations?
          internal static let link = L10n.tr("Localizable", "profile.devices.fingerprint_message.link", fallback: "Why verify conversations?")
          /// Wire gives every device a unique fingerprint. Compare them with %@ and verify your conversation.
          internal static func title(_ p1: Any) -> String {
            return L10n.tr("Localizable", "profile.devices.fingerprint_message.title", String(describing: p1), fallback: "Wire gives every device a unique fingerprint. Compare them with %@ and verify your conversation.")
          }
        }
      }
      internal enum ExtendedMetadata {
        /// Information
        internal static let header = L10n.tr("Localizable", "profile.extended_metadata.header", fallback: "Information")
      }
      internal enum GroupAdminStatusMemo {
        /// When this is on, the admin can add or remove people and services, update group settings, and change a participant's role.
        internal static let body = L10n.tr("Localizable", "profile.group_admin_status_memo.body", fallback: "When this is on, the admin can add or remove people and services, update group settings, and change a participant's role.")
      }
      internal enum Profile {
        internal enum GroupAdminOptions {
          /// Group admin
          internal static let title = L10n.tr("Localizable", "profile.profile.group_admin_options.title", fallback: "Group admin")
        }
      }
      internal enum ReadReceiptsDisabledMemo {
        /// YOU HAVE DISABLED READ RECEIPTS
        internal static let header = L10n.tr("Localizable", "profile.read_receipts_disabled_memo.header", fallback: "YOU HAVE DISABLED READ RECEIPTS")
      }
      internal enum ReadReceiptsEnabledMemo {
        /// YOU HAVE ENABLED READ RECEIPTS
        internal static let header = L10n.tr("Localizable", "profile.read_receipts_enabled_memo.header", fallback: "YOU HAVE ENABLED READ RECEIPTS")
      }
      internal enum ReadReceiptsMemo {
        /// If both sides turn on read receipts, you can see when messages are read.
        /// 
        /// You can change this option in your account settings.
        internal static let body = L10n.tr("Localizable", "profile.read_receipts_memo.body", fallback: "If both sides turn on read receipts, you can see when messages are read.\n\nYou can change this option in your account settings.")
      }
    }
    internal enum ProxyCredentials {
      /// This backend is configured to use the following proxy server: %@.
      internal static func caption(_ p1: Any) -> String {
        return L10n.tr("Localizable", "proxy-credentials.caption", String(describing: p1), fallback: "This backend is configured to use the following proxy server: %@.")
      }
      /// Proxy Credentials
      internal static let title = L10n.tr("Localizable", "proxy-credentials.title", fallback: "Proxy Credentials")
      internal enum Password {
        /// Proxy Password
        internal static let label = L10n.tr("Localizable", "proxy-credentials.password.label", fallback: "Proxy Password")
        /// Password
        internal static let placeholder = L10n.tr("Localizable", "proxy-credentials.password.placeholder", fallback: "Password")
      }
      internal enum Username {
        /// Proxy Email or Username
        internal static let label = L10n.tr("Localizable", "proxy-credentials.username.label", fallback: "Proxy Email or Username")
        /// Email or Username
        internal static let placeholder = L10n.tr("Localizable", "proxy-credentials.username.placeholder", fallback: "Email or Username")
      }
    }
    internal enum Push {
      internal enum Notification {
        /// New message
        internal static let newMessage = L10n.tr("Localizable", "push.notification.new_message", fallback: "New message")
        /// %@ joined Wire
        internal static func newUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "push.notification.new_user", String(describing: p1), fallback: "%@ joined Wire")
        }
      }
    }
    internal enum Registration {
      /// Sign Up
      internal static let confirm = L10n.tr("Localizable", "registration.confirm", fallback: "Sign Up")
      /// Email
      internal static let registerByEmail = L10n.tr("Localizable", "registration.register_by_email", fallback: "Email")
      /// Registration
      internal static let title = L10n.tr("Localizable", "registration.title", fallback: "Registration")
      internal enum AddEmailPassword {
        internal enum Hero {
          /// This lets you use Wire on multiple devices.
          internal static let paragraph = L10n.tr("Localizable", "registration.add_email_password.hero.paragraph", fallback: "This lets you use Wire on multiple devices.")
          /// Add your email and password
          internal static let title = L10n.tr("Localizable", "registration.add_email_password.hero.title", fallback: "Add your email and password")
        }
      }
      internal enum AddressBookAccessDenied {
        internal enum Hero {
          /// Wire helps find your friends if you share your contacts.
          internal static let paragraph1 = L10n.tr("Localizable", "registration.address_book_access_denied.hero.paragraph1", fallback: "Wire helps find your friends if you share your contacts.")
          /// To enable access tap Settings and turn on Contacts.
          internal static let paragraph2 = L10n.tr("Localizable", "registration.address_book_access_denied.hero.paragraph2", fallback: "To enable access tap Settings and turn on Contacts.")
          /// Wire does not have access to your contacts.
          internal static let title = L10n.tr("Localizable", "registration.address_book_access_denied.hero.title", fallback: "Wire does not have access to your contacts.")
        }
        internal enum MaybeLaterButton {
          /// Maybe later
          internal static let title = L10n.tr("Localizable", "registration.address_book_access_denied.maybe_later_button.title", fallback: "Maybe later")
        }
        internal enum SettingsButton {
          /// Settings
          internal static let title = L10n.tr("Localizable", "registration.address_book_access_denied.settings_button.title", fallback: "Settings")
        }
      }
      internal enum Alert {
        /// Register with Another Email
        internal static let changeEmailAction = L10n.tr("Localizable", "registration.alert.change_email_action", fallback: "Register with Another Email")
        /// Log In
        internal static let changeSigninAction = L10n.tr("Localizable", "registration.alert.change_signin_action", fallback: "Log In")
        internal enum AccountExists {
          /// The email address you used to register is already linked to an account.
          /// 
          ///  Use another email address, or try to log in if you own this account.
          internal static let messageEmail = L10n.tr("Localizable", "registration.alert.account_exists.message_email", fallback: "The email address you used to register is already linked to an account.\n\n Use another email address, or try to log in if you own this account.")
          /// Account Exists
          internal static let title = L10n.tr("Localizable", "registration.alert.account_exists.title", fallback: "Account Exists")
        }
      }
      internal enum CloseEmailInvitationButton {
        /// Use another email
        internal static let emailTitle = L10n.tr("Localizable", "registration.close_email_invitation_button.email_title", fallback: "Use another email")
      }
      internal enum ClosePhoneInvitationButton {
        /// Register by email
        internal static let emailTitle = L10n.tr("Localizable", "registration.close_phone_invitation_button.email_title", fallback: "Register by email")
      }
      internal enum CountrySelect {
        /// Country
        internal static let title = L10n.tr("Localizable", "registration.country_select.title", fallback: "Country")
      }
      internal enum Devices {
        /// Activated %@
        internal static func activated(_ p1: Any) -> String {
          return L10n.tr("Localizable", "registration.devices.activated", String(describing: p1), fallback: "Activated %@")
        }
        /// Active
        internal static let activeListHeader = L10n.tr("Localizable", "registration.devices.active_list_header", fallback: "Active")
        /// If you don’t recognize a device above, remove it and reset your password.
        internal static let activeListSubtitle = L10n.tr("Localizable", "registration.devices.active_list_subtitle", fallback: "If you don’t recognize a device above, remove it and reset your password.")
        /// Current
        internal static let currentListHeader = L10n.tr("Localizable", "registration.devices.current_list_header", fallback: "Current")
        /// ID:
        internal static let id = L10n.tr("Localizable", "registration.devices.id", fallback: "ID:")
        /// Devices
        internal static let title = L10n.tr("Localizable", "registration.devices.title", fallback: "Devices")
      }
      internal enum EmailFlow {
        /// Register by Email
        internal static let title = L10n.tr("Localizable", "registration.email_flow.title", fallback: "Register by Email")
        internal enum EmailStep {
          /// Edit Details
          internal static let title = L10n.tr("Localizable", "registration.email_flow.email_step.title", fallback: "Edit Details")
        }
      }
      internal enum EmailInvitation {
        /// Invitation
        internal static let title = L10n.tr("Localizable", "registration.email_invitation.title", fallback: "Invitation")
        internal enum Hero {
          /// Choose a password to create your account.
          internal static let paragraph = L10n.tr("Localizable", "registration.email_invitation.hero.paragraph", fallback: "Choose a password to create your account.")
          /// Hello, %@
          internal static func title(_ p1: Any) -> String {
            return L10n.tr("Localizable", "registration.email_invitation.hero.title", String(describing: p1), fallback: "Hello, %@")
          }
        }
      }
      internal enum EnterName {
        /// What should we call you?
        internal static let hero = L10n.tr("Localizable", "registration.enter_name.hero", fallback: "What should we call you?")
        /// Your full name
        internal static let placeholder = L10n.tr("Localizable", "registration.enter_name.placeholder", fallback: "Your full name")
        /// Edit Name
        internal static let title = L10n.tr("Localizable", "registration.enter_name.title", fallback: "Edit Name")
      }
      internal enum LaunchBackButton {
        /// Back
        internal static let label = L10n.tr("Localizable", "registration.launch_back_button.label", fallback: "Back")
      }
      internal enum NoHistory {
        /// OK
        internal static let gotIt = L10n.tr("Localizable", "registration.no_history.got_it", fallback: "OK")
        /// It’s the first time you’re using Wire on this device.
        internal static let hero = L10n.tr("Localizable", "registration.no_history.hero", fallback: "It’s the first time you’re using Wire on this device.")
        /// Restore from backup
        internal static let restoreBackup = L10n.tr("Localizable", "registration.no_history.restore_backup", fallback: "Restore from backup")
        /// For privacy reasons, your conversation history will not appear here.
        internal static let subtitle = L10n.tr("Localizable", "registration.no_history.subtitle", fallback: "For privacy reasons, your conversation history will not appear here.")
        internal enum LoggedOut {
          /// OK
          internal static let gotIt = L10n.tr("Localizable", "registration.no_history.logged_out.got_it", fallback: "OK")
          /// You’ve used Wire on this device before.
          internal static let hero = L10n.tr("Localizable", "registration.no_history.logged_out.hero", fallback: "You’ve used Wire on this device before.")
          /// Messages sent in the meantime will not appear.
          internal static let subtitle = L10n.tr("Localizable", "registration.no_history.logged_out.subtitle", fallback: "Messages sent in the meantime will not appear.")
        }
        internal enum RestoreBackup {
          /// Completed
          internal static let completed = L10n.tr("Localizable", "registration.no_history.restore_backup.completed", fallback: "Completed")
          /// Restoring…
          internal static let restoring = L10n.tr("Localizable", "registration.no_history.restore_backup.restoring", fallback: "Restoring…")
          internal enum Password {
            /// The password is required to restore this backup.
            internal static let message = L10n.tr("Localizable", "registration.no_history.restore_backup.password.message", fallback: "The password is required to restore this backup.")
            /// Password
            internal static let placeholder = L10n.tr("Localizable", "registration.no_history.restore_backup.password.placeholder", fallback: "Password")
            /// This backup is password protected.
            internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup.password.title", fallback: "This backup is password protected.")
          }
          internal enum PasswordError {
            /// Wrong Password
            internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup.password_error.title", fallback: "Wrong Password")
          }
        }
        internal enum RestoreBackupFailed {
          /// Your history could not be restored.
          internal static let message = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.message", fallback: "Your history could not be restored.")
          /// Something went wrong
          internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.title", fallback: "Something went wrong")
          /// Try again
          internal static let tryAgain = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.try_again", fallback: "Try again")
          internal enum WrongAccount {
            /// You cannot restore history from a different account.
            internal static let message = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.wrong_account.message", fallback: "You cannot restore history from a different account.")
            /// Incompatible backup
            internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.wrong_account.title", fallback: "Incompatible backup")
          }
          internal enum WrongVersion {
            /// This backup was created by a newer or outdated version of Wire and cannot be restored here.
            internal static let message = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.wrong_version.message", fallback: "This backup was created by a newer or outdated version of Wire and cannot be restored here.")
            /// Incompatible backup
            internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.wrong_version.title", fallback: "Incompatible backup")
          }
        }
        internal enum RestoreBackupWarning {
          /// The backup contents will replace the conversation history on this device.
          /// You can only restore history from a backup of the same platform.
          internal static let message = L10n.tr("Localizable", "registration.no_history.restore_backup_warning.message", fallback: "The backup contents will replace the conversation history on this device.\nYou can only restore history from a backup of the same platform.")
          /// Choose Backup File
          internal static let proceed = L10n.tr("Localizable", "registration.no_history.restore_backup_warning.proceed", fallback: "Choose Backup File")
          /// Restore history
          internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup_warning.title", fallback: "Restore history")
        }
      }
      internal enum Password {
        internal enum Rules {
          /// Plural format key: "%#@character_count@"
          internal static func lowercase(_ p1: Int) -> String {
            return L10n.tr("Localizable", "registration.password.rules.lowercase", p1, fallback: "Plural format key: \"%#@character_count@\"")
          }
          /// Plural format key: "at least %#@character_count@"
          internal static func minLength(_ p1: Int) -> String {
            return L10n.tr("Localizable", "registration.password.rules.min_length", p1, fallback: "Plural format key: \"at least %#@character_count@\"")
          }
          /// Use %@.
          internal static func noRequirements(_ p1: Any) -> String {
            return L10n.tr("Localizable", "registration.password.rules.no_requirements", String(describing: p1), fallback: "Use %@.")
          }
          /// Plural format key: "%#@character_count@"
          internal static func number(_ p1: Int) -> String {
            return L10n.tr("Localizable", "registration.password.rules.number", p1, fallback: "Plural format key: \"%#@character_count@\"")
          }
          /// Plural format key: "%#@character_count@"
          internal static func special(_ p1: Int) -> String {
            return L10n.tr("Localizable", "registration.password.rules.special", p1, fallback: "Plural format key: \"%#@character_count@\"")
          }
          /// Plural format key: "%#@character_count@"
          internal static func uppercase(_ p1: Int) -> String {
            return L10n.tr("Localizable", "registration.password.rules.uppercase", p1, fallback: "Plural format key: \"%#@character_count@\"")
          }
          /// Use %@, with %@.
          internal static func withRequirements(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "registration.password.rules.with_requirements", String(describing: p1), String(describing: p2), fallback: "Use %@, with %@.")
          }
        }
      }
      internal enum Personal {
        /// Create an account
        internal static let title = L10n.tr("Localizable", "registration.personal.title", fallback: "Create an account")
      }
      internal enum PushAccessDenied {
        internal enum Hero {
          /// Enable Notifications in Settings.
          internal static let paragraph1 = L10n.tr("Localizable", "registration.push_access_denied.hero.paragraph1", fallback: "Enable Notifications in Settings.")
          /// Never miss a call or a message.
          internal static let title = L10n.tr("Localizable", "registration.push_access_denied.hero.title", fallback: "Never miss a call or a message.")
        }
        internal enum MaybeLaterButton {
          /// Maybe later
          internal static let title = L10n.tr("Localizable", "registration.push_access_denied.maybe_later_button.title", fallback: "Maybe later")
        }
        internal enum SettingsButton {
          /// Go to Settings
          internal static let title = L10n.tr("Localizable", "registration.push_access_denied.settings_button.title", fallback: "Go to Settings")
        }
      }
      internal enum SelectHandle {
        internal enum Takeover {
          /// Choose yours
          internal static let chooseOwn = L10n.tr("Localizable", "registration.select_handle.takeover.choose_own", fallback: "Choose yours")
          /// Keep this one
          internal static let keepSuggested = L10n.tr("Localizable", "registration.select_handle.takeover.keep_suggested", fallback: "Keep this one")
          /// Claim your unique name on Wire.
          internal static let subtitle = L10n.tr("Localizable", "registration.select_handle.takeover.subtitle", fallback: "Claim your unique name on Wire.")
          /// Learn more
          internal static let subtitleLink = L10n.tr("Localizable", "registration.select_handle.takeover.subtitle_link", fallback: "Learn more")
        }
      }
      internal enum ShareContacts {
        internal enum FindFriendsButton {
          /// Share contacts
          internal static let title = L10n.tr("Localizable", "registration.share_contacts.find_friends_button.title", fallback: "Share contacts")
        }
        internal enum Hero {
          /// Share your contacts so we can connect you with others. We anonymize all information and do not share it with anyone else.
          internal static let paragraph = L10n.tr("Localizable", "registration.share_contacts.hero.paragraph", fallback: "Share your contacts so we can connect you with others. We anonymize all information and do not share it with anyone else.")
          /// Find people on Wire
          internal static let title = L10n.tr("Localizable", "registration.share_contacts.hero.title", fallback: "Find people on Wire")
        }
        internal enum SkipButton {
          /// Not now
          internal static let title = L10n.tr("Localizable", "registration.share_contacts.skip_button.title", fallback: "Not now")
        }
      }
      internal enum Signin {
        /// Log in
        internal static let title = L10n.tr("Localizable", "registration.signin.title", fallback: "Log in")
        internal enum Alert {
          internal enum PasswordNeeded {
            /// Please enter your Password in order to log in.
            internal static let message = L10n.tr("Localizable", "registration.signin.alert.password_needed.message", fallback: "Please enter your Password in order to log in.")
            /// Password needed
            internal static let title = L10n.tr("Localizable", "registration.signin.alert.password_needed.title", fallback: "Password needed")
          }
        }
        internal enum E2ei {
          /// [Learn more](%@)
          internal static func learnMore(_ p1: Any) -> String {
            return L10n.tr("Localizable", "registration.signin.e2ei.learn_more", String(describing: p1), fallback: "[Learn more](%@)")
          }
          /// Your team now uses end-to-end identity to make Wire's usage more secure.
          /// 
          ///  Enter your identity provider's credentials in the next step to automatically get a verification certificate for this device.
          internal static let subtitle = L10n.tr("Localizable", "registration.signin.e2ei.subtitle", fallback: "Your team now uses end-to-end identity to make Wire's usage more secure.\n\n Enter your identity provider's credentials in the next step to automatically get a verification certificate for this device.")
          /// End-to-end identity certificate
          internal static let title = L10n.tr("Localizable", "registration.signin.e2ei.title", fallback: "End-to-end identity certificate")
          internal enum Error {
            internal enum Alert {
              /// Failed to retrieve certificate
              internal static let message = L10n.tr("Localizable", "registration.signin.e2ei.error.alert.message", fallback: "Failed to retrieve certificate")
              /// Something went wrong
              internal static let title = L10n.tr("Localizable", "registration.signin.e2ei.error.alert.title", fallback: "Something went wrong")
            }
          }
          internal enum GetCertificateButton {
            /// Get Certificate
            internal static let title = L10n.tr("Localizable", "registration.signin.e2ei.get_certificate_button.title", fallback: "Get Certificate")
          }
        }
        internal enum TooManyDevices {
          /// Remove one of your other devices to start using Wire on this one.
          internal static let subtitle = L10n.tr("Localizable", "registration.signin.too_many_devices.subtitle", fallback: "Remove one of your other devices to start using Wire on this one.")
          /// Too Many Devices
          internal static let title = L10n.tr("Localizable", "registration.signin.too_many_devices.title", fallback: "Too Many Devices")
          internal enum ManageButton {
            /// Manage devices
            internal static let title = L10n.tr("Localizable", "registration.signin.too_many_devices.manage_button.title", fallback: "Manage devices")
          }
          internal enum ManageScreen {
            /// Remove a device
            internal static let title = L10n.tr("Localizable", "registration.signin.too_many_devices.manage_screen.title", fallback: "Remove a device")
          }
          internal enum SignOutButton {
            /// Log out
            internal static let title = L10n.tr("Localizable", "registration.signin.too_many_devices.sign_out_button.title", fallback: "Log out")
          }
        }
        internal enum Username {
          /// Enter your username. It helps others to find you in Wire and connect with you.
          internal static let message = L10n.tr("Localizable", "registration.signin.username.message", fallback: "Enter your username. It helps others to find you in Wire and connect with you.")
          /// username
          internal static let placeholder = L10n.tr("Localizable", "registration.signin.username.placeholder", fallback: "username")
          /// Your username
          internal static let title = L10n.tr("Localizable", "registration.signin.username.title", fallback: "Your username")
          internal enum AlreadyTakenError {
            /// The username is already taken, please try another one
            internal static let message = L10n.tr("Localizable", "registration.signin.username.already_taken_error.message", fallback: "The username is already taken, please try another one")
            /// Username is already taken
            internal static let title = L10n.tr("Localizable", "registration.signin.username.already_taken_error.title", fallback: "Username is already taken")
          }
          internal enum UnknownError {
            /// Please try again later.
            internal static let message = L10n.tr("Localizable", "registration.signin.username.unknown_error.message", fallback: "Please try again later.")
            /// Couldn't update username
            internal static let title = L10n.tr("Localizable", "registration.signin.username.unknown_error.title", fallback: "Couldn't update username")
          }
        }
      }
      internal enum TermsOfUse {
        /// Accept
        internal static let accept = L10n.tr("Localizable", "registration.terms_of_use.accept", fallback: "Accept")
        /// I agree
        internal static let agree = L10n.tr("Localizable", "registration.terms_of_use.agree", fallback: "I agree")
        /// By continuing you agree to the Wire Terms of Use.
        internal static let terms = L10n.tr("Localizable", "registration.terms_of_use.terms", fallback: "By continuing you agree to the Wire Terms of Use.")
        /// Welcome to Wire.
        internal static let title = L10n.tr("Localizable", "registration.terms_of_use.title", fallback: "Welcome to Wire.")
        internal enum Terms {
          /// Terms of Use
          internal static let link = L10n.tr("Localizable", "registration.terms_of_use.terms.link", fallback: "Terms of Use")
          /// Please accept the Terms of Use to continue.
          internal static let message = L10n.tr("Localizable", "registration.terms_of_use.terms.message", fallback: "Please accept the Terms of Use to continue.")
          /// Terms of Use
          internal static let title = L10n.tr("Localizable", "registration.terms_of_use.terms.title", fallback: "Terms of Use")
          /// View
          internal static let view = L10n.tr("Localizable", "registration.terms_of_use.terms.view", fallback: "View")
        }
      }
      internal enum VerifyEmail {
        /// We sent an email to %@.
        ///  Follow the link to verify your address.
        internal static func instructions(_ p1: Any) -> String {
          return L10n.tr("Localizable", "registration.verify_email.instructions", String(describing: p1), fallback: "We sent an email to %@.\n Follow the link to verify your address.")
        }
        internal enum Resend {
          /// Re-send
          internal static let buttonTitle = L10n.tr("Localizable", "registration.verify_email.resend.button_title", fallback: "Re-send")
          /// Didn’t get the message?
          internal static let instructions = L10n.tr("Localizable", "registration.verify_email.resend.instructions", fallback: "Didn’t get the message?")
        }
      }
    }
    internal enum RevokedCertificate {
      internal enum Alert {
        /// Continue Using This Device
        internal static let `continue` = L10n.tr("Localizable", "revoked_certificate.alert.continue", fallback: "Continue Using This Device")
        /// Log out
        internal static let logOut = L10n.tr("Localizable", "revoked_certificate.alert.log_out", fallback: "Log out")
        /// Log out to reduce security risks. Then log in again, get a new certificate, and reset your password. If you keep using this device, your conversations are no longer verified.
        internal static let message = L10n.tr("Localizable", "revoked_certificate.alert.message", fallback: "Log out to reduce security risks. Then log in again, get a new certificate, and reset your password. If you keep using this device, your conversations are no longer verified.")
        /// End-to-end certificate revoked
        internal static let title = L10n.tr("Localizable", "revoked_certificate.alert.title", fallback: "End-to-end certificate revoked")
      }
    }
    internal enum SecuredGuestLinkWithPassword {
      internal enum AlertController {
        /// The password was copied to your device clipboard.
        internal static let message = L10n.tr("Localizable", "secured_guest_link_with_password.alertController.message", fallback: "The password was copied to your device clipboard.")
        /// Password copied
        internal static let title = L10n.tr("Localizable", "secured_guest_link_with_password.alertController.title", fallback: "Password copied")
      }
      internal enum CreateLinkButton {
        /// Create Link
        internal static let title = L10n.tr("Localizable", "secured_guest_link_with_password.createLinkButton.title", fallback: "Create Link")
      }
      internal enum GeneratePasswordButton {
        /// Generate password
        internal static let title = L10n.tr("Localizable", "secured_guest_link_with_password.generate_password_button.title", fallback: "Generate password")
      }
      internal enum Header {
        /// Create password secured link
        internal static let title = L10n.tr("Localizable", "secured_guest_link_with_password.header.title", fallback: "Create password secured link")
      }
      internal enum Textfield {
        /// Use at least 15 characters, with one lowercase letter, one capital letter, a number, and a special character.
        internal static let footer = L10n.tr("Localizable", "secured_guest_link_with_password.textfield.footer", fallback: "Use at least 15 characters, with one lowercase letter, one capital letter, a number, and a special character.")
        /// Set password
        internal static let header = L10n.tr("Localizable", "secured_guest_link_with_password.textfield.header", fallback: "Set password")
        /// Enter password
        internal static let placeholder = L10n.tr("Localizable", "secured_guest_link_with_password.textfield.placeholder", fallback: "Enter password")
      }
      internal enum VerifyPasswordTextField {
        /// Confirm password
        internal static let header = L10n.tr("Localizable", "secured_guest_link_with_password.verifyPasswordTextField.header", fallback: "Confirm password")
        /// Confirm your password
        internal static let placeholder = L10n.tr("Localizable", "secured_guest_link_with_password.verifyPasswordTextField.placeholder", fallback: "Confirm your password")
      }
      internal enum WarningLabel {
        /// People who want to join the conversation via the guest link need to enter this password first.
        /// **You can’t change the password later. Make sure to copy and store it.**
        internal static let title = L10n.tr("Localizable", "secured_guest_link_with_password.warning_label.title", fallback: "People who want to join the conversation via the guest link need to enter this password first.\n**You can’t change the password later. Make sure to copy and store it.**")
      }
    }
    internal enum SecurityClassification {
      /// Security level:
      internal static let securityLevel = L10n.tr("Localizable", "security_classification.security_level", fallback: "Security level:")
      internal enum Level {
        /// VS-NfD
        internal static let bund = L10n.tr("Localizable", "security_classification.level.bund", fallback: "VS-NfD")
        /// UNCLASSIFIED
        internal static let notClassified = L10n.tr("Localizable", "security_classification.level.not_classified", fallback: "UNCLASSIFIED")
      }
    }
    internal enum `Self` {
      /// About
      internal static let about = L10n.tr("Localizable", "self.about", fallback: "About")
      /// Account
      internal static let account = L10n.tr("Localizable", "self.account", fallback: "Account")
      /// Add email address and password
      internal static let addEmailPassword = L10n.tr("Localizable", "self.add_email_password", fallback: "Add email address and password")
      /// Support
      internal static let helpCenter = L10n.tr("Localizable", "self.help_center", fallback: "Support")
      /// Profile
      internal static let profile = L10n.tr("Localizable", "self.profile", fallback: "Profile")
      /// Report Misuse
      internal static let reportAbuse = L10n.tr("Localizable", "self.report_abuse", fallback: "Report Misuse")
      /// Settings
      internal static let settings = L10n.tr("Localizable", "self.settings", fallback: "Settings")
      /// Log Out
      internal static let signOut = L10n.tr("Localizable", "self.sign_out", fallback: "Log Out")
      internal enum HelpCenter {
        /// Contact Support
        internal static let contactSupport = L10n.tr("Localizable", "self.help_center.contact_support", fallback: "Contact Support")
        /// Wire Support Website
        internal static let supportWebsite = L10n.tr("Localizable", "self.help_center.support_website", fallback: "Wire Support Website")
      }
      internal enum NewDevice {
        internal enum Voiceover {
          /// Profile, new devices added
          internal static let label = L10n.tr("Localizable", "self.new-device.voiceover.label", fallback: "Profile, new devices added")
        }
      }
      internal enum NewDeviceAlert {
        /// Manage devices
        internal static let manageDevices = L10n.tr("Localizable", "self.new_device_alert.manage_devices", fallback: "Manage devices")
        /// 
        /// %@
        /// 
        /// If you don’t recognize the device above, remove it and reset your password.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "self.new_device_alert.message", String(describing: p1), fallback: "\n%@\n\nIf you don’t recognize the device above, remove it and reset your password.")
        }
        /// 
        /// %@
        /// 
        /// If you don’t recognize the devices above, remove them and reset your password.
        internal static func messagePlural(_ p1: Any) -> String {
          return L10n.tr("Localizable", "self.new_device_alert.message_plural", String(describing: p1), fallback: "\n%@\n\nIf you don’t recognize the devices above, remove them and reset your password.")
        }
        /// Your account was used on:
        internal static let title = L10n.tr("Localizable", "self.new_device_alert.title", fallback: "Your account was used on:")
        /// OK
        internal static let trustDevices = L10n.tr("Localizable", "self.new_device_alert.trust_devices", fallback: "OK")
        internal enum TitlePrefix {
          /// Plural format key: "%#@device_count@"
          internal static func devices(_ p1: Int) -> String {
            return L10n.tr("Localizable", "self.new_device_alert.title_prefix.devices", p1, fallback: "Plural format key: \"%#@device_count@\"")
          }
        }
      }
      internal enum ReadReceiptsDescription {
        /// You can change this option in your account settings.
        internal static let title = L10n.tr("Localizable", "self.read_receipts_description.title", fallback: "You can change this option in your account settings.")
      }
      internal enum ReadReceiptsDisabled {
        /// You have disabled read receipts
        internal static let title = L10n.tr("Localizable", "self.read_receipts_disabled.title", fallback: "You have disabled read receipts")
      }
      internal enum ReadReceiptsEnabled {
        /// You have enabled read receipts
        internal static let title = L10n.tr("Localizable", "self.read_receipts_enabled.title", fallback: "You have enabled read receipts")
      }
      internal enum Settings {
        /// Account
        internal static let accountSection = L10n.tr("Localizable", "self.settings.account_section", fallback: "Account")
        internal enum Account {
          internal enum DataUsagePermissions {
            /// Data Usage Permissions
            internal static let title = L10n.tr("Localizable", "self.settings.account.data_usage_permissions.title", fallback: "Data Usage Permissions")
          }
        }
        internal enum AccountAppearanceGroup {
          /// Appearance
          internal static let title = L10n.tr("Localizable", "self.settings.account_appearance_group.title", fallback: "Appearance")
        }
        internal enum AccountDetails {
          internal enum Actions {
            /// Actions
            internal static let title = L10n.tr("Localizable", "self.settings.account_details.actions.title", fallback: "Actions")
          }
          internal enum DeleteAccount {
            /// Delete Account
            internal static let title = L10n.tr("Localizable", "self.settings.account_details.delete_account.title", fallback: "Delete Account")
            internal enum Alert {
              /// We will send you a message via email or SMS. Follow the link to permanently delete your account.
              internal static let message = L10n.tr("Localizable", "self.settings.account_details.delete_account.alert.message", fallback: "We will send you a message via email or SMS. Follow the link to permanently delete your account.")
              /// Delete Account
              internal static let title = L10n.tr("Localizable", "self.settings.account_details.delete_account.alert.title", fallback: "Delete Account")
            }
          }
          internal enum KeyFingerprint {
            /// Key Fingerprint
            internal static let title = L10n.tr("Localizable", "self.settings.account_details.key_fingerprint.title", fallback: "Key Fingerprint")
          }
          internal enum LogOut {
            internal enum Alert {
              /// Your message history will be erased on this device.
              internal static let message = L10n.tr("Localizable", "self.settings.account_details.log_out.alert.message", fallback: "Your message history will be erased on this device.")
              /// Password
              internal static let password = L10n.tr("Localizable", "self.settings.account_details.log_out.alert.password", fallback: "Password")
              /// Log out
              internal static let title = L10n.tr("Localizable", "self.settings.account_details.log_out.alert.title", fallback: "Log out")
            }
          }
          internal enum RemoveDevice {
            /// Your password is required to remove the device
            internal static let message = L10n.tr("Localizable", "self.settings.account_details.remove_device.message", fallback: "Your password is required to remove the device")
            /// Password
            internal static let password = L10n.tr("Localizable", "self.settings.account_details.remove_device.password", fallback: "Password")
            /// Remove Device
            internal static let title = L10n.tr("Localizable", "self.settings.account_details.remove_device.title", fallback: "Remove Device")
            internal enum Password {
              /// Wrong password
              internal static let error = L10n.tr("Localizable", "self.settings.account_details.remove_device.password.error", fallback: "Wrong password")
            }
          }
        }
        internal enum AccountDetailsGroup {
          internal enum Info {
            /// People can find you with these details.
            internal static let footer = L10n.tr("Localizable", "self.settings.account_details_group.info.footer", fallback: "People can find you with these details.")
            /// Info
            internal static let title = L10n.tr("Localizable", "self.settings.account_details_group.info.title", fallback: "Info")
          }
          internal enum Personal {
            /// This information is not visible .
            internal static let footer = L10n.tr("Localizable", "self.settings.account_details_group.personal.footer", fallback: "This information is not visible .")
            /// Personal
            internal static let title = L10n.tr("Localizable", "self.settings.account_details_group.personal.title", fallback: "Personal")
          }
        }
        internal enum AccountPersonalInformationGroup {
          /// Personal Information
          internal static let title = L10n.tr("Localizable", "self.settings.account_personal_information_group.title", fallback: "Personal Information")
        }
        internal enum AccountPictureGroup {
          /// Profile color
          internal static let color = L10n.tr("Localizable", "self.settings.account_picture_group.color", fallback: "Profile color")
          /// Profile picture
          internal static let picture = L10n.tr("Localizable", "self.settings.account_picture_group.picture", fallback: "Profile picture")
          /// Theme
          internal static let theme = L10n.tr("Localizable", "self.settings.account_picture_group.theme", fallback: "Theme")
          internal enum AccentColor {
            /// Amber
            internal static let amber = L10n.tr("Localizable", "self.settings.account_picture_group.accent_color.amber", fallback: "Amber")
            /// Blue
            internal static let blue = L10n.tr("Localizable", "self.settings.account_picture_group.accent_color.blue", fallback: "Blue")
            /// Green
            internal static let green = L10n.tr("Localizable", "self.settings.account_picture_group.accent_color.green", fallback: "Green")
            /// Purple
            internal static let purple = L10n.tr("Localizable", "self.settings.account_picture_group.accent_color.purple", fallback: "Purple")
            /// Red
            internal static let red = L10n.tr("Localizable", "self.settings.account_picture_group.accent_color.red", fallback: "Red")
            /// Turquoise
            internal static let turquoise = L10n.tr("Localizable", "self.settings.account_picture_group.accent_color.turquoise", fallback: "Turquoise")
          }
          internal enum Alert {
            /// Choose from Library
            internal static let choosePicture = L10n.tr("Localizable", "self.settings.account_picture_group.alert.choose_picture", fallback: "Choose from Library")
            /// Take Photo
            internal static let takePicture = L10n.tr("Localizable", "self.settings.account_picture_group.alert.take_picture", fallback: "Take Photo")
            /// Change your profile picture
            internal static let title = L10n.tr("Localizable", "self.settings.account_picture_group.alert.title", fallback: "Change your profile picture")
          }
        }
        internal enum AccountSection {
          internal enum AddHandle {
            /// Add username
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.add_handle.title", fallback: "Add username")
          }
          internal enum Domain {
            /// Domain
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.domain.title", fallback: "Domain")
          }
          internal enum Email {
            /// Email
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.email.title", fallback: "Email")
            internal enum Change {
              /// Save
              internal static let save = L10n.tr("Localizable", "self.settings.account_section.email.change.save", fallback: "Save")
              /// Email
              internal static let title = L10n.tr("Localizable", "self.settings.account_section.email.change.title", fallback: "Email")
              internal enum Resend {
                /// Confirmation email was resent to %@. Check your email inbox and follow the instructions.
                internal static func message(_ p1: Any) -> String {
                  return L10n.tr("Localizable", "self.settings.account_section.email.change.resend.message", String(describing: p1), fallback: "Confirmation email was resent to %@. Check your email inbox and follow the instructions.")
                }
                /// Email resent
                internal static let title = L10n.tr("Localizable", "self.settings.account_section.email.change.resend.title", fallback: "Email resent")
              }
              internal enum Verify {
                /// Check your email inbox and follow the instructions.
                internal static let description = L10n.tr("Localizable", "self.settings.account_section.email.change.verify.description", fallback: "Check your email inbox and follow the instructions.")
                /// Resend to %@
                internal static func resend(_ p1: Any) -> String {
                  return L10n.tr("Localizable", "self.settings.account_section.email.change.verify.resend", String(describing: p1), fallback: "Resend to %@")
                }
                /// Verify email
                internal static let title = L10n.tr("Localizable", "self.settings.account_section.email.change.verify.title", fallback: "Verify email")
              }
            }
          }
          internal enum Handle {
            /// Username
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.handle.title", fallback: "Username")
            internal enum Change {
              /// At least 2 characters. a—z, 0—9, and  '.', '-', '_'  only.
              internal static let footer = L10n.tr("Localizable", "self.settings.account_section.handle.change.footer", fallback: "At least 2 characters. a—z, 0—9, and  '.', '-', '_'  only.")
              /// Save
              internal static let save = L10n.tr("Localizable", "self.settings.account_section.handle.change.save", fallback: "Save")
              /// Username
              internal static let title = L10n.tr("Localizable", "self.settings.account_section.handle.change.title", fallback: "Username")
              internal enum FailureAlert {
                /// There was an error setting your username. Please try again.
                internal static let message = L10n.tr("Localizable", "self.settings.account_section.handle.change.failure_alert.message", fallback: "There was an error setting your username. Please try again.")
                /// Unable to set username
                internal static let title = L10n.tr("Localizable", "self.settings.account_section.handle.change.failure_alert.title", fallback: "Unable to set username")
              }
              internal enum Footer {
                /// Already taken
                internal static let unavailable = L10n.tr("Localizable", "self.settings.account_section.handle.change.footer.unavailable", fallback: "Already taken")
              }
            }
          }
          internal enum Name {
            /// Name
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.name.title", fallback: "Name")
          }
          internal enum ProfileLink {
            /// Profile link
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.profile_link.title", fallback: "Profile link")
            internal enum Actions {
              /// Profile Link Copied!
              internal static let copiedLink = L10n.tr("Localizable", "self.settings.account_section.profile_link.actions.copied_link", fallback: "Profile Link Copied!")
              /// Copy Profile Link
              internal static let copyLink = L10n.tr("Localizable", "self.settings.account_section.profile_link.actions.copy_link", fallback: "Copy Profile Link")
            }
          }
          internal enum Team {
            /// Team
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.team.title", fallback: "Team")
          }
        }
        internal enum AddAccount {
          /// Add an account
          internal static let title = L10n.tr("Localizable", "self.settings.add_account.title", fallback: "Add an account")
          internal enum Error {
            /// You can only be logged in with three accounts at once. Log out from one to add another.
            internal static let message = L10n.tr("Localizable", "self.settings.add_account.error.message", fallback: "You can only be logged in with three accounts at once. Log out from one to add another.")
            /// Three accounts active
            internal static let title = L10n.tr("Localizable", "self.settings.add_account.error.title", fallback: "Three accounts active")
          }
        }
        internal enum AddTeamOrAccount {
          /// Add Account
          internal static let title = L10n.tr("Localizable", "self.settings.add_team_or_account.title", fallback: "Add Account")
        }
        internal enum Advanced {
          /// Advanced
          internal static let title = L10n.tr("Localizable", "self.settings.advanced.title", fallback: "Advanced")
          internal enum DebuggingTools {
            /// Debugging Tools
            internal static let title = L10n.tr("Localizable", "self.settings.advanced.debugging_tools.title", fallback: "Debugging Tools")
            internal enum EnterDebugCommand {
              /// Enter debug command
              internal static let title = L10n.tr("Localizable", "self.settings.advanced.debugging_tools.enter_debug_command.title", fallback: "Enter debug command")
            }
            internal enum FirstUnreadConversation {
              /// Find first unread conversation
              internal static let title = L10n.tr("Localizable", "self.settings.advanced.debugging_tools.first_unread_conversation.title", fallback: "Find first unread conversation")
            }
            internal enum ShowUserId {
              /// Show my user ID
              internal static let title = L10n.tr("Localizable", "self.settings.advanced.debugging_tools.show_user_id.title", fallback: "Show my user ID")
            }
          }
          internal enum ResetPushToken {
            /// If you experience problems with push notifications, Wire Support may ask you to reset this token.
            internal static let subtitle = L10n.tr("Localizable", "self.settings.advanced.reset_push_token.subtitle", fallback: "If you experience problems with push notifications, Wire Support may ask you to reset this token.")
            /// Reset Push Notifications Token
            internal static let title = L10n.tr("Localizable", "self.settings.advanced.reset_push_token.title", fallback: "Reset Push Notifications Token")
          }
          internal enum ResetPushTokenAlert {
            /// Notifications will be restored in a few seconds.
            internal static let message = L10n.tr("Localizable", "self.settings.advanced.reset_push_token_alert.message", fallback: "Notifications will be restored in a few seconds.")
            /// Push token has been reset
            internal static let title = L10n.tr("Localizable", "self.settings.advanced.reset_push_token_alert.title", fallback: "Push token has been reset")
          }
          internal enum Troubleshooting {
            /// Troubleshooting
            internal static let title = L10n.tr("Localizable", "self.settings.advanced.troubleshooting.title", fallback: "Troubleshooting")
            internal enum SubmitDebug {
              /// This information helps Wire Support diagnose calling problems and improve the overall app experience.
              internal static let subtitle = L10n.tr("Localizable", "self.settings.advanced.troubleshooting.submit_debug.subtitle", fallback: "This information helps Wire Support diagnose calling problems and improve the overall app experience.")
              /// Debug Report
              internal static let title = L10n.tr("Localizable", "self.settings.advanced.troubleshooting.submit_debug.title", fallback: "Debug Report")
            }
          }
        }
        internal enum ApnsLogging {
          /// APNS Logging
          internal static let title = L10n.tr("Localizable", "self.settings.apns_logging.title", fallback: "APNS Logging")
        }
        internal enum Callkit {
          /// Share with iOS
          internal static let caption = L10n.tr("Localizable", "self.settings.callkit.caption", fallback: "Share with iOS")
          /// Show Wire calls on the lock screen and in iOS call history. If iCloud is enabled, call history is shared with Apple.
          internal static let description = L10n.tr("Localizable", "self.settings.callkit.description", fallback: "Show Wire calls on the lock screen and in iOS call history. If iCloud is enabled, call history is shared with Apple.")
          /// Calls
          internal static let title = L10n.tr("Localizable", "self.settings.callkit.title", fallback: "Calls")
        }
        internal enum Conversations {
          /// History
          internal static let title = L10n.tr("Localizable", "self.settings.conversations.title", fallback: "History")
        }
        internal enum CreateTeam {
          /// Create a team
          internal static let title = L10n.tr("Localizable", "self.settings.create_team.title", fallback: "Create a team")
        }
        internal enum DeveloperOptions {
          /// Developer Options
          internal static let title = L10n.tr("Localizable", "self.settings.developer_options.title", fallback: "Developer Options")
          internal enum DatabaseStatistics {
            /// Database Statistics
            internal static let title = L10n.tr("Localizable", "self.settings.developer_options.database_statistics.title", fallback: "Database Statistics")
          }
          internal enum Loggin {
            /// Options
            internal static let title = L10n.tr("Localizable", "self.settings.developer_options.loggin.title", fallback: "Options")
          }
        }
        internal enum DeviceDetails {
          internal enum Fingerprint {
            /// Wire gives every device a unique fingerprint. Compare them and verify your devices and conversations.
            internal static let subtitle = L10n.tr("Localizable", "self.settings.device_details.fingerprint.subtitle", fallback: "Wire gives every device a unique fingerprint. Compare them and verify your devices and conversations.")
          }
          internal enum RemoveDevice {
            /// Remove this device if you have stopped using it. You will be logged out of this device immediately.
            internal static let subtitle = L10n.tr("Localizable", "self.settings.device_details.remove_device.subtitle", fallback: "Remove this device if you have stopped using it. You will be logged out of this device immediately.")
          }
          internal enum ResetSession {
            /// If fingerprints don’t match, reset the session to generate new encryption keys on both sides.
            internal static let subtitle = L10n.tr("Localizable", "self.settings.device_details.reset_session.subtitle", fallback: "If fingerprints don’t match, reset the session to generate new encryption keys on both sides.")
            /// The session has been reset
            internal static let success = L10n.tr("Localizable", "self.settings.device_details.reset_session.success", fallback: "The session has been reset")
          }
        }
        internal enum EnableReadReceipts {
          /// Send Read Receipts
          internal static let title = L10n.tr("Localizable", "self.settings.enable_read_receipts.title", fallback: "Send Read Receipts")
        }
        internal enum EncryptMessagesAtRest {
          /// Encrypt messages at rest
          internal static let title = L10n.tr("Localizable", "self.settings.encrypt_messages_at_rest.title", fallback: "Encrypt messages at rest")
        }
        internal enum ExternalApps {
          /// Open With
          internal static let header = L10n.tr("Localizable", "self.settings.external_apps.header", fallback: "Open With")
        }
        internal enum HistoryBackup {
          /// Back Up Now
          internal static let action = L10n.tr("Localizable", "self.settings.history_backup.action", fallback: "Back Up Now")
          /// Create a backup to preserve your conversation history. You can use this to restore history if you lose your device or switch to a new one.
          /// 
          /// Choose a strong password to protect the backup file.
          internal static let description = L10n.tr("Localizable", "self.settings.history_backup.description", fallback: "Create a backup to preserve your conversation history. You can use this to restore history if you lose your device or switch to a new one.\n\nChoose a strong password to protect the backup file.")
          /// Back Up Conversations
          internal static let title = L10n.tr("Localizable", "self.settings.history_backup.title", fallback: "Back Up Conversations")
          internal enum Error {
            /// Error
            internal static let title = L10n.tr("Localizable", "self.settings.history_backup.error.title", fallback: "Error")
          }
          internal enum Password {
            /// Cancel
            internal static let cancel = L10n.tr("Localizable", "self.settings.history_backup.password.cancel", fallback: "Cancel")
            /// The backup will be compressed and encrypted with the password you set here.
            internal static let description = L10n.tr("Localizable", "self.settings.history_backup.password.description", fallback: "The backup will be compressed and encrypted with the password you set here.")
            /// Next
            internal static let next = L10n.tr("Localizable", "self.settings.history_backup.password.next", fallback: "Next")
            /// Password
            internal static let placeholder = L10n.tr("Localizable", "self.settings.history_backup.password.placeholder", fallback: "Password")
            /// Set Password
            internal static let title = L10n.tr("Localizable", "self.settings.history_backup.password.title", fallback: "Set Password")
          }
          internal enum SetEmail {
            /// You need an email and a password in order to back up your conversation history. You can do it from the account page in Settings.
            internal static let message = L10n.tr("Localizable", "self.settings.history_backup.set_email.message", fallback: "You need an email and a password in order to back up your conversation history. You can do it from the account page in Settings.")
            /// Set an email and password.
            internal static let title = L10n.tr("Localizable", "self.settings.history_backup.set_email.title", fallback: "Set an email and password.")
          }
        }
        internal enum InviteFriends {
          /// Invite people
          internal static let title = L10n.tr("Localizable", "self.settings.invite_friends.title", fallback: "Invite people")
        }
        internal enum LinkOptions {
          internal enum Browser {
            /// Browser
            internal static let title = L10n.tr("Localizable", "self.settings.link_options.browser.title", fallback: "Browser")
          }
          internal enum Maps {
            /// Locations
            internal static let title = L10n.tr("Localizable", "self.settings.link_options.maps.title", fallback: "Locations")
          }
          internal enum Twitter {
            /// Tweets
            internal static let title = L10n.tr("Localizable", "self.settings.link_options.twitter.title", fallback: "Tweets")
          }
        }
        internal enum ManageTeam {
          /// Manage Team
          internal static let title = L10n.tr("Localizable", "self.settings.manage_team.title", fallback: "Manage Team")
        }
        internal enum MuteOtherCall {
          /// Silence other calls
          internal static let caption = L10n.tr("Localizable", "self.settings.mute_other_call.caption", fallback: "Silence other calls")
          /// Enable to silence incoming calls when you are already in an ongoing call.
          internal static let description = L10n.tr("Localizable", "self.settings.mute_other_call.description", fallback: "Enable to silence incoming calls when you are already in an ongoing call.")
        }
        internal enum Notifications {
          internal enum ChatAlerts {
            /// New messages in other conversations.
            internal static let footer = L10n.tr("Localizable", "self.settings.notifications.chat_alerts.footer", fallback: "New messages in other conversations.")
            /// Message Banners
            internal static let toggle = L10n.tr("Localizable", "self.settings.notifications.chat_alerts.toggle", fallback: "Message Banners")
          }
          internal enum PushNotification {
            /// Sender name and message on the lock screen and in Notification Center.
            internal static let footer = L10n.tr("Localizable", "self.settings.notifications.push_notification.footer", fallback: "Sender name and message on the lock screen and in Notification Center.")
            /// Notifications
            internal static let title = L10n.tr("Localizable", "self.settings.notifications.push_notification.title", fallback: "Notifications")
            /// Message Previews
            internal static let toogle = L10n.tr("Localizable", "self.settings.notifications.push_notification.toogle", fallback: "Message Previews")
          }
        }
        internal enum OptionsMenu {
          /// Options
          internal static let title = L10n.tr("Localizable", "self.settings.options_menu.title", fallback: "Options")
        }
        internal enum PasswordResetMenu {
          /// Reset Password
          internal static let title = L10n.tr("Localizable", "self.settings.password_reset_menu.title", fallback: "Reset Password")
        }
        internal enum PopularDemand {
          /// By popular demand
          internal static let title = L10n.tr("Localizable", "self.settings.popular_demand.title", fallback: "By popular demand")
          internal enum DarkMode {
            /// Switch between dark and light theme.
            internal static let footer = L10n.tr("Localizable", "self.settings.popular_demand.dark_mode.footer", fallback: "Switch between dark and light theme.")
          }
          internal enum SendButton {
            /// Disable to send via the return key.
            internal static let footer = L10n.tr("Localizable", "self.settings.popular_demand.send_button.footer", fallback: "Disable to send via the return key.")
            /// Send Button
            internal static let title = L10n.tr("Localizable", "self.settings.popular_demand.send_button.title", fallback: "Send Button")
          }
        }
        internal enum Privacy {
          internal enum ClearHistory {
            /// This will permanently erase the content of all your conversations.
            internal static let subtitle = L10n.tr("Localizable", "self.settings.privacy.clear_history.subtitle", fallback: "This will permanently erase the content of all your conversations.")
            /// Clear History
            internal static let title = L10n.tr("Localizable", "self.settings.privacy.clear_history.title", fallback: "Clear History")
          }
        }
        internal enum PrivacyAnalytics {
          /// Send anonymous usage data
          internal static let title = L10n.tr("Localizable", "self.settings.privacy_analytics.title", fallback: "Send anonymous usage data")
        }
        internal enum PrivacyAnalyticsMenu {
          internal enum Description {
            /// Usage data allows Wire to understand how the app is being used and how it can be improved. The data is anonymous and does not include the content of your communications (such as messages, files or calls).
            internal static let title = L10n.tr("Localizable", "self.settings.privacy_analytics_menu.description.title", fallback: "Usage data allows Wire to understand how the app is being used and how it can be improved. The data is anonymous and does not include the content of your communications (such as messages, files or calls).")
          }
          internal enum Devices {
            /// Devices
            internal static let title = L10n.tr("Localizable", "self.settings.privacy_analytics_menu.devices.title", fallback: "Devices")
          }
        }
        internal enum PrivacyAnalyticsSection {
          /// Usage and Crash Reports
          internal static let title = L10n.tr("Localizable", "self.settings.privacy_analytics_section.title", fallback: "Usage and Crash Reports")
        }
        internal enum PrivacyContactsMenu {
          internal enum DescriptionDisabled {
            /// This helps you connect with others. We anonymize all the information and do not share it with anyone else. Allow access via Settings > Privacy > Contacts.
            internal static let title = L10n.tr("Localizable", "self.settings.privacy_contacts_menu.description_disabled.title", fallback: "This helps you connect with others. We anonymize all the information and do not share it with anyone else. Allow access via Settings > Privacy > Contacts.")
          }
          internal enum SettingsButton {
            /// Open Contacts Settings
            internal static let title = L10n.tr("Localizable", "self.settings.privacy_contacts_menu.settings_button.title", fallback: "Open Contacts Settings")
          }
        }
        internal enum PrivacyContactsSection {
          /// Contacts
          internal static let title = L10n.tr("Localizable", "self.settings.privacy_contacts_section.title", fallback: "Contacts")
        }
        internal enum PrivacySectionGroup {
          /// When this is off, you won’t be able to see read receipts from other people.
          /// 
          /// This setting does not apply to group conversations.
          internal static let subtitle = L10n.tr("Localizable", "self.settings.privacy_section_group.subtitle", fallback: "When this is off, you won’t be able to see read receipts from other people.\n\nThis setting does not apply to group conversations.")
          /// Privacy
          internal static let title = L10n.tr("Localizable", "self.settings.privacy_section_group.title", fallback: "Privacy")
        }
        internal enum PrivacySecurity {
          /// Lock With Passcode
          internal static let lockApp = L10n.tr("Localizable", "self.settings.privacy_security.lock_app", fallback: "Lock With Passcode")
          internal enum DisableLinkPreviews {
            /// Previews may still be shown for links from other people.
            internal static let footer = L10n.tr("Localizable", "self.settings.privacy_security.disable_link_previews.footer", fallback: "Previews may still be shown for links from other people.")
            /// Create Link Previews
            internal static let title = L10n.tr("Localizable", "self.settings.privacy_security.disable_link_previews.title", fallback: "Create Link Previews")
          }
          internal enum LockApp {
            /// Unlock Wire
            internal static let description = L10n.tr("Localizable", "self.settings.privacy_security.lock_app.description", fallback: "Unlock Wire")
            internal enum Subtitle {
              /// If forgotten, your passcode can not be recovered.
              internal static let customAppLockReminder = L10n.tr("Localizable", "self.settings.privacy_security.lock_app.subtitle.custom_app_lock_reminder", fallback: "If forgotten, your passcode can not be recovered.")
              /// Unlock with Face ID or enter your passcode.
              internal static let faceId = L10n.tr("Localizable", "self.settings.privacy_security.lock_app.subtitle.face_id", fallback: "Unlock with Face ID or enter your passcode.")
              /// Lock Wire after %@ in the background.
              internal static func lockDescription(_ p1: Any) -> String {
                return L10n.tr("Localizable", "self.settings.privacy_security.lock_app.subtitle.lock_description", String(describing: p1), fallback: "Lock Wire after %@ in the background.")
              }
              /// Unlock by entering your passcode.
              internal static let `none` = L10n.tr("Localizable", "self.settings.privacy_security.lock_app.subtitle.none", fallback: "Unlock by entering your passcode.")
              /// Unlock with Touch ID or enter your passcode.
              internal static let touchId = L10n.tr("Localizable", "self.settings.privacy_security.lock_app.subtitle.touch_id", fallback: "Unlock with Touch ID or enter your passcode.")
            }
          }
          internal enum LockPassword {
            internal enum Description {
              /// Unlock with your password.
              internal static let unlock = L10n.tr("Localizable", "self.settings.privacy_security.lock_password.description.unlock", fallback: "Unlock with your password.")
              /// Wrong password. If you recently changed your password, connect to the internet and try again.
              internal static let wrongOfflinePassword = L10n.tr("Localizable", "self.settings.privacy_security.lock_password.description.wrong_offline_password", fallback: "Wrong password. If you recently changed your password, connect to the internet and try again.")
              /// Wrong password. Please try again.
              internal static let wrongPassword = L10n.tr("Localizable", "self.settings.privacy_security.lock_password.description.wrong_password", fallback: "Wrong password. Please try again.")
            }
          }
        }
        internal enum ReceiveNewsAndOffers {
          /// Receive Newsletter
          internal static let title = L10n.tr("Localizable", "self.settings.receiveNews_and_offers.title", fallback: "Receive Newsletter")
          internal enum Description {
            /// Receive news and product updates from Wire via email.
            internal static let title = L10n.tr("Localizable", "self.settings.receiveNews_and_offers.description.title", fallback: "Receive news and product updates from Wire via email.")
          }
        }
        internal enum SoundMenu {
          /// Sound Alerts
          internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.title", fallback: "Sound Alerts")
          internal enum AllSounds {
            /// All
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.all_sounds.title", fallback: "All")
          }
          internal enum Message {
            /// Text Tone
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.message.title", fallback: "Text Tone")
          }
          internal enum MuteWhileTalking {
            /// First message and pings
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.mute_while_talking.title", fallback: "First message and pings")
          }
          internal enum NoSounds {
            /// None
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.no_sounds.title", fallback: "None")
          }
          internal enum Ping {
            /// Ping
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.ping.title", fallback: "Ping")
          }
          internal enum Ringtone {
            /// Ringtone
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.ringtone.title", fallback: "Ringtone")
          }
          internal enum Ringtones {
            /// Ringtones
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.ringtones.title", fallback: "Ringtones")
          }
          internal enum Sounds {
            /// None
            internal static let `none` = L10n.tr("Localizable", "self.settings.sound_menu.sounds.none", fallback: "None")
            /// Sounds
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.sounds.title", fallback: "Sounds")
            /// Wire Call
            internal static let wireCall = L10n.tr("Localizable", "self.settings.sound_menu.sounds.wire_call", fallback: "Wire Call")
            /// Wire Message
            internal static let wireMessage = L10n.tr("Localizable", "self.settings.sound_menu.sounds.wire_message", fallback: "Wire Message")
            /// Wire Ping
            internal static let wirePing = L10n.tr("Localizable", "self.settings.sound_menu.sounds.wire_ping", fallback: "Wire Ping")
            /// Wire
            internal static let wireSound = L10n.tr("Localizable", "self.settings.sound_menu.sounds.wire_sound", fallback: "Wire")
          }
        }
        internal enum SwitchAccount {
          /// Switch anyway
          internal static let action = L10n.tr("Localizable", "self.settings.switch_account.action", fallback: "Switch anyway")
          /// A call is active in this account.
          /// Switching accounts will hang up the current call.
          internal static let message = L10n.tr("Localizable", "self.settings.switch_account.message", fallback: "A call is active in this account.\nSwitching accounts will hang up the current call.")
        }
        internal enum TechnicalReport {
          /// Include detailed log
          internal static let includeLog = L10n.tr("Localizable", "self.settings.technical_report.include_log", fallback: "Include detailed log")
          /// If you encounter unexpected behaviour or a bug while using Wire, you can send a bug report to our support team from here. The bug report could contain personal information. 
          /// 
          /// You can also share your debug logs directly with your team admin via Wire.
          internal static let info = L10n.tr("Localizable", "self.settings.technical_report.info", fallback: "If you encounter unexpected behaviour or a bug while using Wire, you can send a bug report to our support team from here. The bug report could contain personal information. \n\nYou can also share your debug logs directly with your team admin via Wire.")
          /// No mail client detected. Tap "OK" and send logs manually to: 
          internal static let noMailAlert = L10n.tr("Localizable", "self.settings.technical_report.no_mail_alert", fallback: "No mail client detected. Tap \"OK\" and send logs manually to: ")
          /// Detailed logs could contain personal data
          internal static let privacyWarning = L10n.tr("Localizable", "self.settings.technical_report.privacy_warning", fallback: "Detailed logs could contain personal data")
          /// Send Report
          internal static let sendReport = L10n.tr("Localizable", "self.settings.technical_report.send_report", fallback: "Send Report")
          /// Share Report Via Wire
          internal static let shareReport = L10n.tr("Localizable", "self.settings.technical_report.share_report", fallback: "Share Report Via Wire")
          internal enum Mail {
            /// Wire Debug Report
            internal static let subject = L10n.tr("Localizable", "self.settings.technical_report.mail.subject", fallback: "Wire Debug Report")
          }
          internal enum MailBody {
            /// Please fill in the following
            internal static let firstline = L10n.tr("Localizable", "self.settings.technical_report.mail_body.firstline", fallback: "Please fill in the following")
            /// Date and Time of the issue occured:
            internal static let section1 = L10n.tr("Localizable", "self.settings.technical_report.mail_body.section1", fallback: "Date and Time of the issue occured:")
            /// What Happened:
            internal static let section2 = L10n.tr("Localizable", "self.settings.technical_report.mail_body.section2", fallback: "What Happened:")
            /// Steps to reproduce (if relevant):
            internal static let section3 = L10n.tr("Localizable", "self.settings.technical_report.mail_body.section3", fallback: "Steps to reproduce (if relevant):")
          }
        }
        internal enum TechnicalReportSection {
          /// Debug Report
          internal static let title = L10n.tr("Localizable", "self.settings.technical_report_section.title", fallback: "Debug Report")
        }
        internal enum Vbr {
          /// This makes audio calls use less data and work better on slower networks. Turn off to use constant bitrate encoding (CBR). This setting only affects 1:1 calls; conference calls always use CBR encoding.
          internal static let description = L10n.tr("Localizable", "self.settings.vbr.description", fallback: "This makes audio calls use less data and work better on slower networks. Turn off to use constant bitrate encoding (CBR). This setting only affects 1:1 calls; conference calls always use CBR encoding.")
          /// Variable Bit Rate Encoding
          internal static let title = L10n.tr("Localizable", "self.settings.vbr.title", fallback: "Variable Bit Rate Encoding")
        }
      }
    }
    internal enum SendInvitation {
      /// Connect with me on Wire
      internal static let subject = L10n.tr("Localizable", "send_invitation.subject", fallback: "Connect with me on Wire")
      /// I’m on Wire, search for %@ or visit get.wire.com
      internal static func text(_ p1: Any) -> String {
        return L10n.tr("Localizable", "send_invitation.text", String(describing: p1), fallback: "I’m on Wire, search for %@ or visit get.wire.com")
      }
    }
    internal enum SendInvitationNoEmail {
      /// I’m on Wire. Visit get.wire.com to connect with me.
      internal static let text = L10n.tr("Localizable", "send_invitation_no_email.text", fallback: "I’m on Wire. Visit get.wire.com to connect with me.")
    }
    internal enum ServicesOptions {
      internal enum AllowServices {
        /// Open this conversation to services.
        internal static let subtitle = L10n.tr("Localizable", "services_options.allow_services.subtitle", fallback: "Open this conversation to services.")
        /// Allow services
        internal static let title = L10n.tr("Localizable", "services_options.allow_services.title", fallback: "Allow services")
      }
      internal enum RemoveServices {
        /// Remove
        internal static let action = L10n.tr("Localizable", "services_options.remove_services.action", fallback: "Remove")
        /// Current services will be removed from the conversation. New services will not be allowed.
        internal static let message = L10n.tr("Localizable", "services_options.remove_services.message", fallback: "Current services will be removed from the conversation. New services will not be allowed.")
      }
    }
    internal enum ShareExtension {
      internal enum Voiceover {
        /// All clients verified.
        internal static let conversationSecure = L10n.tr("Localizable", "share_extension.voiceover.conversation_secure", fallback: "All clients verified.")
        /// Not all clients verified.
        internal static let conversationSecureWithIgnored = L10n.tr("Localizable", "share_extension.voiceover.conversation_secure_with_ignored", fallback: "Not all clients verified.")
        /// Under legal hold.
        internal static let conversationUnderLegalHold = L10n.tr("Localizable", "share_extension.voiceover.conversation_under_legal_hold", fallback: "Under legal hold.")
      }
    }
    internal enum Shortcut {
      internal enum MarkAllAsRead {
        /// Mark All as Read
        internal static let title = L10n.tr("Localizable", "shortcut.mark_all_as_read.title", fallback: "Mark All as Read")
      }
    }
    internal enum Signin {
      /// Log In
      internal static let confirm = L10n.tr("Localizable", "signin.confirm", fallback: "Log In")
      /// Forgot password?
      internal static let forgotPassword = L10n.tr("Localizable", "signin.forgot_password", fallback: "Forgot password?")
      internal enum CompanyIdp {
        internal enum Button {
          /// For Companies
          internal static let title = L10n.tr("Localizable", "signin.company_idp.button.title", fallback: "For Companies")
        }
      }
      internal enum Email {
        internal enum MissingPassword {
          /// Enter your email address and password to continue.
          internal static let subtitle = L10n.tr("Localizable", "signin.email.missing_password.subtitle", fallback: "Enter your email address and password to continue.")
        }
      }
      internal enum UseEmail {
        /// Login with Email
        internal static let label = L10n.tr("Localizable", "signin.use_email.label", fallback: "Login with Email")
      }
      internal enum UseOnePassword {
        /// Double tap to fill your password with 1Password
        internal static let hint = L10n.tr("Localizable", "signin.use_one_password.hint", fallback: "Double tap to fill your password with 1Password")
        /// Log in with 1Password
        internal static let label = L10n.tr("Localizable", "signin.use_one_password.label", fallback: "Log in with 1Password")
      }
    }
    internal enum SigninLogout {
      internal enum Email {
        /// Your session expired. Enter your email address and password to continue.
        internal static let subheadline = L10n.tr("Localizable", "signin_logout.email.subheadline", fallback: "Your session expired. Enter your email address and password to continue.")
      }
      internal enum Sso {
        /// Enterprise log in
        internal static let buton = L10n.tr("Localizable", "signin_logout.sso.buton", fallback: "Enterprise log in")
        /// Your session expired. Log in with your enterprise account to continue.
        internal static let subheadline = L10n.tr("Localizable", "signin_logout.sso.subheadline", fallback: "Your session expired. Log in with your enterprise account to continue.")
      }
    }
    internal enum Sketchpad {
      /// Tap colors to change brush size
      internal static let initialHint = L10n.tr("Localizable", "sketchpad.initial_hint", fallback: "Tap colors to change brush size")
    }
    internal enum SystemStatusBar {
      internal enum NoInternet {
        /// There seems to be a problem with your Internet connection. Please make sure it’s working.
        internal static let explanation = L10n.tr("Localizable", "system_status_bar.no_internet.explanation", fallback: "There seems to be a problem with your Internet connection. Please make sure it’s working.")
        /// No Internet
        internal static let title = L10n.tr("Localizable", "system_status_bar.no_internet.title", fallback: "No Internet")
      }
      internal enum PoorConnectivity {
        /// We can’t guarantee voice quality. Connect to Wi-Fi or try changing your location.
        internal static let explanation = L10n.tr("Localizable", "system_status_bar.poor_connectivity.explanation", fallback: "We can’t guarantee voice quality. Connect to Wi-Fi or try changing your location.")
        /// Slow Internet, can’t call now
        internal static let title = L10n.tr("Localizable", "system_status_bar.poor_connectivity.title", fallback: "Slow Internet, can’t call now")
      }
    }
    internal enum Team {
      internal enum ActivationCode {
        /// You’ve got mail
        internal static let headline = L10n.tr("Localizable", "team.activation_code.headline", fallback: "You’ve got mail")
        /// Enter the verification code we sent to %@.
        internal static func subheadline(_ p1: Any) -> String {
          return L10n.tr("Localizable", "team.activation_code.subheadline", String(describing: p1), fallback: "Enter the verification code we sent to %@.")
        }
        internal enum Button {
          /// Change email
          internal static let changeEmail = L10n.tr("Localizable", "team.activation_code.button.change_email", fallback: "Change email")
          /// Resend code
          internal static let resend = L10n.tr("Localizable", "team.activation_code.button.resend", fallback: "Resend code")
        }
      }
      internal enum FullName {
        /// Your name
        internal static let headline = L10n.tr("Localizable", "team.full_name.headline", fallback: "Your name")
        internal enum Textfield {
          /// Set full name
          internal static let accessibility = L10n.tr("Localizable", "team.full_name.textfield.accessibility", fallback: "Set full name")
          /// Full name
          internal static let placeholder = L10n.tr("Localizable", "team.full_name.textfield.placeholder", fallback: "Full name")
        }
      }
      internal enum Invite {
        internal enum Error {
          /// No Internet Connection
          internal static let noInternet = L10n.tr("Localizable", "team.invite.error.no_internet", fallback: "No Internet Connection")
        }
      }
      internal enum Password {
        /// Set password
        internal static let headline = L10n.tr("Localizable", "team.password.headline", fallback: "Set password")
      }
      internal enum PhoneActivationCode {
        /// Verification
        internal static let headline = L10n.tr("Localizable", "team.phone_activation_code.headline", fallback: "Verification")
      }
    }
    internal enum Time {
      /// Just now
      internal static let justNow = L10n.tr("Localizable", "time.just_now", fallback: "Just now")
    }
    internal enum ToolTip {
      internal enum Contacts {
        /// Start a conversation. Call, message and share in private or with groups.
        internal static let message = L10n.tr("Localizable", "tool_tip.contacts.message", fallback: "Start a conversation. Call, message and share in private or with groups.")
        /// Conversations start here
        internal static let title = L10n.tr("Localizable", "tool_tip.contacts.title", fallback: "Conversations start here")
      }
    }
    internal enum TwitterStatus {
      /// %@ on Twitter
      internal static func onTwitter(_ p1: Any) -> String {
        return L10n.tr("Localizable", "twitter_status.on_twitter", String(describing: p1), fallback: "%@ on Twitter")
      }
    }
    internal enum Unlock {
      /// Wrong passcode
      internal static let errorLabel = L10n.tr("Localizable", "unlock.error_label", fallback: "Wrong passcode")
      /// Enter passcode to unlock Wire
      internal static let titleLabel = L10n.tr("Localizable", "unlock.title_label", fallback: "Enter passcode to unlock Wire")
      /// Forgot your app lock passcode?
      internal static let wipeButton = L10n.tr("Localizable", "unlock.wipe_button", fallback: "Forgot your app lock passcode?")
      internal enum SubmitButton {
        /// Unlock
        internal static let title = L10n.tr("Localizable", "unlock.submit_button.title", fallback: "Unlock")
      }
      internal enum Textfield {
        /// Enter your passcode
        internal static let placeholder = L10n.tr("Localizable", "unlock.textfield.placeholder", fallback: "Enter your passcode")
      }
    }
    internal enum UpdateCertificate {
      internal enum Alert {
        /// The end-to-end identity certificate for this device has expired. Enter your identity provider’s credentials in the next step to update the certificate automatically.
        internal static let expiredMessage = L10n.tr("Localizable", "update_certificate.alert.expired-message", fallback: "The end-to-end identity certificate for this device has expired. Enter your identity provider’s credentials in the next step to update the certificate automatically.")
        /// The end-to-end identity certificate for this device expires soon. To keep your communication secure, update your certificate now. Enter your identity provider’s credentials in the next step to update the certificate automatically.
        internal static let message = L10n.tr("Localizable", "update_certificate.alert.message", fallback: "The end-to-end identity certificate for this device expires soon. To keep your communication secure, update your certificate now. Enter your identity provider’s credentials in the next step to update the certificate automatically.")
        /// Update certificate
        internal static let title = L10n.tr("Localizable", "update_certificate.alert.title", fallback: "Update certificate")
      }
      internal enum Button {
        /// Update Certificate
        internal static let updateCertificate = L10n.tr("Localizable", "update_certificate.button.update_certificate", fallback: "Update Certificate")
      }
    }
    internal enum UpdateE2eiCertificate {
      /// The certificate is updated and your device is verified.
      internal static let subtitle = L10n.tr("Localizable", "update_e2ei_certificate.subtitle", fallback: "The certificate is updated and your device is verified.")
      /// Certificate updated
      internal static let title = L10n.tr("Localizable", "update_e2ei_certificate.title", fallback: "Certificate updated")
    }
    internal enum UrlAction {
      /// Confirm
      internal static let confirm = L10n.tr("Localizable", "url_action.confirm", fallback: "Confirm")
      /// Confirm URL action
      internal static let title = L10n.tr("Localizable", "url_action.title", fallback: "Confirm URL action")
      internal enum AuthorizationRequired {
        /// You need to log in to view this content.
        internal static let message = L10n.tr("Localizable", "url_action.authorization_required.message", fallback: "You need to log in to view this content.")
        /// Authorization required.
        internal static let title = L10n.tr("Localizable", "url_action.authorization_required.title", fallback: "Authorization required.")
      }
      internal enum ConnectToBot {
        /// Would you like to connect to the bot?
        internal static let message = L10n.tr("Localizable", "url_action.connect_to_bot.message", fallback: "Would you like to connect to the bot?")
      }
      internal enum InvalidConversation {
        /// You may not have permission with this account or the person may not be on Wire.
        internal static let message = L10n.tr("Localizable", "url_action.invalid_conversation.message", fallback: "You may not have permission with this account or the person may not be on Wire.")
        /// Wire can't open this conversation.
        internal static let title = L10n.tr("Localizable", "url_action.invalid_conversation.title", fallback: "Wire can't open this conversation.")
      }
      internal enum InvalidLink {
        /// The link you opened is not valid.
        internal static let message = L10n.tr("Localizable", "url_action.invalid_link.message", fallback: "The link you opened is not valid.")
        /// Invalid link.
        internal static let title = L10n.tr("Localizable", "url_action.invalid_link.title", fallback: "Invalid link.")
      }
      internal enum InvalidUser {
        /// You may not have permission with this account or it no longer exists.
        internal static let message = L10n.tr("Localizable", "url_action.invalid_user.message", fallback: "You may not have permission with this account or it no longer exists.")
        /// Wire can't find this person.
        internal static let title = L10n.tr("Localizable", "url_action.invalid_user.title", fallback: "Wire can't find this person.")
      }
      internal enum JoinConversation {
        internal enum Confirmation {
          /// Join
          internal static let confirmButton = L10n.tr("Localizable", "url_action.join_conversation.confirmation.confirm_button", fallback: "Join")
          /// You have been invited to a conversation:
          /// %@
          internal static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "url_action.join_conversation.confirmation.message", String(describing: p1), fallback: "You have been invited to a conversation:\n%@")
          }
        }
        internal enum Error {
          internal enum Alert {
            /// You could not join the conversation
            internal static let title = L10n.tr("Localizable", "url_action.join_conversation.error.alert.title", fallback: "You could not join the conversation")
            internal enum ConverationIsFull {
              /// The conversation is full.
              internal static let message = L10n.tr("Localizable", "url_action.join_conversation.error.alert.converation_is_full.message", fallback: "The conversation is full.")
            }
            internal enum InvalidPassword {
              /// Password is incorrect, please try again.
              internal static let message = L10n.tr("Localizable", "url_action.join_conversation.error.alert.invalid_password.message", fallback: "Password is incorrect, please try again.")
            }
            internal enum LearnMore {
              /// Learn more about guest links
              internal static let action = L10n.tr("Localizable", "url_action.join_conversation.error.alert.learn_more.action", fallback: "Learn more about guest links")
            }
            internal enum LinkIsInvalid {
              /// The conversation link is invalid.
              internal static let message = L10n.tr("Localizable", "url_action.join_conversation.error.alert.link_is_invalid.message", fallback: "The conversation link is invalid.")
            }
          }
        }
      }
      internal enum SwitchBackend {
        internal enum Error {
          /// Please check your internet connection, verify the link and try again.
          internal static let invalidBackend = L10n.tr("Localizable", "url_action.switch_backend.error.invalid_backend", fallback: "Please check your internet connection, verify the link and try again.")
          /// You are already logged in. To switch to this server, log out of all accounts and try again.
          internal static let loggedIn = L10n.tr("Localizable", "url_action.switch_backend.error.logged_in", fallback: "You are already logged in. To switch to this server, log out of all accounts and try again.")
          internal enum InvalidBackend {
            /// The server is not responding
            internal static let title = L10n.tr("Localizable", "url_action.switch_backend.error.invalid_backend.title", fallback: "The server is not responding")
          }
          internal enum LoggedIn {
            /// Can’t switch servers
            internal static let title = L10n.tr("Localizable", "url_action.switch_backend.error.logged_in.title", fallback: "Can’t switch servers")
          }
        }
      }
      internal enum SwitchBackendConfirmation {
        /// Accounts URL:
        internal static let accountsUrl = L10n.tr("Localizable", "url_action.switch_backend_confirmation.accounts_url", fallback: "Accounts URL:")
        /// Backend name:
        internal static let backendName = L10n.tr("Localizable", "url_action.switch_backend_confirmation.backend_name", fallback: "Backend name:")
        /// Backend URL:
        internal static let backendUrl = L10n.tr("Localizable", "url_action.switch_backend_confirmation.backend_url", fallback: "Backend URL:")
        /// Backend websocket URL:
        internal static let backendWsurl = L10n.tr("Localizable", "url_action.switch_backend_confirmation.backend_wsurl", fallback: "Backend websocket URL:")
        /// Blacklist URL:
        internal static let blacklistUrl = L10n.tr("Localizable", "url_action.switch_backend_confirmation.blacklist_url", fallback: "Blacklist URL:")
        /// If you proceed, you will be redirected to the following on-premises backend to log in:
        internal static let message = L10n.tr("Localizable", "url_action.switch_backend_confirmation.message", fallback: "If you proceed, you will be redirected to the following on-premises backend to log in:")
        /// Proceed
        internal static let proceed = L10n.tr("Localizable", "url_action.switch_backend_confirmation.proceed", fallback: "Proceed")
        /// Teams URL:
        internal static let teamsUrl = L10n.tr("Localizable", "url_action.switch_backend_confirmation.teams_url", fallback: "Teams URL:")
        /// Redirect to an on-premises backend?
        internal static let title = L10n.tr("Localizable", "url_action.switch_backend_confirmation.title", fallback: "Redirect to an on-premises backend?")
        /// Website URL:
        internal static let websiteUrl = L10n.tr("Localizable", "url_action.switch_backend_confirmation.website_url", fallback: "Website URL:")
      }
    }
    internal enum UserCell {
      internal enum Title {
        ///  (You)
        internal static let youSuffix = L10n.tr("Localizable", "user_cell.title.you_suffix", fallback: " (You)")
      }
    }
    internal enum Verification {
      /// Double tap to enter the code.
      internal static let codeHint = L10n.tr("Localizable", "verification.code_hint", fallback: "Double tap to enter the code.")
      /// Six-digit code. Text field.
      internal static let codeLabel = L10n.tr("Localizable", "verification.code_label", fallback: "Six-digit code. Text field.")
    }
    internal enum VideoCall {
      internal enum CameraAccess {
        /// Wire doesn’t have access to the camera
        internal static let denied = L10n.tr("Localizable", "video_call.camera_access.denied", fallback: "Wire doesn’t have access to the camera")
      }
    }
    internal enum Voice {
      internal enum AcceptButton {
        /// Accept
        internal static let title = L10n.tr("Localizable", "voice.accept_button.title", fallback: "Accept")
      }
      internal enum Alert {
        internal enum CallInProgress {
          /// OK
          internal static let confirm = L10n.tr("Localizable", "voice.alert.call_in_progress.confirm", fallback: "OK")
          /// You can have only one active call at a time
          internal static let message = L10n.tr("Localizable", "voice.alert.call_in_progress.message", fallback: "You can have only one active call at a time")
          /// Call in progress
          internal static let title = L10n.tr("Localizable", "voice.alert.call_in_progress.title", fallback: "Call in progress")
        }
        internal enum CameraWarning {
          /// Wire needs access to the camera
          internal static let title = L10n.tr("Localizable", "voice.alert.camera_warning.title", fallback: "Wire needs access to the camera")
        }
        internal enum MicrophoneWarning {
          /// Wire needs access to the microphone
          internal static let title = L10n.tr("Localizable", "voice.alert.microphone_warning.title", fallback: "Wire needs access to the microphone")
        }
      }
      internal enum CallButton {
        /// Call
        internal static let title = L10n.tr("Localizable", "voice.call_button.title", fallback: "Call")
      }
      internal enum CallError {
        internal enum UnsupportedVersion {
          /// Later
          internal static let dismiss = L10n.tr("Localizable", "voice.call_error.unsupported_version.dismiss", fallback: "Later")
          /// You received a call that isn't supported by this version of Wire.
          /// Get the latest version in the App Store.
          internal static let message = L10n.tr("Localizable", "voice.call_error.unsupported_version.message", fallback: "You received a call that isn't supported by this version of Wire.\nGet the latest version in the App Store.")
          /// Please update Wire
          internal static let title = L10n.tr("Localizable", "voice.call_error.unsupported_version.title", fallback: "Please update Wire")
        }
      }
      internal enum Calling {
        /// Calling...
        internal static let title = L10n.tr("Localizable", "voice.calling.title", fallback: "Calling...")
      }
      internal enum CancelButton {
        /// Cancel
        internal static let title = L10n.tr("Localizable", "voice.cancel_button.title", fallback: "Cancel")
      }
      internal enum DeclineButton {
        /// Decline
        internal static let title = L10n.tr("Localizable", "voice.decline_button.title", fallback: "Decline")
      }
      internal enum Degradation {
        /// You started using a new device.
        internal static let newSelfDevice = L10n.tr("Localizable", "voice.degradation.new_self_device", fallback: "You started using a new device.")
        /// %@ started using a new device.
        internal static func newUserDevice(_ p1: Any) -> String {
          return L10n.tr("Localizable", "voice.degradation.new_user_device", String(describing: p1), fallback: "%@ started using a new device.")
        }
      }
      internal enum DegradationIncoming {
        /// Do you still want to accept the call?
        internal static let prompt = L10n.tr("Localizable", "voice.degradation_incoming.prompt", fallback: "Do you still want to accept the call?")
      }
      internal enum DegradationOutgoing {
        /// Do you still want to place the call?
        internal static let prompt = L10n.tr("Localizable", "voice.degradation_outgoing.prompt", fallback: "Do you still want to place the call?")
      }
      internal enum EndCallButton {
        /// End Call
        internal static let title = L10n.tr("Localizable", "voice.end_call_button.title", fallback: "End Call")
      }
      internal enum FlipCameraButton {
        /// Flip
        internal static let title = L10n.tr("Localizable", "voice.flip_camera_button.title", fallback: "Flip")
      }
      internal enum FlipVideoButton {
        /// Switch camera
        internal static let title = L10n.tr("Localizable", "voice.flip_video_button.title", fallback: "Switch camera")
      }
      internal enum HangUpButton {
        /// Hang Up
        internal static let title = L10n.tr("Localizable", "voice.hang_up_button.title", fallback: "Hang Up")
      }
      internal enum MuteButton {
        /// Microphone
        internal static let title = L10n.tr("Localizable", "voice.mute_button.title", fallback: "Microphone")
      }
      internal enum NetworkError {
        /// You must be online to call. Check your connection and try again.
        internal static let body = L10n.tr("Localizable", "voice.network_error.body", fallback: "You must be online to call. Check your connection and try again.")
        /// No Internet Connection
        internal static let title = L10n.tr("Localizable", "voice.network_error.title", fallback: "No Internet Connection")
      }
      internal enum PickUpButton {
        /// Accept
        internal static let title = L10n.tr("Localizable", "voice.pick_up_button.title", fallback: "Accept")
      }
      internal enum SpeakerButton {
        /// Speaker
        internal static let title = L10n.tr("Localizable", "voice.speaker_button.title", fallback: "Speaker")
      }
      internal enum Status {
        /// Constant Bit Rate
        internal static let cbr = L10n.tr("Localizable", "voice.status.cbr", fallback: "Constant Bit Rate")
        /// %@
        /// Connecting
        internal static func joining(_ p1: Any) -> String {
          return L10n.tr("Localizable", "voice.status.joining", String(describing: p1), fallback: "%@\nConnecting")
        }
        /// %@
        /// Call ended
        internal static func leaving(_ p1: Any) -> String {
          return L10n.tr("Localizable", "voice.status.leaving", String(describing: p1), fallback: "%@\nCall ended")
        }
        /// Bad connection
        internal static let lowConnection = L10n.tr("Localizable", "voice.status.low_connection", fallback: "Bad connection")
        /// Video turned off
        internal static let videoNotAvailable = L10n.tr("Localizable", "voice.status.video_not_available", fallback: "Video turned off")
        internal enum GroupCall {
          /// %@
          /// ringing
          internal static func incoming(_ p1: Any) -> String {
            return L10n.tr("Localizable", "voice.status.group_call.incoming", String(describing: p1), fallback: "%@\nringing")
          }
        }
        internal enum OneToOne {
          /// %@
          /// calling
          internal static func incoming(_ p1: Any) -> String {
            return L10n.tr("Localizable", "voice.status.one_to_one.incoming", String(describing: p1), fallback: "%@\ncalling")
          }
          /// %@
          /// ringing
          internal static func outgoing(_ p1: Any) -> String {
            return L10n.tr("Localizable", "voice.status.one_to_one.outgoing", String(describing: p1), fallback: "%@\nringing")
          }
        }
      }
      internal enum TopOverlay {
        /// Ongoing call
        internal static let accessibilityTitle = L10n.tr("Localizable", "voice.top_overlay.accessibility_title", fallback: "Ongoing call")
        /// Tap to return to call
        internal static let tapToReturn = L10n.tr("Localizable", "voice.top_overlay.tap_to_return", fallback: "Tap to return to call")
      }
      internal enum VideoButton {
        /// Camera
        internal static let title = L10n.tr("Localizable", "voice.video_button.title", fallback: "Camera")
      }
    }
    internal enum WarningScreen {
      /// There was a change in Wire
      internal static let titleLabel = L10n.tr("Localizable", "warning_screen.title_label", fallback: "There was a change in Wire")
      internal enum InfoLabel {
        /// Next time, unlock Wire the same way you unlock your phone.
        internal static let forcedApplock = L10n.tr("Localizable", "warning_screen.info_label.forced_applock", fallback: "Next time, unlock Wire the same way you unlock your phone.")
        /// Your organization does not need app lock anymore. From now, you can access Wire without any obstacles.
        internal static let nonForcedApplock = L10n.tr("Localizable", "warning_screen.info_label.non_forced_applock", fallback: "Your organization does not need app lock anymore. From now, you can access Wire without any obstacles.")
      }
      internal enum MainInfo {
        /// Your organization needs to lock your app when Wire is not in use to keep the team safe.
        internal static let forcedApplock = L10n.tr("Localizable", "warning_screen.main_info.forced_applock", fallback: "Your organization needs to lock your app when Wire is not in use to keep the team safe.")
      }
    }
    internal enum WipeDatabase {
      /// The data stored on this device can only be accessed with your app lock passcode. If you have forgotten your passpcode, you can reset this device. Please enter your Wire account password to reset this device and log in again. By resetting your device,
      internal static let infoLabel = L10n.tr("Localizable", "wipe_database.info_label", fallback: "The data stored on this device can only be accessed with your app lock passcode. If you have forgotten your passpcode, you can reset this device. Please enter your Wire account password to reset this device and log in again. By resetting your device,")
      /// Forgot your app lock passcode?
      internal static let titleLabel = L10n.tr("Localizable", "wipe_database.title_label", fallback: "Forgot your app lock passcode?")
      internal enum Alert {
        /// Delete
        internal static let confirm = L10n.tr("Localizable", "wipe_database.alert.confirm", fallback: "Delete")
        /// Delete
        internal static let confirmInput = L10n.tr("Localizable", "wipe_database.alert.confirm_input", fallback: "Delete")
        /// Reset Device
        internal static let description = L10n.tr("Localizable", "wipe_database.alert.description", fallback: "Reset Device")
        /// Type 'Delete' to verify you want to delete all data in this device,
        /// to reset this device and log in again
        internal static let message = L10n.tr("Localizable", "wipe_database.alert.message", fallback: "Type 'Delete' to verify you want to delete all data in this device,\nto reset this device and log in again")
        /// Type 'Delete'
        internal static let placeholder = L10n.tr("Localizable", "wipe_database.alert.placeholder", fallback: "Type 'Delete'")
      }
      internal enum Button {
        /// Reset Device
        internal static let title = L10n.tr("Localizable", "wipe_database.button.title", fallback: "Reset Device")
      }
      internal enum InfoLabel {
        /// all local data and messages for this account will be permanently deleted.
        internal static let highlighted = L10n.tr("Localizable", "wipe_database.info_label.highlighted", fallback: "all local data and messages for this account will be permanently deleted.")
      }
    }
    internal enum WipeDatabaseCompletion {
      /// Your data and messages have been deleted. You can now log in again as a new device.
      internal static let subtitle = L10n.tr("Localizable", "wipe_database_completion.subtitle", fallback: "Your data and messages have been deleted. You can now log in again as a new device.")
      /// Database deleted
      internal static let title = L10n.tr("Localizable", "wipe_database_completion.title", fallback: "Database deleted")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
