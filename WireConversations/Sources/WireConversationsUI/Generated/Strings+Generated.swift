// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Accessibility {
    internal enum Conversation {
      internal enum Create {
        internal enum Channel {
          /// Go back to new conversation overview
          internal static let back = L10n.tr("Accessibility", "conversation.create.channel.back", fallback: "Go back to new conversation overview")
        }
      }
    }
  }
  internal enum Localizable {
    internal enum ChannelAccessLevel {
      /// All team members can join public channels. But, only channel admins or members can add people to a private channel. A private channel can not be changed to public.
      internal static let accessFooter = L10n.tr("Localizable", "channel_access_level.access_footer", fallback: "All team members can join public channels. But, only channel admins or members can add people to a private channel. A private channel can not be changed to public.")
      /// Admins
      internal static let admins = L10n.tr("Localizable", "channel_access_level.admins", fallback: "Admins")
      /// Admins and members
      internal static let everyone = L10n.tr("Localizable", "channel_access_level.everyone", fallback: "Admins and members")
      /// Access
      internal static let navigationTitle = L10n.tr("Localizable", "channel_access_level.navigation_title", fallback: "Access")
      /// Select who can add participants to a private channel
      internal static let participantsFooter = L10n.tr("Localizable", "channel_access_level.participants_footer", fallback: "Select who can add participants to a private channel")
      /// Add participants
      internal static let participantsHeader = L10n.tr("Localizable", "channel_access_level.participants_header", fallback: "Add participants")
      /// Private
      internal static let `private` = L10n.tr("Localizable", "channel_access_level.private", fallback: "Private")
      /// Public
      internal static let `public` = L10n.tr("Localizable", "channel_access_level.public", fallback: "Public")
      internal enum ChangeLevelAlert {
        /// Changing the channel access to private will have the following implications:
        /// 
        /// Team members can not join the channel themselves anymore.
        /// New members can only be added by channel admins or other members, depending on the “Add participants” setting.
        /// The channel access can not be turned back to public anymore.
        /// 
        /// Do you want to change channel access to private?
        internal static let message = L10n.tr("Localizable", "channel_access_level.change_level_alert.message", fallback: "Changing the channel access to private will have the following implications:\n\nTeam members can not join the channel themselves anymore.\nNew members can only be added by channel admins or other members, depending on the “Add participants” setting.\nThe channel access can not be turned back to public anymore.\n\nDo you want to change channel access to private?")
        /// Channel access
        internal static let title = L10n.tr("Localizable", "channel_access_level.change_level_alert.title", fallback: "Channel access")
        internal enum Button {
          /// Cancel
          internal static let cancel = L10n.tr("Localizable", "channel_access_level.change_level_alert.button.cancel", fallback: "Cancel")
          /// Change
          internal static let change = L10n.tr("Localizable", "channel_access_level.change_level_alert.button.change", fallback: "Change")
        }
      }
    }
    internal enum Conversation {
      internal enum Create {
        internal enum Channel {
          /// Back
          internal static let back = L10n.tr("Localizable", "conversation.create.channel.back", fallback: "Back")
          /// Next
          internal static let next = L10n.tr("Localizable", "conversation.create.channel.next", fallback: "Next")
          /// Conversation history and more
          internal static let subtitle = L10n.tr("Localizable", "conversation.create.channel.subtitle", fallback: "Conversation history and more")
          /// New channel
          internal static let title = L10n.tr("Localizable", "conversation.create.channel.title", fallback: "New channel")
        }
        internal enum Group {
          /// New group
          internal static let title = L10n.tr("Localizable", "conversation.create.group.title", fallback: "New group")
        }
      }
      internal enum CreationForm {
        internal enum ChannelName {
          /// Channel name
          internal static let label = L10n.tr("Localizable", "conversation.creationForm.channelName.label", fallback: "Channel name")
          /// Enter channel name
          internal static let placeholder = L10n.tr("Localizable", "conversation.creationForm.channelName.placeholder", fallback: "Enter channel name")
          /// Channel name
          internal static let sectionTitle = L10n.tr("Localizable", "conversation.creationForm.channelName.sectionTitle", fallback: "Channel name")
        }
        internal enum Guests {
          /// Open this conversation to people outside your team or services.
          internal static let description = L10n.tr("Localizable", "conversation.creationForm.guests.description", fallback: "Open this conversation to people outside your team or services.")
          /// Allow guests
          internal static let toggle = L10n.tr("Localizable", "conversation.creationForm.guests.toggle", fallback: "Allow guests")
        }
        internal enum Options {
          /// Channel access
          internal static let channelAccess = L10n.tr("Localizable", "conversation.creationForm.options.channelAccess", fallback: "Channel access")
          /// All team members can join public channels. But, only channel admins or members can add people to a private channel. A private channel can not be changed to public later.
          internal static let footer = L10n.tr("Localizable", "conversation.creationForm.options.footer", fallback: "All team members can join public channels. But, only channel admins or members can add people to a private channel. A private channel can not be changed to public later.")
          /// Options
          internal static let sectionTitle = L10n.tr("Localizable", "conversation.creationForm.options.sectionTitle", fallback: "Options")
          internal enum ChannelAccess {
            /// Add participants
            internal static let invitePolicy = L10n.tr("Localizable", "conversation.creationForm.options.channelAccess.invitePolicy", fallback: "Add participants")
            /// Private
            internal static let `private` = L10n.tr("Localizable", "conversation.creationForm.options.channelAccess.private", fallback: "Private")
            /// Public
            internal static let `public` = L10n.tr("Localizable", "conversation.creationForm.options.channelAccess.public", fallback: "Public")
            internal enum InvitePolicy {
              /// Admins and members
              internal static let adminsAndMembers = L10n.tr("Localizable", "conversation.creationForm.options.channelAccess.invitePolicy.adminsAndMembers", fallback: "Admins and members")
              /// Admins
              internal static let adminsOnly = L10n.tr("Localizable", "conversation.creationForm.options.channelAccess.invitePolicy.adminsOnly", fallback: "Admins")
            }
          }
        }
        internal enum ReadReceipts {
          /// When this is on, people can see when their messages in this conversation are read.
          internal static let description = L10n.tr("Localizable", "conversation.creationForm.readReceipts.description", fallback: "When this is on, people can see when their messages in this conversation are read.")
          /// Read receipts
          internal static let toggle = L10n.tr("Localizable", "conversation.creationForm.readReceipts.toggle", fallback: "Read receipts")
        }
        internal enum Services {
          /// Allow services
          internal static let toggle = L10n.tr("Localizable", "conversation.creationForm.services.toggle", fallback: "Allow services")
        }
      }
    }
    internal enum General {
      /// Loading…
      internal static let loading = L10n.tr("Localizable", "general.loading", fallback: "Loading…")
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
