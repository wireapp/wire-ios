//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireCommonComponents
import WireDataModel

final class  ConversationDomainsStoppedFederatingSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {

    static let federationLearnMoreURL: URL = URL.wr_FederationLearnMore
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
        textLabel.linkTextAttributes = [.font: UIFont.mediumFont,
                                        .foregroundColor: SemanticColors.Label.textDefault,
                                        .underlineStyle: NSUnderlineStyle.single.rawValue,
                                        .underlineColor: SemanticColors.Label.textDefault]
    }

    func configure(with object: Configuration, animated: Bool) {
        attributedText = object.attributedText
        imageView.image = object.icon
        conversation = object.conversation
    }

}
extension ConversationDomainsStoppedFederatingSystemMessageCell {

    public override func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        return url == ConversationDomainsStoppedFederatingSystemMessageCell.federationLearnMoreURL
    }

}
