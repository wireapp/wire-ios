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

protocol PasscodeSetupUserInterface: AnyObject {
    var createButtonEnabled: Bool { get set }
    func setValidationLabelsState(errorReason: PasscodeError, passed: Bool)
}

final class PasscodeSetupViewController: UIViewController {
    enum Context {
        case forcedForTeam
        case createPasscode

        var infoLabelString: String {
            switch self {
            case .createPasscode:
                L10n.Localizable.CreatePasscode.infoLabel

            case .forcedForTeam:
                L10n.Localizable.WarningScreen.MainInfo.forcedApplock + "\n\n" + L10n.Localizable.CreatePasscode
                    .infoLabelForcedApplock
            }
        }
    }

    weak var passcodeSetupViewControllerDelegate: PasscodeSetupViewControllerDelegate?

    private lazy var presenter = PasscodeSetupPresenter(userInterface: self)

    private let stackView = UIStackView.verticalStackView()

    private let contentView = UIView()

    private lazy var createButton: LegacyButton = {
        let button = ZMButton(style: .primaryTextButtonStyle, cornerRadius: 16, fontSpec: .mediumSemiboldFont)
        button.accessibilityIdentifier = "createPasscodeButton"

        button.setTitle(L10n.Localizable.CreatePasscode.CreateButton.title, for: .normal)
        button.isEnabled = false

        button.addTarget(self, action: #selector(onCreateCodeButtonPressed(sender:)), for: .touchUpInside)

        return button
    }()

    lazy var passcodeTextField: ValidatedTextField = {
        let textField = ValidatedTextField.createPasscodeTextField(
            kind: .passcode(.applockPasscode, isNew: true),
            delegate: self,
            setNewColors: true
        )
        textField.placeholder = L10n.Localizable.CreatePasscode.Textfield.placeholder
        textField.delegate = self

        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        return textField
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel.createMultiLineCenterdLabel()
        switch context {
        case .createPasscode:
            label.text = L10n.Localizable.CreatePasscode.titleLabel
        case .forcedForTeam:
            label.text = L10n.Localizable.WarningScreen.titleLabel
        }

        label.accessibilityIdentifier = "createPasscodeTitle"

        return label
    }()

    private let useCompactLayout: Bool

    private lazy var infoLabel: UILabel = {
        let style = DownStyle.infoLabelStyle(compact: useCompactLayout)
        let label = UILabel()
        label.configMultipleLineLabel()
        label.attributedText = .markdown(from: context.infoLabelString, style: style)
        label.textAlignment = .center
        return label
    }()

    private let validationLabels: [PasscodeError: UILabel] = PasscodeError
        .allCases
        .reduce(into: [:]) { partialResult, errorReason in
            partialResult[errorReason] = UILabel()
        }

    private var callback: ResultHandler?
    private let context: Context

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// init with parameters
    /// - Parameters:
    ///   - useCompactLayout: Set this to true for reduce font size and spacing for iPhone 4 inch screen. Set to nil to
    /// follow current window's height
    ///   - context: context  for this screen. Depending on the context, there are a different title and info message.
    ///   - callback: callback for storing passcode result.
    required init(
        useCompactLayout: Bool? = nil,
        context: Context,
        callback: ResultHandler?
    ) {
        self.callback = callback
        self.context = context

        self.useCompactLayout = useCompactLayout ??
            (AppDelegate.shared.mainWindow.frame.height <= CGFloat.iPhone4Inch.height)

        super.init(nibName: nil, bundle: nil)

        setupViews()
    }

    private func setupViews() {
        view.backgroundColor = SemanticColors.View.backgroundDefault

        view.addSubview(contentView)

        stackView.distribution = .fill

        contentView.addSubview(stackView)

        [
            titleLabel,
            SpacingView(useCompactLayout ? 1 : 10),
            infoLabel,
            UILabel.createHintLabel(),
            passcodeTextField,
            SpacingView(useCompactLayout ? 2 : 16),
        ].forEach {
            stackView.addArrangedSubview($0)
        }

        for item in PasscodeError.allCases {
            if let label = validationLabels[item] {
                label.font = FontSpec.smallSemiboldFont.font!
                label.textColor = SemanticColors.Label.textPasswordRulesCheck
                label.numberOfLines = 0
                label.attributedText = item.descriptionWithInvalidIcon
                label.isEnabled = false

                stackView.addArrangedSubview(label)
            }
        }

        stackView.addArrangedSubview(createButton)

        createConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        passcodeTextField.becomeFirstResponder()
    }

    private func createConstraints() {
        [contentView, stackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let widthConstraint = contentView.createContentWidthConstraint()

        let contentPadding: CGFloat = 24

        NSLayoutConstraint.activate([
            // content view
            widthConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 375),
            contentView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: contentPadding),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -contentPadding),

            // stack view
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // passcode text field
            passcodeTextField.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            passcodeTextField.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            // create Button
            createButton.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.buttonHeight),
            createButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            createButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])
    }

    private func storePasscode() {
        guard let passcode = passcodeTextField.text else { return }
        presenter.storePasscode(passcode: passcode, callback: callback)

        passcodeSetupViewControllerDelegate?.passcodeSetupControllerDidFinish()
        dismiss(animated: true)
    }

    @objc
    private func textFieldDidChange(textField: UITextField) {
        passcodeTextField.returnKeyType = presenter.isPasscodeValid ? .done : .default
        passcodeTextField.reloadInputViews()
    }

    @objc
    private func onCreateCodeButtonPressed(sender: AnyObject?) {
        storePasscode()
    }

    // MARK: - keyboard avoiding

    static func createKeyboardAvoidingFullScreenView(
        context: Context,
        delegate: PasscodeSetupViewControllerDelegate? = nil
    )
        -> KeyboardAvoidingAuthenticationCoordinatedViewController {
        let passcodeSetupViewController = PasscodeSetupViewController(
            context: context,
            callback: nil
        )

        passcodeSetupViewController.passcodeSetupViewControllerDelegate = delegate

        let keyboardAvoidingViewController =
            KeyboardAvoidingAuthenticationCoordinatedViewController(viewController: passcodeSetupViewController)

        keyboardAvoidingViewController.modalPresentationStyle = .fullScreen

        return keyboardAvoidingViewController
    }

    // MARK: - close button

    lazy var closeItem: UIBarButtonItem = {
        let closeItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
            self?.appLockSetupViewControllerDismissed()
        }, accessibilityLabel: L10n.Localizable.General.close)

        return closeItem
    }()

    private func appLockSetupViewControllerDismissed() {
        callback?(false)

        passcodeSetupViewControllerDelegate?.passcodeSetupControllerWasDismissed()
    }
}

