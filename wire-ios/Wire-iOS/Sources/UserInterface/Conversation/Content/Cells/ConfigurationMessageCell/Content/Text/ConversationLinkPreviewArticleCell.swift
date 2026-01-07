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

import UIKit
import WireDataModel
import WireSyncEngine

final class ConversationLinkPreviewArticleCell: UIView, ConversationMessageCell, ContextMenuDelegate {

    struct Configuration: Equatable {
        var textMessageData: TextMessageData
        let showImage: Bool
        var message: ZMConversationMessage
        var isObfuscated: Bool

        static func == (lhs: Configuration, rhs: Configuration) -> Bool {
            lhs.message == rhs.message &&
                lhs.showImage == rhs.showImage &&
                lhs.isObfuscated == rhs.isObfuscated &&
                lhs.textMessageData.messageText == rhs.textMessageData.messageText
        }

    }

    private let articleView = ArticleView(withImagePlaceholder: true)

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    var isSelected: Bool = false

    var selectionView: UIView? {
        articleView
    }

    var configuration: Configuration?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func configureSubviews() {
        articleView.delegate = self
        articleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(articleView)
    }

    private func configureConstraints() {
        articleView.fitIn(view: self, insets: .zero)
    }

    func configure(with object: Configuration, animated: Bool) {
        configuration = object
        articleView.configure(
            withTextMessageData: object.textMessageData,
            obfuscated: object.isObfuscated
        )

        updateImageLayout(isRegular: traitCollection.horizontalSizeClass == .regular)
    }

    func updateImageLayout(isRegular: Bool) {
        if configuration?.showImage == true {
            articleView.imageHeight = isRegular ? 250 : 150
        } else {
            articleView.imageHeight = 0
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateImageLayout(isRegular: traitCollection.horizontalSizeClass == .regular)
    }

}

extension ConversationLinkPreviewArticleCell: LinkViewDelegate {
    var url: URL? {
        configuration?.textMessageData.linkPreview?.openableURL
    }
}

final class ConversationLinkPreviewArticleCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationLinkPreviewArticleCell

    var configuration: View.Configuration

    weak var message: ZMConversationMessage? {
        didSet {
            if let message {
                configuration.message = message
                configuration.textMessageData = message.textMessageData!
            }
        }
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var topMargin: CGFloat = 8
    var bottomMargin: CGFloat = 0

    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true
    let shouldAlignMessageContentForBubbles: Bool = true

    var accessibilityIdentifier: String? {
        configuration.isObfuscated ? "ObfuscatedLinkPreviewCell" : "LinkPreviewCell"
    }

    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: TextMessageData) {
        let showImage = data.linkPreviewHasImage
        self.configuration = View
            .Configuration(
                textMessageData: data,
                showImage: showImage,
                message: message,
                isObfuscated: message.isObfuscated
            )
        self.accessibilityLabel = L10n.Accessibility.ConversationSearch.LinkMessage.description
    }
}
