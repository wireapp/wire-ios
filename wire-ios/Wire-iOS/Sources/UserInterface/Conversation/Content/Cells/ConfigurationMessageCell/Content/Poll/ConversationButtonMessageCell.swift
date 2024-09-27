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
import WireDataModel

// MARK: - ConversationButtonMessageCell

final class ConversationButtonMessageCell: UIView, ConversationMessageCell {
    var isSelected = false

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?

    var errorMessage: String? {
        didSet {
            errorLabelTopConstraint?.constant = errorMessage?.isEmpty == false ? 4 : 0
            errorLabel.text = errorMessage
            errorLabel.invalidateIntrinsicContentSize()

            layoutIfNeeded()
        }
    }

    private let button = SpinnerButton.alarmButton()
    private var buttonAction: Completion?

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .smallLightFont
        label.textColor = UIColor.AlarmButton.alarmRed

        return label
    }()

    private var errorLabelTopConstraint: NSLayoutConstraint?

    private var config: Configuration? {
        didSet {
            buttonAction = config?.buttonAction

            guard config != oldValue else {
                return
            }

            updateUI()
        }
    }

    private func updateUI() {
        guard let config else {
            return
        }

        button.setTitle(config.text, for: .normal)

        switch config.state {
        case .unselected:
            button.legacyStyle = .empty
            button.isLoading = false
            button.isEnabled = true
            button.accessibilityValue = L10n.Localizable.ButtonMessageCell.State.unselected

        case .selected:
            button.legacyStyle = .empty
            button.isLoading = true
            button.isEnabled = false
            button.accessibilityValue = L10n.Localizable.ButtonMessageCell.State.selected

        case .confirmed:
            button.legacyStyle = .full
            button.isLoading = false
            button.isEnabled = false
            button.accessibilityValue = L10n.Localizable.ButtonMessageCell.State.confirmed
        }

        errorMessage = config.hasError ? L10n.Localizable.ButtonMessageCell.genericError : nil
    }

    func configure(with object: Configuration, animated: Bool) {
        config = object
    }

    struct Configuration {
        let text: String?
        let state: ButtonMessageState
        let buttonAction: Completion
        let hasError: Bool
    }

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)

        configureViews()
        createConstraints()

        button.addTarget(self, action: #selector(buttonTouched(sender:)), for: .touchUpInside)
    }

    @objc
    private func buttonTouched(sender: Any) {
        buttonAction?()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        for item in [button, errorLabel] {
            addSubview(item)
        }
    }

    private func createConstraints() {
        [button, errorLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let errorLabelTopConstraint = errorLabel.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),

            errorLabelTopConstraint,
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        self.errorLabelTopConstraint = errorLabelTopConstraint
    }
}

// MARK: - ConversationButtonMessageCellDescription

final class ConversationButtonMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationButtonMessageCell

    var topMargin = Float.ConversationButtonMessageCell.verticalInset

    var isFullWidth = false

    var supportsActions = false

    var showEphemeralTimer = false

    var containsHighlightableContent = false

    var message: ZMConversationMessage?

    weak var delegate: ConversationMessageCellDelegate?

    var actionController: ConversationMessageActionController?

    var configuration: View.Configuration

    var accessibilityIdentifier: String? = "PollCell"

    var accessibilityLabel: String?

    init(
        text: String?,
        state: ButtonMessageState,
        hasError: Bool,
        buttonAction: @escaping Completion
    ) {
        self.configuration = View.Configuration(
            text: text,
            state: state,
            buttonAction: buttonAction,
            hasError: hasError
        )
    }
}

// MARK: - ConversationButtonMessageCell.Configuration + Hashable

extension ConversationButtonMessageCell.Configuration: Hashable {
    static func == (
        lhs: ConversationButtonMessageCell.Configuration,
        rhs: ConversationButtonMessageCell.Configuration
    ) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(state)
        hasher.combine(hasError)
    }
}
