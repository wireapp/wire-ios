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
    var conversationMessageCells: [any UIView & ConversationMessageCell] {
        stackView.arrangedSubviews.compactMap { $0 as? any ConversationMessageCell }
    }

    var isSelected = false

    weak var cellDescription: StackViewCellDescription?

    var message: (any ZMConversationMessage)? {
        didSet { conversationMessageCells.forEach { $0.message = message } }
    }

    var delegate: (any ConversationMessageCellDelegate)? {
        didSet { conversationMessageCells.forEach { $0.delegate = delegate } }
    }

    weak var actionController: ConversationMessageActionController? {
        didSet { conversationMessageCells.forEach { $0.actionController = actionController } }
    }

    var menuPresenter: ConversationMessageCellMenuPresenter? {
        conversationMessageCells.compactMap(\.menuPresenter).first
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

        // set ephemeralTimerTopInset
        if
            let index = configuration.firstIndex(where: \.showEphemeralTimer),
            let contentView = stackView.arrangedSubviews[index] as? any ConversationMessageCell {
            ephemeralTimerTopInset = contentView.frame.origin.y + contentView.ephemeralTimerTopInset
        }
    }

    private func setupStackView() {
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.fitIn(view: self)
    }

    // MARK: - ConversationMessageCell

    var selectionView: UIView? {
        fatalError("??") // TODO: fix
        // nil
    }

    var selectionRect: CGRect {
        fatalError("??") // TODO: fix
        // selectionView?.bounds ?? .zero
    }

    private(set) var ephemeralTimerTopInset: CGFloat = 8

    func willDisplay() {
        for cell in conversationMessageCells {
            cell.willDisplay()
        }
    }

    func didEndDisplaying() {
        for cell in conversationMessageCells {
            cell.didEndDisplaying()
        }
    }

    func prepareForReuse() {
        for cell in conversationMessageCells {
            cell.prepareForReuse()
        }
    }

}
