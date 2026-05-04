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

final class ConversationNewDeviceSystemMessageCell<
    CellDescription: ConversationMessageCellDescription
>: ConversationIconBasedCell<CellDescription>, ConversationMessageCell {

    static var userClientURL: URL {
        URL(string: "settings://user-client")!
    }

    var linkTarget: LinkTarget?

    enum LinkTarget {
        case user(_ id: Any, (_ id: Any) -> Void)
        case conversation(_ id: Any, (_ id: Any) -> Void)
    }

    struct Configuration {
        let attributedText: NSAttributedString?
        var icon: UIImage?
        var linkTarget: LinkTarget
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
        lineView.isHidden = false
    }

    func configure(with object: Configuration, animated: Bool) {
        attributedText = object.attributedText
        imageView.image = object.icon
        linkTarget = object.linkTarget
    }

    // MARK: - UITextViewDelegate

    override func textView(
        _ textView: UITextView,
        shouldInteractWith url: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {

        guard let linkTarget else { return false }

        switch linkTarget {
        case let .user(user, onUserTapped):
            onUserTapped(user)
        case let .conversation(conversation, onConversationTapped):
            onConversationTapped(conversation)
        }

        return false
    }

}
