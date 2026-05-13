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
import WireCommonComponents
import WireDataModel
import WireDesign

final class UnlockViewController: UIViewController {

    typealias Callback = (_ passcode: String?) -> Void

    // MARK: - Properties

    var callback: Callback?

    private let viewModel: UnlockViewModel
    private let contentView: UIView = .init()
    private let stackView: UIStackView = .verticalStackView()

    private lazy var unlockButton: UIButton = {
        var button = UIButton()

        button.setBackgroundImage(UIImage.singlePixelImage(with: .white), for: .normal)
        button.setTitleColor(.graphite, for: .normal)
        button.setTitleColor(.lightGraphite, for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.isEnabled = false

        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true

        button.addTarget(self, action: #selector(onUnlockButtonPressed(sender:)), for: .touchUpInside)
        button.accessibilityIdentifier = "unlock_screen.button.unlock"

        return button
    }()

    private lazy var passcodeTextField: PasscodeTextField = {
        let textField = PasscodeTextField.createPasscodeTextField(delegate: self)
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none

        textField.accessibilityIdentifier = "unlock_screen.text_field.enter_passcode"

        return textField
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()

        label.accessibilityIdentifier = "unlock_screen.title.enter_passcode"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .white

        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    private let hintFont = UIFont.systemFont(ofSize: 10)
    private let hintLabel: UILabel = {
        let label = UILabel()

        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .white

        let leadingMargin: CGFloat = 16
        let style = NSMutableParagraphStyle()
        style.firstLineHeadIndent = leadingMargin
        style.headIndent = leadingMargin

        return label
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = " "
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = SemanticColors.Label.textErrorDefault

        return label
    }()

    // MARK: - Life cycle

    init() {
        self.viewModel = UnlockViewModel()

        super.init(nibName: nil, bundle: nil)

        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupInitialStates()
    }
}

// MARK: - View creation

extension UnlockViewController {

    private func setupViews() {
        view.backgroundColor = .black

        view.addSubview(contentView)

        stackView.distribution = .fill
        contentView.addSubview(stackView)

        [
            titleLabel,
            hintLabel,
            passcodeTextField,
            errorLabel,
            unlockButton
        ].forEach(stackView.addArrangedSubview)

        render(viewModel.displayState)
        createConstraints()
    }

    private func createConstraints() {
        [
            contentView,
            stackView
        ].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        let widthConstraint = contentView.createContentWidthConstraint()

        let contentPadding: CGFloat = 24

        NSLayoutConstraint.activate([
            // content view
            widthConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: CGFloat.iPhone4_7Inch.width),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: contentPadding),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -contentPadding),

            // stack view
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // unlock button
            unlockButton.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.buttonHeight)
        ])
    }

    private func setupInitialStates() {
        viewModel.reset()
        render(viewModel.displayState)
        passcodeTextField.text = ""
        passcodeTextField.becomeFirstResponder()
    }
}

// MARK: - Actions

extension UnlockViewController {

    @objc
    private func onUnlockButtonPressed(sender: AnyObject?) {
        unlock()
    }

    private func unlock() {
        switch viewModel.routeForSubmit() {
        case let .submit(passcode):
            callback?(passcode)
        case .none:
            break
        }
    }

    func showWrongPasscodeMessage() {
        viewModel.showWrongPasscode()

        let textAttachment = NSTextAttachment.textAttachment(
            for: .exclamationMarkCircle,
            with: SemanticColors.Label.textErrorDefault,
            iconSize: StyleKitIcon.Size.CreatePasscode.errorIconSize,
            verticalCorrection: -1,
            insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        )

        let attributedString = NSMutableAttributedString(string: viewModel.displayState.errorMessage ?? "")
        attributedString.addAttributes([.font: hintFont], range: NSRange(location: 0, length: attributedString.length))
        attributedString.insert(.init(attachment: textAttachment), at: 0)
        errorLabel.attributedText = .init(attributedString)
        unlockButton.isEnabled = viewModel.displayState.isSubmitEnabled
    }
}

// MARK: - PasscodeTextFieldDelegate

extension UnlockViewController: PasscodeTextFieldDelegate {

    func textFieldValueChanged(_ value: String?) {
        viewModel.updatePasscode(value)
        render(viewModel.displayState)
    }
}

private extension UnlockViewController {
    func render(_ displayState: UnlockViewModel.DisplayState) {
        titleLabel.text = displayState.title
        passcodeTextField.placeholder = displayState.passcodePlaceholder
        unlockButton.setTitle(displayState.submitButtonTitle, for: .normal)
        unlockButton.isEnabled = displayState.isSubmitEnabled

        let leadingMargin: CGFloat = 16
        let style = NSMutableParagraphStyle()
        style.firstLineHeadIndent = leadingMargin
        style.headIndent = leadingMargin

        hintLabel.attributedText = NSAttributedString(
            string: displayState.hint,
            attributes: [NSAttributedString.Key.paragraphStyle: style]
        )

        if let errorMessage = displayState.errorMessage {
            errorLabel.text = errorMessage
        } else {
            errorLabel.text = " "
        }
    }
}
