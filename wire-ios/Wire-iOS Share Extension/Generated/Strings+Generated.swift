// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Content {
    internal enum File {
      /// You can send files up to %@
      internal static func tooBig(_ p1: Any) -> String {
        return L10n.tr("Localizable", "content.file.too_big", String(describing: p1), fallback: "You can send files up to %@")
      }
      /// Unsupported attachment
      internal static let unsupportedAttachment = L10n.tr("Localizable", "content.file.unsupported_attachment", fallback: "Unsupported attachment")
    }
  }
  internal enum Conversation {
    internal enum Displayname {
      /// Empty group conversation
      internal static let emptygroup = L10n.tr("Localizable", "conversation.displayname.emptygroup", fallback: "Empty group conversation")
    }
  }
  internal enum Feature {
    internal enum Flag {
      internal enum FileSharing {
        internal enum Alert {
          /// You can not share this file because this feature is disabled.
          internal static let message = L10n.tr("Localizable", "feature.flag.file_sharing.alert.message", fallback: "You can not share this file because this feature is disabled.")
          /// File sharing restrictions
          internal static let title = L10n.tr("Localizable", "feature.flag.file_sharing.alert.title", fallback: "File sharing restrictions")
        }
      }
    }
  }
  internal enum General {
    /// OK
    internal static let ok = L10n.tr("Localizable", "general.ok", fallback: "OK")
  }
  internal enum Meta {
    internal enum Degraded {
      /// Do not send
      internal static let cancelSendingButton = L10n.tr("Localizable", "meta.degraded.cancel_sending_button", fallback: "Do not send")
      /// Do you still want to send your message?
      internal static let dialogMessage = L10n.tr("Localizable", "meta.degraded.dialog_message", fallback: "Do you still want to send your message?")
      /// Send anyway
      internal static let sendAnywayButton = L10n.tr("Localizable", "meta.degraded.send_anyway_button", fallback: "Send anyway")
      internal enum DegradationReasonMessage {
        /// %@ started using new devices.
        internal static func plural(_ p1: Any) -> String {
          return L10n.tr("Localizable", "meta.degraded.degradation_reason_message.plural", String(describing: p1), fallback: "%@ started using new devices.")
        }
        /// %@ started using a new device.
        internal static func singular(_ p1: Any) -> String {
          return L10n.tr("Localizable", "meta.degraded.degradation_reason_message.singular", String(describing: p1), fallback: "%@ started using a new device.")
        }
      }
    }
  }
  internal enum ShareExtension {
    internal enum ConversationSelection {
      /// Account:
      internal static let account = L10n.tr("Localizable", "share_extension.conversation_selection.account", fallback: "Account:")
      /// Conversation:
      internal static let title = L10n.tr("Localizable", "share_extension.conversation_selection.title", fallback: "Conversation:")
      internal enum Empty {
        /// Choose
        internal static let value = L10n.tr("Localizable", "share_extension.conversation_selection.empty.value", fallback: "Choose")
      }
    }
    internal enum Error {
      internal enum ConversationDoesNotExist {
        /// Please select a conversation for sharing
        internal static let message = L10n.tr("Localizable", "share_extension.error.conversation_does_not_exist.message", fallback: "Please select a conversation for sharing")
      }
    }
    internal enum Input {
      /// Type a message
      internal static let placeholder = L10n.tr("Localizable", "share_extension.input.placeholder", fallback: "Type a message")
    }
    internal enum LoggedOut {
      /// Please choose another account.
      internal static let message = L10n.tr("Localizable", "share_extension.logged_out.message", fallback: "Please choose another account.")
      /// You've been logged out from this account.
      internal static let title = L10n.tr("Localizable", "share_extension.logged_out.title", fallback: "You've been logged out from this account.")
    }
    internal enum NoInternetConnection {
      /// No Internet Connection
      internal static let title = L10n.tr("Localizable", "share_extension.no_internet_connection.title", fallback: "No Internet Connection")
    }
    internal enum NotSignedIn {
      /// Close
      internal static let closeButton = L10n.tr("Localizable", "share_extension.not_signed_in.close_button", fallback: "Close")
      /// You need to sign into Wire before you can share anything
      internal static let title = L10n.tr("Localizable", "share_extension.not_signed_in.title", fallback: "You need to sign into Wire before you can share anything")
    }
    internal enum Preparing {
      /// Preparing…
      internal static let title = L10n.tr("Localizable", "share_extension.preparing.title", fallback: "Preparing…")
    }
    internal enum PrivacySecurity {
      internal enum LockApp {
        /// Unlock Wire
        internal static let description = L10n.tr("Localizable", "share_extension.privacy_security.lock_app.description", fallback: "Unlock Wire")
      }
    }
    internal enum SendButton {
      /// Send
      internal static let title = L10n.tr("Localizable", "share_extension.send_button.title", fallback: "Send")
    }
    internal enum SendingProgress {
      /// Sending…
      internal static let title = L10n.tr("Localizable", "share_extension.sending_progress.title", fallback: "Sending…")
    }
    internal enum Timeout {
      /// Check your Internet connection and try again. The attachments were saved in the conversation.
      internal static let message = L10n.tr("Localizable", "share_extension.timeout.message", fallback: "Check your Internet connection and try again. The attachments were saved in the conversation.")
      /// The connection has timed out.
      internal static let title = L10n.tr("Localizable", "share_extension.timeout.title", fallback: "The connection has timed out.")
    }
    internal enum Unlock {
      /// Wrong passcode
      internal static let errorLabel = L10n.tr("Localizable", "share_extension.unlock.error_label", fallback: "Wrong passcode")
      /// Passcode
      internal static let hintLabel = L10n.tr("Localizable", "share_extension.unlock.hint_label", fallback: "Passcode")
      /// Reveal passcode
      internal static let revealPasscode = L10n.tr("Localizable", "share_extension.unlock.reveal_passcode", fallback: "Reveal passcode")
      /// Enter passcode to unlock Wire
      internal static let titleLabel = L10n.tr("Localizable", "share_extension.unlock.title_label", fallback: "Enter passcode to unlock Wire")
      internal enum Alert {
        /// Open Wire to create a passcode
        internal static let message = L10n.tr("Localizable", "share_extension.unlock.alert.message", fallback: "Open Wire to create a passcode")
      }
      internal enum SubmitButton {
        /// unlock
        internal static let title = L10n.tr("Localizable", "share_extension.unlock.submit_button.title", fallback: "unlock")
      }
      internal enum Textfield {
        /// Enter your passcode
        internal static let placeholder = L10n.tr("Localizable", "share_extension.unlock.textfield.placeholder", fallback: "Enter your passcode")
      }
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
