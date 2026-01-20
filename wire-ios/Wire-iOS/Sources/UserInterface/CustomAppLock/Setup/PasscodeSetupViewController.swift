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

import Down
import UIKit
import WireCommonComponents
import WireDesign
import WireLocators

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

    private lazy var presenter: PasscodeSetupPresenter = .init(userInterface: self)

    private let stackView: UIStackView = .verticalStackView()

    private let contentView: UIView = .init()

    private lazy var createButton: LegacyButton = {
        let button = ZMButton(style: .primaryTextButtonStyle, cornerRadius: 16, fontSpec: .mediumSemiboldFont)
        button.accessibilityIdentifier = Locators.SetPasscodePage.createPasscodeButton.rawValue

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
        let label = DynamicFontLabel(
            fontSpec: .normalRegularFont,
            color: ColorTheme.Backgrounds.onSurfaceVariant
        )
        label.textAlignment = .center
        label.configMultipleLineLabel()
        return label
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        return scrollView
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
    ///   - useCompactLayout: Set this to true for reduced font size and spacing for iPhone 4 inch screen. Set to nil to
    /// follow current window's height
    ///   - context: context for this screen. Depending on the context, there is a different title and info message.
    ///   - callback: callback for storing passcode result.
    required init(
        useCompactLayout: Bool? = nil,
        context: Context,
        callback: ResultHandler?
    ) {
        self.callback = callback
        self.context = context

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let windowHeight = appDelegate?.mainWindow?.frame.height ?? UIScreen.main.bounds.height
        self.useCompactLayout = useCompactLayout ?? (windowHeight <= CGFloat.iPhone4Inch.height)

        super.init(nibName: nil, bundle: nil)

        setupViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        passcodeTextField.becomeFirstResponder()
    }

    // MARK: - setup views

    private func setupViews() {
        view.backgroundColor = SemanticColors.View.backgroundDefault

        setupScrollView()
        scrollView.addSubview(contentView)

        stackView.distribution = .fill
        infoLabel.text = context.infoLabelString

        contentView.addSubview(stackView)

        [
            titleLabel,
            SpacingView(useCompactLayout ? 1 : 10),
            infoLabel,
            UILabel.createHintLabel(),
            passcodeTextField,
            SpacingView(useCompactLayout ? 2 : 16)
        ].forEach {
            stackView.addArrangedSubview($0)
        }

        PasscodeError.allCases.forEach {
            if let label = validationLabels[$0] {
                label.font = FontSpec.smallSemiboldFont.font!
                label.textColor = SemanticColors.Label.textPasswordRulesCheck
                label.numberOfLines = 0
                label.attributedText = $0.descriptionWithInvalidIcon
                label.isEnabled = false

                stackView.addArrangedSubview(label)
            }
        }

        stackView.addArrangedSubview(createButton)

        createConstraints()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let frameLayoutGuide = scrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func createConstraints() {

        [contentView, stackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let heightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        let contentLayoutGuide = scrollView.contentLayoutGuide

        let contentPadding: CGFloat = 24

        NSLayoutConstraint.activate([
            // content view
            heightConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 375),
            contentView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentLayoutGuide.leadingAnchor,
                constant: contentPadding
            ),
            contentView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentLayoutGuide.trailingAnchor,
                constant: -contentPadding
            ),
            contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),

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
            createButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
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

    lazy var closeItem: UIBarButtonItem = .closeButton(action: UIAction { [weak self] _ in
        self?.presentingViewController?.dismiss(animated: true)
        self?.appLockSetupViewControllerDismissed()
    }, accessibilityLabel: L10n.Localizable.General.close)

    private func appLockSetupViewControllerDismissed() {
        callback?(false)

        passcodeSetupViewControllerDelegate?.passcodeSetupControllerWasDismissed()
    }
}

// MARK: - UITextFieldDelegate

extension PasscodeSetupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard presenter.isPasscodeValid else {
            return false
        }

        storePasscode()
        return true
    }
}

// MARK: - ValidatedTextFieldDelegate

extension PasscodeSetupViewController: ValidatedTextFieldDelegate {
    func buttonPressed(_ sender: UIButton) {
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

    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
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
