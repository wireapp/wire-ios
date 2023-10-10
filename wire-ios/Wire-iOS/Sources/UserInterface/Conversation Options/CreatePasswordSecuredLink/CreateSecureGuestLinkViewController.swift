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

import Down
import UIKit
import WireCommonComponents

class CreateSecureGuestLinkViewController: UIViewController, CreatePasswordSecuredLinkViewModelDelegate {

    // MARK: - Properties

    typealias ViewColors = SemanticColors.View
    typealias LabelColors = SemanticColors.Label
    typealias SecuredGuestLinkWithPasswordLocale = L10n.Localizable.SecuredGuestLinkWithPassword

    private lazy var generatePasswordButton: SecondaryTextButton = {
        let button = SecondaryTextButton(
            fontSpec: FontSpec.buttonSmallSemibold,
            insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        )

        button.setTitle(SecuredGuestLinkWithPasswordLocale.GeneratePasswordButton.title, for: .normal)
        button.setImage(Asset.Images.shield.image, for: .normal)
        button.addTarget(self, action: #selector(generatePasswordButtonTapped), for: .touchUpInside)
        button.imageEdgeInsets.right = 10.0
        return button
    }()

    private var viewModel: CreateSecureGuestLinkViewModel {
       return CreateSecureGuestLinkViewModel(delegate: self)
    }

    private let warningLabel: UILabel = {
        var paragraphStyle = NSMutableParagraphStyle()
        var label = UILabel()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.attributedText = .markdown(from: SecuredGuestLinkWithPasswordLocale.WarningLabel.title, style: .warningLabelStyle)
        return label
    }()

    // MARK: - Override methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpViews()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    // MARK: - Setup UI

    private func setUpViews() {
        view.addSubview(warningLabel)
        view.addSubview(generatePasswordButton)
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.backgroundColor = ViewColors.backgroundDefault
        navigationController?.navigationBar.tintColor = LabelColors.textDefault
        navigationItem.setupNavigationBarTitle(title: SecuredGuestLinkWithPasswordLocale.Header.title)
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
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

    func viewModel(
        _ viewModel: CreateSecureGuestLinkViewModel,
        didGeneratePassword password: String
    ) {
    }

}

private extension DownStyle {

    static var warningLabelStyle: DownStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        let style = DownStyle()
        style.baseFont = .preferredFont(forTextStyle: .caption1)
        style.baseFontColor = SemanticColors.Label.textDefault
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineHeightMultiple = 0.98
        style.baseParagraphStyle = paragraphStyle
        return style
    }

}
