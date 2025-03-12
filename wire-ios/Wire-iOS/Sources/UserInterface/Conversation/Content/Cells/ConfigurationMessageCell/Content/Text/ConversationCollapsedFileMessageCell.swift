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

import WireDesign
import WireSyncEngine

final class ConversationCollapsedFileMessageCell: UIView, ConversationMessageCell {
    
    struct Configuration {
        let message: ZMConversationMessage
        let user: UserType?
        let collapseExpandAction: () -> Void
    }
    
    var isSelected: Bool = false

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?
    
    private lazy var avatar: UserImageView = {
        let view = UserImageView()
        view.userSession = ZMUserSession.shared()
        view.initialsFont = .avatarInitial
        view.size = .badge
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedOnAvatar)))
        view.accessibilityElementsHidden = false
        view.isAccessibilityElement = true
        view.accessibilityTraits = .button
        view.accessibilityLabel = L10n.Accessibility.Conversation.ProfileImage.description
        view.accessibilityHint = L10n.Accessibility.Conversation.ProfileImage.hint
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var titleLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont.italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
        label.textColor = ColorTheme.Backgrounds.onSurfaceVariant
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.isUserInteractionEnabled = false
        return label
    }()
    
    private lazy var typeIcon: UIImageView = {
        let view = UIImageView(image: .init(resource: .file))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.isUserInteractionEnabled = false
        view.tintColor = ColorTheme.Backgrounds.onSurfaceVariant
        return view
    }()
    
    private lazy var collapseButton: UIButton = {
        let button = UIButton()
        let image = UIImage(resource: .collapse)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.tintColor = SemanticColors.Label.baseSecondaryText
        return button
    }()
    
    private lazy var wholeViewTapButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with object: Configuration, animated: Bool) {
        let user = object.user
        avatar.user = user
        titleLabel.text = L10n.Localizable.Content.Collapsed.File.title
        
        wholeViewTapButton.removeTarget(nil, action: nil, for: .allEvents)

        let action = UIAction { _ in
            object.collapseExpandAction()
        }

        wholeViewTapButton.addAction(action, for: .touchUpInside)
    }
    
    private func configureSubviews() {
        
        addSubview(wholeViewTapButton)
        wholeViewTapButton.pin(to: self)
        
        let stack = UIStackView.horizontal(
            views: [
                avatar.wrapInView(leadingInset: 20, bottomInset: -7),
                titleLabel,
                [typeIcon, collapseButton.wrapInView(trailingInset: 16)]
                    .horizontalStack(spacing: 5)],
            spacing: 10,
            alignment: .center)
        
        addSubview(stack)
        
        stack
            .setTranslatesAutoresizingMaskIntoConstraints(false)
            .pin(to: self)
            .heightConstraint(38)
        
        stack.isUserInteractionEnabled = false
        
        typeIcon.constraintToSquare(sideLength: 16)
    }
    
    // MARK: - Tap gesture of avatar

    @objc
    func tappedOnAvatar() {
        guard let user = avatar.user else { return }

        SessionManager.shared?.showUserProfile(user: user)
    }
}

final class ConversationCollapsedFileMessageCellDescription: ConversationMessageCellDescription {
    
    typealias View = ConversationCollapsedFileMessageCell

    let configuration: View.Configuration

    var topMargin: CGFloat = 8
    var showEphemeralTimer: Bool = false

    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = false

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var accessibilityIdentifier: String? {
        "CollapsedFileCell"
    }

    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, collapseExpandAction: @escaping () -> Void) {
        self.configuration = View.Configuration(
            message: message,
            user: message.senderUser,
            collapseExpandAction: collapseExpandAction
        )
    }

}
