// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum LiveActivity {
    internal enum Uploads {
      internal enum Completed {
        /// %lld files to Shared Drive
        internal static func subtitleMany(_ p1: Int) -> String {
          return L10n.tr("Localizable", "live_activity.uploads.completed.subtitle_many", p1, fallback: "%lld files to Shared Drive")
        }
        /// 1 file to Shared Drive
        internal static let subtitleOne = L10n.tr("Localizable", "live_activity.uploads.completed.subtitle_one", fallback: "1 file to Shared Drive")
        /// Upload complete
        internal static let title = L10n.tr("Localizable", "live_activity.uploads.completed.title", fallback: "Upload complete")
      }
      internal enum Failed {
        /// to Shared Drive
        internal static let subtitle = L10n.tr("Localizable", "live_activity.uploads.failed.subtitle", fallback: "to Shared Drive")
        /// %1$lld of %2$lld uploaded
        internal static func subtitleWithUploaded(_ p1: Int, _ p2: Int) -> String {
          return L10n.tr("Localizable", "live_activity.uploads.failed.subtitle_with_uploaded", p1, p2, fallback: "%1$lld of %2$lld uploaded")
        }
        /// Couldn’t upload %lld files
        internal static func titleMany(_ p1: Int) -> String {
          return L10n.tr("Localizable", "live_activity.uploads.failed.title_many", p1, fallback: "Couldn’t upload %lld files")
        }
        /// Couldn’t upload 1 file
        internal static let titleOne = L10n.tr("Localizable", "live_activity.uploads.failed.title_one", fallback: "Couldn’t upload 1 file")
      }
      internal enum Stale {
        /// Open Wire
        internal static let compactText = L10n.tr("Localizable", "live_activity.uploads.stale.compact_text", fallback: "Open Wire")
        /// Open Wire to check upload status
        internal static let subtitle = L10n.tr("Localizable", "live_activity.uploads.stale.subtitle", fallback: "Open Wire to check upload status")
        /// Shared Drive uploads
        internal static let title = L10n.tr("Localizable", "live_activity.uploads.stale.title", fallback: "Shared Drive uploads")
      }
      internal enum Uploading {
        /// %lld failed
        internal static func failed(_ p1: Int) -> String {
          return L10n.tr("Localizable", "live_activity.uploads.uploading.failed", p1, fallback: "%lld failed")
        }
        /// %1$lld of %2$lld uploaded
        internal static func subtitle(_ p1: Int, _ p2: Int) -> String {
          return L10n.tr("Localizable", "live_activity.uploads.uploading.subtitle", p1, p2, fallback: "%1$lld of %2$lld uploaded")
        }
        /// Uploading to Shared Drive
        internal static let title = L10n.tr("Localizable", "live_activity.uploads.uploading.title", fallback: "Uploading to Shared Drive")
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
