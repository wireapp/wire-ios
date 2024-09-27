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

import Down
import UIKit
import WireCommonComponents
import WireDesign

// MARK: - MarkdownBarViewDelegate

protocol MarkdownBarViewDelegate: AnyObject {
    func markdownBarView(_ view: MarkdownBarView, didSelectMarkdown markdown: Markdown, with sender: IconButton)
    func markdownBarView(_ view: MarkdownBarView, didDeselectMarkdown markdown: Markdown, with sender: IconButton)
}

// MARK: - MarkdownBarView

final class MarkdownBarView: UIView {
    // MARK: Lifecycle

    required init() {
        self.buttons = [headerButton, boldButton, italicButton, numberListButton, bulletListButton, codeButton]
        super.init(frame: CGRect.zero)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    weak var delegate: MarkdownBarViewDelegate?

    let headerButton         = PopUpIconButton()
    let boldButton           = IconButton()
    let italicButton         = IconButton()
    let numberListButton     = IconButton()
    let bulletListButton     = IconButton()
    let codeButton           = IconButton()

    let buttons: [IconButton]

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    func setupViews() {
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: buttonMargin, bottom: 0, right: buttonMargin)
        stackView.isLayoutMarginsRelativeArrangement = true

        headerButton.setIcon(.markdownH1, size: .tiny, for: .normal)
        boldButton.setIcon(.markdownBold, size: .tiny, for: .normal)
        italicButton.setIcon(.markdownItalic, size: .tiny, for: .normal)
        numberListButton.setIcon(.markdownNumberList, size: .tiny, for: .normal)
        bulletListButton.setIcon(.markdownBulletList, size: .tiny, for: .normal)
        codeButton.setIcon(.markdownCode, size: .tiny, for: .normal)

        for button in buttons {
            // We apply the corner radius only for the first and the last button
            if button == buttons.first {
                button.layer.cornerRadius = 12
                button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
            }

            if button == buttons.last {
                button.layer.cornerRadius = 12
                button.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            }

            button.contentEdgeInsets = UIEdgeInsets(top: 9, left: 20, bottom: 9, right: 20)
            button.layer.borderWidth = 1
            button.clipsToBounds = true

            button.setIconColor(enabledStateIconColor, for: .normal)
            button.setBorderColor(enabledStateBorderColor, for: .normal)
            button.setBackgroundImageColor(enabledStateBackgroundColor, for: .normal)

            button.setIconColor(highlightedStateIconColor, for: .highlighted)
            button.setBorderColor(highlightedStateBorderColor, for: .highlighted)
            button.setBackgroundImageColor(highlightedStateBackgroundColor, for: .highlighted)

            button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }

        addSubview(stackView)

        let buttonMaxWidth = 100
        let stackViewMaxWidth = CGFloat(buttonMaxWidth * buttons.count)

        let stackViewWidth = stackView.widthAnchor.constraint(lessThanOrEqualToConstant: stackViewMaxWidth)
        stackViewWidth.priority = .defaultHigh

        let stackViewTrailingConstraint = stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        stackViewTrailingConstraint.priority = .defaultLow

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackViewWidth,
            stackViewTrailingConstraint,
        ])

        headerButton.itemIcons = [.markdownH1, .markdownH2, .markdownH3]
        headerButton.delegate = self
        headerButton.setupView()

        setupAccessibility()
    }

    @objc
    func textViewDidChangeActiveMarkdown(note: Notification) {
        guard let textView = note.object as? MarkdownTextView else {
            return
        }
        updateIcons(for: textView.activeMarkdown)
    }

    func updateIcons(for markdown: Markdown) {
        // change header icon if necessary
        if let headerIcon = markdown.headerValue?.headerIcon {
            headerButton.setIcon(headerIcon, size: .tiny, for: .normal)
        }

        for button in buttons {
            guard let buttonMarkdown = self.markdown(for: button) else {
                continue
            }
            let iconColor = markdown.contains(buttonMarkdown) ? highlightedStateIconColor : enabledStateIconColor
            let backgroundColor = markdown
                .contains(buttonMarkdown) ? highlightedStateBackgroundColor : enabledStateBackgroundColor
            let borderColor = markdown.contains(buttonMarkdown) ? highlightedStateBorderColor : enabledStateBorderColor
            button.setIconColor(iconColor, for: .normal)
            button.setBorderColor(borderColor, for: .normal)
            button.setBackgroundImageColor(backgroundColor, for: .normal)
        }
    }

    @objc
    func resetIcons() {
        for button in buttons {
            button.setIconColor(enabledStateIconColor, for: .normal)
            button.setBorderColor(enabledStateBorderColor, for: .normal)
            button.setBackgroundImageColor(enabledStateBackgroundColor, for: .normal)
        }
    }

    func updateAccessibilityElements(isAccessible: Bool) {
        buttons.forEach { $0.isAccessibilityElement = isAccessible }
    }

    // MARK: Fileprivate

    // MARK: - Conversions

    fileprivate func markdown(for button: IconButton) -> Markdown? {
        switch button {
        case headerButton:      headerButton.icon(for: .normal)?.headerMarkdown ?? .h1
        case boldButton:        .bold
        case italicButton:      .italic
        case codeButton:        .code
        case numberListButton:  .oList
        case bulletListButton:  .uList
        default:                nil
        }
    }

    // MARK: Private

    private let stackView = UIStackView()

    private let enabledStateIconColor = SemanticColors.Button.textInputBarItemEnabled
    private let highlightedStateIconColor = SemanticColors.Button.textInputBarItemHighlighted

    private let enabledStateBackgroundColor = SemanticColors.Button.backgroundInputBarItemEnabled
    private let highlightedStateBackgroundColor = SemanticColors.Button.backgroundInputBarItemHighlighted

    private let enabledStateBorderColor = SemanticColors.Button.borderInputBarItemEnabled
    private let highlightedStateBorderColor = SemanticColors.Button.borderInputBarItemHighlighted

    private var buttonMargin: CGFloat {
        conversationHorizontalMargins.left / 2 - StyleKitIcon.Size.tiny.rawValue / 2
    }

    private func setupAccessibility() {
        typealias Conversation = L10n.Accessibility.Conversation

        headerButton.accessibilityLabel = Conversation.HeaderButton.description
        boldButton.accessibilityLabel = Conversation.BoldButton.description
        italicButton.accessibilityLabel = Conversation.ItalicButton.description
        numberListButton.accessibilityLabel = Conversation.NumberListButton.description
        bulletListButton.accessibilityLabel = Conversation.BulletListButton.description
        codeButton.accessibilityLabel = Conversation.CodeButton.description
    }

    // MARK: Actions

    @objc
    private func buttonTapped(sender: IconButton) {
        guard let markdown = markdown(for: sender) else {
            return
        }

        if sender.iconColor(for: .normal) != enabledStateIconColor {
            delegate?.markdownBarView(self, didDeselectMarkdown: markdown, with: sender)
        } else {
            delegate?.markdownBarView(self, didSelectMarkdown: markdown, with: sender)
        }
    }
}

// MARK: PopUpIconButtonDelegate

extension MarkdownBarView: PopUpIconButtonDelegate {
    func popUpIconButton(_ button: PopUpIconButton, didSelectIcon icon: StyleKitIcon) {
        if button === headerButton {
            let markdown = icon.headerMarkdown ?? .h1
            delegate?.markdownBarView(self, didSelectMarkdown: markdown, with: button)
        }
    }
}

extension StyleKitIcon {
    fileprivate var headerMarkdown: Markdown? {
        switch self {
        case .markdownH1: .h1
        case .markdownH2: .h2
        case .markdownH3: .h3
        default:          nil
        }
    }
}

extension Markdown {
    fileprivate var headerIcon: StyleKitIcon? {
        switch self {
        case .h1: .markdownH1
        case .h2: .markdownH2
        case .h3: .markdownH3
        default:  nil
        }
    }
}
