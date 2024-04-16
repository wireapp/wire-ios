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
import Down

final class MessageSendFailureView: UIView {

    // MARK: - Properties
    override var isHidden: Bool {
        didSet {
            titleLabel.isHidden = isHidden
            retryButton.isHidden = isHidden
        }
    }

    var tapHandler: ((UIButton) -> Void)?

    private let stackView = UIStackView(axis: .vertical)
    private let titleLabel = WebLinkTextView()
    private let retryButton = InviteButton(fontSpec: FontSpec.buttonSmallSemibold,
                                           insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

    // MARK: - initialization
    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)

        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI
    func setTitle(_ errorMessage: String) {
        titleLabel.attributedText = .markdown(from: errorMessage, style: .errorLabelStyle)
    }

    private func setupViews() {
        addSubview(stackView)

        stackView.alignment = .leading
        stackView.spacing = 15
        [titleLabel, retryButton].forEach(stackView.addArrangedSubview)
        retryButton.setTitle(L10n.Localizable.Content.System.FailedtosendMessage.retry, for: .normal)
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)

        setupConstraints()
        setupAccessibility()
    }

    private func setupAccessibility() {
        titleLabel.accessibilityIdentifier = "failedToSend.label"
        retryButton.accessibilityIdentifier = "retry.button"
    }

    private func setupConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Methods
    @objc
    func retryButtonTapped(_ sender: UIButton) {
        tapHandler?(sender)
    }

}

// MARK: - DownStyle extension
    public extension DownStyle {

    static var errorLabelStyle: DownStyle {
        let style = DownStyle()
        style.baseFont = FontSpec.mediumRegularFont.font!
        style.baseFontColor = SemanticColors.Label.textErrorDefault
        style.baseParagraphStyle = NSParagraphStyle.default

        return style
    }

}
