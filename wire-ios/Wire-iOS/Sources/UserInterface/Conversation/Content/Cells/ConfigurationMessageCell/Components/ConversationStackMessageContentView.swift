//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class ConversationStackMessageContentView: UIView, ConversationMessageCell {
    typealias Configuration = [AnyConversationMessageCellDescription]

    private let stackView = UIStackView()

    var isSelected = false

    var message: (any ZMConversationMessage)? {
        didSet {
            for cell in stackView.arrangedSubviews.compactMap({ $0 as? any ConversationMessageCell }) {
                cell.message = message
            }
        }
    }

    var delegate: (any ConversationMessageCellDelegate)? {
        didSet {
            for cell in stackView.arrangedSubviews.compactMap({ $0 as? any ConversationMessageCell }) {
                cell.delegate = delegate
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(with configuration: Configuration, animated: Bool) {
        stackView.arrangedSubviews.forEach { arrangedSubview in
            arrangedSubview.removeFromSuperview()
        }
        for cellDescription in configuration {
            let contentView = cellDescription.makeView(frame: .zero)
            cellDescription.configureContentView(contentView)
            let lastArrangedSubview = stackView.arrangedSubviews.last
            stackView.addArrangedSubview(contentView)
            if let lastArrangedSubview {
                stackView.setCustomSpacing(cellDescription.topMargin, after: lastArrangedSubview)
            }
        }
        UIView.performWithoutAnimation {
            stackView.setNeedsLayout()
            stackView.layoutIfNeeded()
        }
    }

    private func setupStackView() {
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.fitIn(view: self)
    }

}
