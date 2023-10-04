//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

class CreatePasswordSecuredLinkViewController: UIViewController, CreatePasswordSecuredLinkViewModelDelegate {

    // MARK: - Properties

    typealias ViewColors = SemanticColors.View
    typealias LabelColors = SemanticColors.Label
    typealias SecuredGuestLinkWithPasswordLocale = L10n.Localizable.SecuredGuestLinkWithPassword

    private let generatePasswordButton = SecondaryTextButton(fontSpec: FontSpec.buttonSmallSemibold,
                                                             insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

    private var viewModel = CreatePasswordSecuredLinkViewModel()

    private let warningLabel: DynamicFontLabel = {

        var paragraphStyle = NSMutableParagraphStyle()
        var label = DynamicFontLabel(fontSpec: .mediumFont, color: LabelColors.textDefault)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        paragraphStyle.lineHeightMultiple = 0.98
        label.attributedText = NSMutableAttributedString(
            string: SecuredGuestLinkWithPasswordLocale.WarningLabel.title,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]).semiBold(
                SecuredGuestLinkWithPasswordLocale.WarningLabel.subtitle,
                fontspec: .mediumSemiboldFont
            )

        return label
    }()

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.delegate = self
        setUpViews()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    // MARK: - Setup UI

    private func setUpViews() {
        setupGeneratePasswordButton()
        view.addSubview(warningLabel)
        view.addSubview(generatePasswordButton)
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.backgroundColor = ViewColors.backgroundDefault
        navigationController?.navigationBar.tintColor = LabelColors.textDefault
        navigationItem.setupNavigationBarTitle(title: SecuredGuestLinkWithPasswordLocale.Header.title)
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
    }

    private func setupGeneratePasswordButton() {
        generatePasswordButton.setTitle(SecuredGuestLinkWithPasswordLocale.GeneratePasswordButton.title, for: .normal)
        generatePasswordButton.setImage(Asset.Images.shield.image, for: .normal)
        generatePasswordButton.addTarget(self, action: #selector(generatePasswordButtonTapped), for: .touchUpInside)
        generatePasswordButton.imageEdgeInsets.right = 10.0
    }

    private func setupConstraints() {
        [generatePasswordButton, warningLabel].prepareForLayout()

        NSLayoutConstraint.activate([
            warningLabel.safeLeadingAnchor.constraint(equalTo: self.view.safeLeadingAnchor, constant: 20),
            warningLabel.safeTrailingAnchor.constraint(equalTo: self.view.safeTrailingAnchor, constant: -20),
            warningLabel.safeTopAnchor.constraint(equalTo: self.view.safeTopAnchor, constant: 30),

            generatePasswordButton.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 40),
            generatePasswordButton.safeLeadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            // This is a temporary constraint for the height.
            // It will change as soon as we add more elements to the View Controller
            generatePasswordButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    // MARK: - Button Actions

    @objc
    func generatePasswordButtonTapped() {
        viewModel.requestRandomPassword()
    }

    // MARK: - CreatePasswordSecuredLinkViewModelDelegate

    func generateButtonDidTap(_ password: String) {
        print("Generated Password: \(password)")
    }

}
