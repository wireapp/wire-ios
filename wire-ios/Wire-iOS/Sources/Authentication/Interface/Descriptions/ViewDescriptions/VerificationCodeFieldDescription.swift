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

// MARK: - VerificationCodeFieldDescription

final class VerificationCodeFieldDescription: NSObject, ValueSubmission {
    var valueSubmitted: ValueSubmitted?
    var valueValidated: ValueValidated?
    var acceptsInput = true
    var constraints: [NSLayoutConstraint] = []
}

// MARK: - ResponderContainer

private final class ResponderContainer<Child: UIView>: UIView {
    private let responder: Child

    init(responder: Child) {
        self.responder = responder
        super.init(frame: .zero)
        addSubview(self.responder)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        responder.canBecomeFirstResponder
    }

    override func becomeFirstResponder() -> Bool {
        responder.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        responder.resignFirstResponder()
    }
}

// MARK: TextContainer

extension ResponderContainer: TextContainer where Child: TextContainer {
    var text: String? {
        get {
            responder.text
        }
        set {
            responder.text = newValue
        }
    }
}

// MARK: - VerificationCodeFieldDescription + ViewDescriptor

extension VerificationCodeFieldDescription: ViewDescriptor {
    func create() -> UIView {
        // Get the with from window for iPad non full screen modes.
        let window = AppDelegate.shared.mainWindow
        let width = window?.frame.width ?? UIScreen.main.bounds.size.width
        let size = CGSize(width: width, height: AuthenticationStepController.mainViewHeight)

        let inputField = CharacterInputField(maxLength: 6, characterSet: .decimalDigits, size: size)
        inputField.keyboardType = .decimalPad
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.delegate = self
        inputField.accessibilityIdentifier = "VerificationCode"
        inputField.accessibilityLabel = L10n.Localizable.Verification.codeLabel

        inputField.textContentType = .oneTimeCode

        let containerView = ResponderContainer(responder: inputField)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            inputField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            inputField.topAnchor.constraint(equalTo: containerView.topAnchor),
            inputField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            inputField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        return containerView
    }
}

// MARK: - VerificationCodeFieldDescription + CharacterInputFieldDelegate

extension VerificationCodeFieldDescription: CharacterInputFieldDelegate {
    func shouldAcceptChanges(_ inputField: CharacterInputField) -> Bool {
        acceptsInput && inputField.text != nil
    }

    func didChangeText(_ inputField: CharacterInputField, to: String) {
        valueValidated?(.none)
    }

    func didFillInput(inputField: CharacterInputField, text: String) {
        valueSubmitted?(text)
    }
}
