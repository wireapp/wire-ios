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

// MARK: - ConversationTitleView

final class ConversationTitleView: TitleView {
    var conversation: GroupDetailsConversationType
    var interactive = true

    init(conversation: GroupDetailsConversationType, interactive: Bool = true) {
        self.conversation = conversation
        self.interactive = interactive
        super.init()
        configure()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        titleColor = SemanticColors.Label.textDefault
        titleFont = .normalSemiboldFont

        var leadingIcons: [NSTextAttachment] = []
        var trailingIcons: [NSTextAttachment] = []

        if conversation.isUnderLegalHold {
            leadingIcons.append(.legalHold())
        }

        if conversation.isVerified {
            trailingIcons.append(verifiedShield)
        }

        var subtitle: String?
        if conversation.conversationType == .oneOnOne,
           let user = conversation.connectedUserType,
           user.isFederated {
            subtitle = user.handleDisplayString(withDomain: true)
        }

        super.configure(
            leadingIcons: leadingIcons,
            title: conversation.displayNameWithFallback,
            trailingIcons: trailingIcons,
            subtitle: subtitle,
            interactive: interactive && conversation.relatedConnectionState != .sent,
            showInteractiveIcon: true
        )

        setupAccessibility()
    }

    private var verifiedShield: NSTextAttachment {
        switch conversation.messageProtocol {
        case .proteus, .mixed:
            .proteusVerifiedShield()
        case .mls:
            .e2eiVerifiedShield()
        }
    }

    private func setupAccessibility() {
        typealias Conversation = L10n.Accessibility.Conversation

        var components: [String] = []
        components.append(conversation.displayNameWithFallback)

        if conversation.isVerified {
            components.append(Conversation.VerifiedIcon.description)
        }

        if conversation.isUnderLegalHold {
            components.append(Conversation.LegalHoldIcon.description)
        }

        if !UIApplication.isLeftToRightLayout {
            components.reverse()
        }

        accessibilityLabel = components.joined(separator: ", ")

        guard interactive else {
            accessibilityTraits = .header
            return
        }

        accessibilityTraits = .button
        accessibilityHint = conversation.conversationType == .oneOnOne
            ? Conversation.TitleViewForOneToOne.hint
            : Conversation.TitleViewForGroup.hint
    }
}

extension NSTextAttachment {
    fileprivate static func proteusVerifiedShield() -> NSTextAttachment {
        let attachment = NSTextAttachment()
        let shield = UIImage(resource: .verifiedShield)
        attachment.image = shield
        let ratio = shield.size.width / shield.size.height
        let height: CGFloat = 12
        attachment.bounds = CGRect(x: 0, y: 0, width: height * ratio, height: height)
        return attachment
    }

    fileprivate static func e2eiVerifiedShield() -> NSTextAttachment {
        let attachment = NSTextAttachment()
        let shield = UIImage(resource: .certificateValid)
        attachment.image = shield
        attachment.bounds = CGRect(x: 0, y: -2, width: shield.size.width, height: shield.size.height)
        return attachment
    }

    fileprivate static func legalHold() -> NSTextAttachment {
        let attachment = NSTextAttachment()
        let legalHold = StyleKitIcon.legalholdactive.makeImage(
            size: .tiny,
            color: SemanticColors.Icon.foregroundDefaultRed
        )
        attachment.image = legalHold
        let ratio = legalHold.size.width / legalHold.size.height
        let height: CGFloat = 12
        attachment.bounds = CGRect(x: 0, y: -2, width: height * ratio, height: height)
        return attachment
    }
}

extension ConversationLike {
    var displayNameWithFallback: String {
        displayName ?? L10n.Localizable.Profile.Details.Title.unavailable
    }
}
