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

import MessageUI
import UIKit
import WireDataModel
import WireDesign

class SettingsDebugReportViewController: UIViewController {

    // MARK: - Constants

    private enum LayoutConstants {
        static let spacing: CGFloat = 8
        static let padding: CGFloat = 20
        static let safeBottomPadding: CGFloat = 30
        static let buttonHeight: CGFloat = 48
    }

    // MARK: - Types

    private typealias Strings = L10n.Localizable.Self.Settings

    // MARK: - Properties

    private let viewModel: SettingsDebugReportViewModelProtocol

    // MARK: - Views

    private lazy var infoLabel: UILabel = {
        let label = DynamicFontLabel(
            text: Strings.TechnicalReport.info,
            style: .body1,
            color: SemanticColors.Label.textDefault
        )
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var sendReportButton = createButton(
        title: Strings.TechnicalReport.sendReport.capitalized,
        action: UIAction { [weak self] action in
            self?.didTapSendReport(sender: action.sender as! UIButton)
        }
    )

    private lazy var shareReportButton: UIButton = {
        return createButton(
            title: Strings.TechnicalReport.shareReport.capitalized,
            action: UIAction { [weak self] _ in self?.didTapShareReport() }
        )
    }()

    // MARK: - Life cycle

    init(viewModel: SettingsDebugReportViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault

        setupViews()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTitle(Strings.TechnicalReportSection.title.capitalized)
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(infoLabel)
        view.addSubview(sendReportButton)
        view.addSubview(shareReportButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: LayoutConstants.padding),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: LayoutConstants.padding),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -LayoutConstants.padding),

            shareReportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -LayoutConstants.safeBottomPadding),
            shareReportButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: LayoutConstants.padding),
            shareReportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -LayoutConstants.padding),
            shareReportButton.heightAnchor.constraint(greaterThanOrEqualToConstant: LayoutConstants.buttonHeight),

            sendReportButton.bottomAnchor.constraint(equalTo: shareReportButton.topAnchor, constant: -LayoutConstants.spacing),
            sendReportButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: LayoutConstants.padding),
            sendReportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -LayoutConstants.padding),
            sendReportButton.heightAnchor.constraint(greaterThanOrEqualToConstant: LayoutConstants.buttonHeight)
        ])
    }

    // MARK: - Actions

    @objc private func didTapSendReport(sender: UIView) {
        viewModel.sendReport(sender: sender)
    }

    @objc private func didTapShareReport() {
        Task { await viewModel.shareReport() }
    }

    // MARK: - Helpers

    private func createButton(title: String, action: UIAction) -> UIButton {
        let button = ZMButton(
            style: .secondaryTextButtonStyle,
            cornerRadius: 16,
            fontSpec: .buttonBigSemibold
        )
        button.setTitle(title, for: .normal)
        button.addAction(action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
