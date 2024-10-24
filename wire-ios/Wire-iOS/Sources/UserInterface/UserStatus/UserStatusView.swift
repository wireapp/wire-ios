//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign
import WireSyncEngine

/// A title view subclass that displays the availability of the user.
final class UserStatusView: TitleView {

    // MARK: - Properties

    private let options: Options
    var userStatus = UserStatus() {
        didSet { updateConfiguration() }
    }

    // MARK: - Initialization

    /// Creates a view for the specific user and options.
    /// - parameter options: The options to display the availability.
    init(options: Options) {
        self.options = options
        super.init()
        updateConfiguration()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateConfiguration()
        }
    }

    /// Refreshes the content and appearance of the view.
    private func updateConfiguration() {
        updateAppearance()
        updateContent()
    }

    /// Refreshes the content of the view, based on the user data and the options.
    private func updateContent() {
        typealias AvailabilityStatusStrings = L10n.Accessibility.AccountPage.AvailabilityStatus

        let availability = userStatus.availability
        let fontStyle: FontSize = options.contains(.useLargeFont) ? .normal : .small
        let leadingIcons = [
            AvailabilityStringBuilder.icon(
                for: availability,
                with: AvailabilityStringBuilder.color(for: availability),
                and: fontStyle
            )
        ]
        var trailingIcons = [NSTextAttachment?]()
        let isInteractive = options.contains(.allowSettingStatus)
        var title = ""

        if options.contains(.displayUserName) {
            title = userStatus.displayName
            var accessibilityLabel = title
            if userStatus.isE2EICertified {
                trailingIcons += [.e2eiCertifiedShield]
                accessibilityLabel += ", " + L10n.Accessibility.GroupDetails.Conversation.Participants.allYourDevicesHaveValidCertificates
            }
            if userStatus.isProteusVerified {
                trailingIcons += [.proteusVerifiedShield]
                accessibilityLabel += ", " + L10n.Accessibility.GroupDetails.Conversation.Participants.allYourDevicesProteusVerified
            }
            self.accessibilityLabel = accessibilityLabel
        } else if availability == .none && options.contains(.allowSettingStatus) {
            title = L10n.Localizable.Availability.Message.setStatus
            accessibilityLabel = title
        } else if availability != .none {
            title = availability.localizedName
            accessibilityLabel = AvailabilityStatusStrings.description
        }

        let showInteractiveIcon = isInteractive && !options.contains(.hideActionHint)
        configure(
            leadingIcons: leadingIcons.compactMap { $0 },
            title: title,
            trailingIcons: trailingIcons.compactMap { $0 },
            subtitle: nil,
            interactive: isInteractive,
            showInteractiveIcon: showInteractiveIcon
        )

        accessibilityValue = availability != .none ? availability.localizedName : ""
        if options.contains(.allowSettingStatus) {
            accessibilityTraits = .button
            accessibilityHint = AvailabilityStatusStrings.hint
        }
    }

    /// Sets the titleFont and titleColor for the view.
    private func updateAppearance() {
        if options.contains(.useLargeFont) {
            titleFont = .headerSemiboldFont
        } else {
            titleFont = .headerRegularFont
        }

        titleColor = SemanticColors.Label.textDefault
    }
}

extension UserStatusView {

    /// The available options for this view.
    struct Options: OptionSet {
        let rawValue: Int

        /// Whether we allow the user to update the status by tapping this view.
        static let allowSettingStatus = Options(rawValue: 1 << 0)

        /// Whether to hide the action hint (down arrow) next to the status.
        static let hideActionHint = Options(rawValue: 1 << 1)

        /// Whether to display the user name instead of the availability.
        static let displayUserName = Options(rawValue: 1 << 2)

        /// Whether to use a large text font instead of the default small one.
        static let useLargeFont = Options(rawValue: 1 << 3)

        /// The default options for using the view in a title bar.
        static var header: Options = [.allowSettingStatus, .hideActionHint, .displayUserName, .useLargeFont]
    }
}

extension NSTextAttachment {

    fileprivate static var e2eiCertifiedShield: NSTextAttachment {
        let textAttachment = NSTextAttachment(imageResource: .certificateValid)
        if let imageSize = textAttachment.image?.size {
            textAttachment.bounds = .init(origin: .init(x: 0, y: -1.5), size: imageSize)
        }
        return textAttachment
    }

    fileprivate static var proteusVerifiedShield: NSTextAttachment {
        let textAttachment = NSTextAttachment(imageResource: .verifiedShield)
        if let imageSize = textAttachment.image?.size {
            textAttachment.bounds = .init(origin: .init(x: 0, y: -1.5), size: imageSize)
        }
        return textAttachment
    }
}
