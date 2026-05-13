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
import WireDesign

protocol WipeDatabaseUserInterface: AnyObject {
    func presentConfirmAlert()
}

extension WipeDatabaseViewController: WipeDatabaseUserInterface {
    func presentConfirmAlert() {
        let currentViewModel = viewModel
        let wipeDatabase: RequestPasswordController.Callback = presenter?.confirmAlertCallback() ?? { _ in }
        let callback: RequestPasswordController.Callback = { confirmText in
            switch currentViewModel.route(for: .confirmationSubmitted(confirmText)) {
            case .wipeDatabase:
                wipeDatabase(confirmText)
            case .presentConfirmation, .cancel, .none:
                break
            }
        }

        let confirmController = RequestPasswordController(
            context: .wiping,
            callback: callback,
            inputValidation: { confirmText in
                currentViewModel.confirmationState(for: confirmText).isConfirmEnabled
            }
        )

        self.confirmController = confirmController
        present(confirmController.alertController, animated: true)
    }

}

final class WipeDatabaseViewController: UIViewController {

    private let viewModel: WipeDatabaseViewModel

    var presenter: WipeDatabasePresenter!

    var confirmController: RequestPasswordController?

    private let stackView: UIStackView = .verticalStackView()

    private let titleLabel: UILabel = {
        let label = UILabel.createMultiLineCenterdLabel()

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
            .foregroundColor: textColor
        ]

        label.text = " "
        label.attributedText = NSAttributedString(string: " ") &&
            UIFont.normalRegularFont &&
            baseAttributes

        return label
    }()

    private lazy var confirmButton = {
        let button = ZMButton(style: .primaryTextButtonStyle, cornerRadius: 16, fontSpec: .mediumSemiboldFont)
        button.addTarget(self, action: #selector(onConfirmButtonPressed(sender:)), for: .touchUpInside)
        return button
    }()

    @objc
    private func onConfirmButtonPressed(sender: LegacyButton?) {
        perform(route: viewModel.route(for: .confirmTapped))
    }

    init(viewModel: WipeDatabaseViewModel = WipeDatabaseViewModel()) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = SemanticColors.View.backgroundDefault

        configure(with: viewModel.displayModel)
        configureSubviews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
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
    }

    private func configure(with displayModel: WipeDatabaseViewModel.DisplayModel) {
        titleLabel.text = displayModel.title

        let textColor = SemanticColors.Label.textDefault

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor
        ]

        let headingText = NSAttributedString(string: displayModel.info) &&
            UIFont.normalRegularFont &&
            baseAttributes
        let highlightText = NSAttributedString(string: displayModel.highlightedInfo) &&
            FontSpec.normalBoldFont.font! &&
            baseAttributes

        infoLabel.attributedText = headingText + highlightText

        confirmButton.setTitle(displayModel.confirmButton.title, for: .normal)
        confirmButton.isEnabled = displayModel.confirmButton.isEnabled
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
            confirmButton.topAnchor.constraint(
                greaterThanOrEqualTo: stackView.bottomAnchor,
                constant: CGFloat.PasscodeUnlock.buttonPadding
            ),
            confirmButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -CGFloat.PasscodeUnlock.buttonPadding
            ),
            confirmButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: CGFloat.PasscodeUnlock.buttonPadding
            ),
            confirmButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -CGFloat.PasscodeUnlock.buttonPadding
            )
        ])
    }

    private func perform(route: WipeDatabaseViewModel.Route) {
        switch route {
        case .presentConfirmation:
            presentConfirmAlert()
        case .wipeDatabase:
            break
        case .cancel:
            break
        case .none:
            break
        }
    }

}
