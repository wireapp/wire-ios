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

final class ConversationLegalHoldSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {
    static let legalHoldURL: URL = WireURLs.shared.legalHoldInfo
    var conversation: ZMConversation?

    struct Configuration {
        let attributedText: NSAttributedString?
        var icon: UIImage?
        var conversation: ZMConversation?
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    func setupView() {
        lineView.isHidden = true
    }

    func configure(with object: Configuration, animated: Bool) {
        attributedText = object.attributedText
        imageView.image = object.icon
        conversation = object.conversation
    }
}

final class ConversationLegalHoldCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationLegalHoldSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer = false
    var topMargin: Float = 0

    let isFullWidth = true
    let supportsActions = false
    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(systemMessageType: ZMSystemMessageType, conversation: ZMConversation) {
        self.configuration = ConversationLegalHoldCellDescription.configuration(
            for: systemMessageType,
            in: conversation
        )
        self.accessibilityLabel = configuration.attributedText?.string
    }

    private static func configuration(
        for systemMessageType: ZMSystemMessageType,
        in conversation: ZMConversation
    ) -> View.Configuration {
        let systemMessageTitle = title(for: systemMessageType)
        let attributedText = NSAttributedString.markdown(from: systemMessageTitle, style: .systemMessage)

        let icon = StyleKitIcon.legalholdactive.makeImage(size: .tiny, color: SemanticColors.Icon.foregroundDefaultRed)

        return View.Configuration(attributedText: attributedText, icon: icon, conversation: conversation)
    }

    private static func title(for messageType: ZMSystemMessageType) -> String {
        switch messageType {
        case .legalHoldEnabled:
            L10n.Localizable.Content.System.MessageLegalHold
                .enabled(ConversationLegalHoldSystemMessageCell.legalHoldURL.absoluteString)
        case .legalHoldDisabled:
            L10n.Localizable.Content.System.MessageLegalHold.disabled
        default:
            ""
        }
    }
}

extension ConversationLegalHoldSystemMessageCell {
    override func textView(
        _ textView: UITextView,
        shouldInteractWith url: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        if url == ConversationLegalHoldSystemMessageCell.legalHoldURL,
           let conversation,
           let clientViewController = ZClientViewController.shared {
            LegalHoldDetailsViewController.present(
                in: clientViewController,
                conversation: conversation,
                userSession: clientViewController.userSession,
                mainCoordinator: MainCoordinator(zClientViewController: clientViewController)
            )

            return true
        }

        return false
    }
}
