// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

protocol WipeDatabaseUserInterface: AnyObject {
    func presentConfirmAlert()
}

extension WipeDatabaseViewController: WipeDatabaseUserInterface {
    func presentConfirmAlert() {
        let confirmController = RequestPasswordController(context: .wiping,
                                                          callback: presenter?.confirmAlertCallback() ?? { _ in },
                                                          inputValidation: presenter?.confirmAlertInputValidation())

        self.confirmController = confirmController
        present(confirmController.alertController, animated: true)
    }

}

final class WipeDatabaseViewController: UIViewController {

    var presenter: WipeDatabasePresenter!

    var confirmController: RequestPasswordController?

    private let stackView: UIStackView = UIStackView.verticalStackView()

    typealias WipeDatabase = L10n.Localizable.WipeDatabase

    private let titleLabel: UILabel = {
        let label = UILabel.createMultiLineCenterdLabel()
        label.text = L10n.Localizable.WipeDatabase.titleLabel

        return label
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.configMultipleLineLabel()

        let textColor = SemanticColors.Label.textDefault

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor]

        let headingText = NSAttributedString(string: WipeDatabase.infoLabel) &&
                                UIFont.normalRegularFont &&
                                baseAttributes
        let highlightText = NSAttributedString(string: WipeDatabase.InfoLabel.highlighted) &&
                                FontSpec.normalBoldFont.font! &&
                                baseAttributes

        label.text = " "
        label.attributedText = headingText + highlightText

        return label
    }()

    private lazy var confirmButton = {
        let button = ZMButton(style: .primaryTextButtonStyle, cornerRadius: 16, fontSpec: .mediumSemiboldFont)
        button.setTitle(WipeDatabase.Button.title, for: .normal)
        button.addTarget(self, action: #selector(onConfirmButtonPressed(sender:)), for: .touchUpInside)
        return button
    }()

    @objc
    private func onConfirmButtonPressed(sender: LegacyButton?) {
        presentConfirmAlert()
    }

    convenience init() {
        self.init(nibName: nil, bundle: nil)

        view.backgroundColor = SemanticColors.View.backgroundDefault

        [
            stackView,
            confirmButton
        ].forEach {
            view.addSubview($0)
        }

        stackView.distribution = .fillProportionally

        [
            titleLabel,
            SpacingView(25),
            infoLabel
        ].forEach {
            stackView.addArrangedSubview($0)
        }

        createConstraints()
    }

    private func createConstraints() {

        [stackView, confirmButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let widthConstraint = stackView.widthAnchor.constraint(equalToConstant: CGFloat.iPhone4_7Inch.width)
        widthConstraint.priority = .defaultHigh

        let stackViewPadding: CGFloat = 46

        NSLayoutConstraint.activate([
            // content view
            widthConstraint,
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: CGFloat.iPhone4_7Inch.width),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: stackViewPadding),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -stackViewPadding),

            // confirmButton
            confirmButton.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.buttonHeight),
            confirmButton.topAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor, constant: CGFloat.PasscodeUnlock.buttonPadding),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -CGFloat.PasscodeUnlock.buttonPadding),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: CGFloat.PasscodeUnlock.buttonPadding),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -CGFloat.PasscodeUnlock.buttonPadding)])
    }

}
