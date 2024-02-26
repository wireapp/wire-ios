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

import Foundation
import WireSyncEngine
import SwiftUI

final class SuccessfulCertificateEnrollmentViewController: AuthenticationStepViewController {
    var certificateDetails: String = ""
    // MARK: - Properties

    public var onOkTapped: ((_ viewController: SuccessfulCertificateEnrollmentViewController) -> Void)?

    private let titleLabel: UILabel = {
        let label = DynamicFontLabel(
            text: L10n.Localizable.EnrollE2eiCertificate.title,
            style: .bigHeadline,
            color: SemanticColors.Label.textDefault)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityIdentifier = "titleLabel"

        return label
    }()

    private let detailsLabel: UILabel = {
        let label = DynamicFontLabel(
            text: L10n.Localizable.EnrollE2eiCertificate.subtitle,
            style: .body,
            color: SemanticColors.Label.textDefault)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.accessibilityIdentifier = "detailsLabel"

        return label
    }()

    private let shieldImageView: UIImageView = {
        let guestUserIconColor = SemanticColors.Icon.foregroundDefault
        let imageView = UIImageView(image: Asset.Images.certificateValid.image)
        imageView.accessibilityIdentifier = "shieldImageView"
        imageView.isAccessibilityElement = false
        imageView.contentMode = .scaleAspectFit

        return imageView
    }()

    private lazy var certificateDetailsButton: Button = {
        let button = Button(
            style: .secondaryTextButtonStyle,
            cornerRadius: 12,
            fontSpec: .buttonSmallBold)

        button.accessibilityIdentifier = "certificateDetailsButton"
        button.setTitle(L10n.Localizable.EnrollE2eiCertificate.certificateDetailsButton, for: .normal)
        button.addTarget(
            self,
            action: #selector(certificateDetailsTapped),
            for: .touchUpInside)

        return button
    }()

    private lazy var confirmationButton: Button = {
        let button = Button(
            style: .primaryTextButtonStyle,
            cornerRadius: 16,
            fontSpec: .buttonBigSemibold)

        button.accessibilityIdentifier = "confirmationButton"
        button.setTitle(L10n.Localizable.EnrollE2eiCertificate.okButton, for: .normal)
        button.addTarget(
            self,
            action: #selector(okTapped),
            for: .touchUpInside)

        return button
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 30
        stack.alignment = .fill
        stack.isAccessibilityElement = false

        return stack
    }()

    // MARK: - Life cycle

    init() {
        super.init(nibName: nil, bundle: nil)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    // MARK: - Helpers

    private func setupViews() {
        [stackView,
         certificateDetailsButton
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        [titleLabel,
         shieldImageView,
         detailsLabel,
         confirmationButton
        ].forEach {
            stackView.addArrangedSubview($0)
        }

        createConstraints()
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            // title Label
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            // shield image view
            shieldImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shieldImageView.heightAnchor.constraint(equalToConstant: 64),
            shieldImageView.widthAnchor.constraint(equalToConstant: 64),

            // confirmation button
            confirmationButton.heightAnchor.constraint(equalToConstant: 56),

            // stackView
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // certificate details button
            certificateDetailsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            certificateDetailsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            certificateDetailsButton.heightAnchor.constraint(equalToConstant: 32),
            certificateDetailsButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -64)
        ])
    }

    // MARK: - Actions

    @objc
    private func certificateDetailsTapped() {
        let wrapNavigationController = UINavigationController()
        let saveFileManger = SaveFileManager(systemFileSavePresenter: SystemSavePresenter())
        var detailsView = E2EIdentityCertificateDetailsView(
            certificateDetails: certificateDetails,
            isDownloadAndCopyEnabled: Settings.isClipboardEnabled,
            isMenuPresented: false) {
            saveFileManger.save(value: self.certificateDetails, fileName: "certificate-chain", type: "txt")
        } performCopy: { value in
            UIPasteboard.general.string = value
        }
        detailsView.didDismiss = {
            wrapNavigationController.dismiss(animated: true)
        }
        let hostingViewController = UIHostingController(rootView: detailsView)
        wrapNavigationController.viewControllers = [hostingViewController]
        wrapNavigationController.isNavigationBarHidden = true
        wrapNavigationController.presentTopmost()
    }

    @objc
    private func okTapped() {
        onOkTapped?(self)
    }

    // MARK: - AuthenticationStepViewController

    weak var authenticationCoordinator: AuthenticationCoordinator?

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) { }

    func displayError(_ error: Error) { }

}
