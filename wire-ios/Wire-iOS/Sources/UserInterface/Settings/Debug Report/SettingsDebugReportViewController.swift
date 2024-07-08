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
import MessageUI
import UIKit
import WireDataModel
import WireDesign

class SettingsDebugReportViewController: UIViewController {

    // MARK: - Types

    private typealias Strings = L10n.Localizable.Self.Settings

    // MARK: - Properties

    private let viewModel: SettingsDebugReportViewModelProtocol

    // MARK: - Views

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.TechnicalReport.info
        label.textColor = SemanticColors.Label.textDefault
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var sendReportButton: UIButton = {
        return createButton(
            title: Strings.TechnicalReport.sendReport.capitalized,
            action: #selector(didTapSendReport)
        )
    }()

    private lazy var shareReportButton: UIButton = {
        return createButton(
            title: Strings.TechnicalReport.shareReport.capitalized,
            action: #selector(didTapShareReport)
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
        navigationItem.setDynamicFontLabel(title: Strings.TechnicalReportSection.title.capitalized)

        setupViews()
        setupConstraints()
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(infoLabel)
        view.addSubview(sendReportButton)
        view.addSubview(shareReportButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            shareReportButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -30),
            shareReportButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            shareReportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            shareReportButton.heightAnchor.constraint(equalToConstant: 48),

            sendReportButton.bottomAnchor.constraint(equalTo: shareReportButton.topAnchor, constant: -8),
            sendReportButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sendReportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sendReportButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    // MARK: - Actions

    @objc private func didTapSendReport() {
        viewModel.sendReport()
    }

    @objc private func didTapShareReport() {
        viewModel.shareReport()
    }

    // MARK: - Helpers

    private func createButton(title: String, action: Selector) -> UIButton {
        let button = ZMButton(
            style: .secondaryTextButtonStyle,
            cornerRadius: 16,
            fontSpec: .buttonBigSemibold
        )
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