// MARK: - UITextFieldDelegate

extension PasscodeSetupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        guard presenter.isPasscodeValid else {
            return false
        }

        storePasscode()
        return true
    }
}

// MARK: - ValidatedTextFieldDelegate

extension PasscodeSetupViewController: ValidatedTextFieldDelegate {
    func buttonPressed(_: UIButton) {
        passcodeTextField.isSecureTextEntry = !passcodeTextField.isSecureTextEntry

        passcodeTextField.updatePasscodeIcon()
    }
}

// MARK: - TextFieldValidationDelegate

extension PasscodeSetupViewController: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        presenter.validate(error: error)
    }
}

// MARK: - PasscodeSetupUserInterface

extension PasscodeSetupViewController: PasscodeSetupUserInterface {
    func setValidationLabelsState(errorReason: PasscodeError, passed: Bool) {
        validationLabels[errorReason]?.attributedText = passed ? errorReason.descriptionWithPassedIcon : errorReason
            .descriptionWithInvalidIcon
        validationLabels[errorReason]?.isEnabled = passed
    }

    var createButtonEnabled: Bool {
        get {
            createButton.isEnabled
        }

        set {
            createButton.isEnabled = newValue
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension PasscodeSetupViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_: UIPresentationController) {
        appLockSetupViewControllerDismissed()
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // more space for iPhone 4-inch to prevent keyboard hides the create passcode button
        if view.frame.size.height <= CGFloat.iPhone4Inch.height {
            .fullScreen
        } else {
            .automatic
        }
    }
}

extension DownStyle {
    fileprivate static func infoLabelStyle(compact: Bool) -> DownStyle {
        let style = DownStyle()
        style.baseFont = compact ? FontSpec.smallRegularFont.font! : FontSpec.normalRegularFont.font!
        style.baseFontColor = SemanticColors.Label.textDefault

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = compact ? 14 : 20
        paragraphStyle.maximumLineHeight = compact ? 14 : 20
        paragraphStyle.paragraphSpacing = compact ? 14 : 20
        style.baseParagraphStyle = paragraphStyle

        return style
    }
}
