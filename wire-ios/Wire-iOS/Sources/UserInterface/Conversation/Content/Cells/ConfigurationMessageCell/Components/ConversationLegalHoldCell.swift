//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireDataModel
import WireCommonComponents

final class ConversationLegalHoldSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    static let legalHoldURL: URL = .wr_legalHoldLearnMore
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

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(systemMessageType: ZMSystemMessageType, conversation: ZMConversation) {
        configuration = ConversationLegalHoldCellDescription.configuration(for: systemMessageType, in: conversation)
        accessibilityLabel = configuration.attributedText?.string
    }

    private static func configuration(for systemMessageType: ZMSystemMessageType, in conversation: ZMConversation) -> View.Configuration {
        let systemMessageTitle = title(for: systemMessageType)
        let attributedText = NSAttributedString.markdown(from: systemMessageTitle, style: .systemMessage)

        let icon = StyleKitIcon.legalholdactive.makeImage(size: .tiny, color: SemanticColors.Icon.foregroundDefaultRed)

        return View.Configuration(attributedText: attributedText, icon: icon, conversation: conversation)
    }

    private static func title(for messageType: ZMSystemMessageType) -> String {
        switch messageType {
        case .legalHoldEnabled:
            return L10n.Localizable.Content.System.MessageLegalHold.enabled(ConversationLegalHoldSystemMessageCell.legalHoldURL.absoluteString)
        case .legalHoldDisabled:
            return L10n.Localizable.Content.System.MessageLegalHold.disabled
        default:
            return ""
        }
    }

}

extension ConversationLegalHoldSystemMessageCell {

    public override func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        if url == ConversationLegalHoldSystemMessageCell.legalHoldURL,
            let conversation = conversation,
            let clientViewController = ZClientViewController.shared {

            LegalHoldDetailsViewController.present(in: clientViewController, conversation: conversation, userSession: clientViewController.userSession)

            return true
        }

        return false
    }

}
