// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Sidebar {
    internal enum Contacts {
      /// Contacts
      internal static let title = L10n.tr("Localizable", "sidebar.contacts.title", fallback: "Contacts")
      internal enum Connect {
        /// Connect
        internal static let title = L10n.tr("Localizable", "sidebar.contacts.connect.title", fallback: "Connect")
      }
    }
    internal enum ConversationFilter {
      /// Conversations
      internal static let title = L10n.tr("Localizable", "sidebar.conversation_filter.title", fallback: "Conversations")
      internal enum All {
        /// All
        internal static let title = L10n.tr("Localizable", "sidebar.conversation_filter.all.title", fallback: "All")
      }
      internal enum Archived {
        /// Archive
        internal static let title = L10n.tr("Localizable", "sidebar.conversation_filter.archived.title", fallback: "Archive")
      }
      internal enum Favorites {
        /// Favorites
        internal static let title = L10n.tr("Localizable", "sidebar.conversation_filter.favorites.title", fallback: "Favorites")
      }
      internal enum Groups {
        /// Groups
        internal static let title = L10n.tr("Localizable", "sidebar.conversation_filter.groups.title", fallback: "Groups")
      }
      internal enum OneOnOneConversations {
        /// 1:1 Conversations
        internal static let title = L10n.tr("Localizable", "sidebar.conversation_filter.oneOnOneConversations.title", fallback: "1:1 Conversations")
      }
    }
    internal enum Settings {
      /// Settings
      internal static let title = L10n.tr("Localizable", "sidebar.settings.title", fallback: "Settings")
    }
    internal enum Support {
      /// Support
      internal static let title = L10n.tr("Localizable", "sidebar.support.title", fallback: "Support")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
      fatalError()
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
