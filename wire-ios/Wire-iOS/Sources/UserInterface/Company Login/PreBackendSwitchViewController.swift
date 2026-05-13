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

protocol PreBackendSwitchViewControllerDelegate: AnyObject {
    func preBackendSwitchViewControllerDidComplete(_ url: URL)
}

final class PreBackendSwitchViewController: AuthenticationStepViewController {

    var authenticationCoordinator: AuthenticationCoordinator?
    var backendURL: URL? {
        didSet {
            updateViewModel()
        }
    }

    private lazy var viewModel = makeViewModel()

    var delegate: PreBackendSwitchViewControllerDelegate? {
        authenticationCoordinator
    }

    // MARK: - UI Styles

    static let informationBlue = UIColor(red: 35 / 255, green: 145 / 255, blue: 211 / 255, alpha: 1)

    // MARK: - UI Elements

    private lazy var wireLogoInfoView = WireLogoInfoView(
        title: viewModel.state.title,
        subtitle: viewModel.state.subtitle
    )

    let progressView: TimedCircularProgressView = {
        let progress = TimedCircularProgressView()
        progress.lineWidth = 4
        progress.lineCap = .round
        progress.tintColor = PreBackendSwitchViewController.informationBlue
        progress.accessibilityIdentifier = "ProgressView.Timer"
        return progress
    }()

    private lazy var informationLabel: UILabel = {
        let label = DynamicFontLabel(
            text: viewModel.state.information,
            fontSpec: .normalSemiboldFont,
            color: SemanticColors.Label.textDefault
        )
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityValue = label.text
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SemanticColors.View.backgroundDefault
        navigationController?.navigationBar.barStyle = .black

        apply(state: viewModel.state)
        configureSubviews()
        createConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        progressView.animate { [viewModel] in
            let route = viewModel.handleAction(.timerCompleted)
            viewModel.complete(route: route)
        }
    }

    private func makeViewModel() -> PreBackendSwitchViewModel {
        PreBackendSwitchViewModel(backendURL: backendURL) { [weak self] url in
            self?.delegate?.preBackendSwitchViewControllerDidComplete(url)
        }
    }

    private func updateViewModel() {
        viewModel = makeViewModel()

        if isViewLoaded {
            apply(state: viewModel.state)
        }
    }

    private func apply(state: PreBackendSwitchViewModel.State) {
        wireLogoInfoView.titleLabel.text = state.title
        wireLogoInfoView.titleLabel.accessibilityValue = state.title
        wireLogoInfoView.subtitleLabel.text = state.subtitle
        wireLogoInfoView.subtitleLabel.accessibilityValue = state.subtitle
        informationLabel.text = state.information
        informationLabel.accessibilityValue = state.information
        progressView.duration = state.progressDuration
    }

    private func configureSubviews() {
        view.addSubview(wireLogoInfoView)

        wireLogoInfoView.contentView.addSubview(informationLabel)

        wireLogoInfoView.progressContainerView.addSubview(progressView)
    }

    private func createConstraints() {
        [
            wireLogoInfoView,
            progressView,
            informationLabel
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            wireLogoInfoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wireLogoInfoView.topAnchor.constraint(equalTo: view.topAnchor),
            wireLogoInfoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wireLogoInfoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // progress view
            progressView.centerXAnchor.constraint(equalTo: wireLogoInfoView.progressContainerView.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: wireLogoInfoView.progressContainerView.centerYAnchor),
            progressView.widthAnchor.constraint(equalTo: wireLogoInfoView.progressContainerView.widthAnchor),
            progressView.heightAnchor.constraint(equalTo: wireLogoInfoView.progressContainerView.heightAnchor),

            // information label
            informationLabel.topAnchor.constraint(equalTo: wireLogoInfoView.subtitleLabel.bottomAnchor, constant: 10),
            informationLabel.leadingAnchor.constraint(equalTo: wireLogoInfoView.contentView.leadingAnchor),
            informationLabel.trailingAnchor.constraint(equalTo: wireLogoInfoView.contentView.trailingAnchor)
        ])
    }

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        // NO OP
    }

    func displayError(_ error: Error) {
        // NO OP
    }

    func didRewindToThisView() {
        // no-op
    }
}
