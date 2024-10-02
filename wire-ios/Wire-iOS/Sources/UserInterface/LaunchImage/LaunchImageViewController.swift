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
import WireReusableUIComponents

/// Replicates the launch screen to prevent the black screen being visible, cause of later UI initialization
class LaunchImageViewController: UIViewController {

    private var shouldShowLoadingScreenOnViewDidLoad = false

    private weak var contentView: UIView!
    private let loadingScreenLabel = UILabel()
    private let activityIndicator = ProgressSpinner()

    /// Convenience method for showing the @c activityIndicator and @c loadingScreenLabel and start the spinning animation
    func showLoadingScreen() {
        shouldShowLoadingScreenOnViewDidLoad = true
        loadingScreenLabel.isHidden = false
        activityIndicator.startAnimation()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let contentView: UIView = AppLockView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        self.contentView = contentView

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        loadingScreenLabel.font = .systemFont(ofSize: 12)
        loadingScreenLabel.textColor = .white
        loadingScreenLabel.text = L10n.Localizable.Migration.pleaseWaitMessage.localizedUppercase
        loadingScreenLabel.isHidden = true
        loadingScreenLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingScreenLabel)

        createConstraints()

        // Start the spinner in case of it was requested right after the init
        if shouldShowLoadingScreenOnViewDidLoad {
            showLoadingScreen()
        }
    }

    private func createConstraints() {

        NSLayoutConstraint.activate(
            [
                contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                contentView.topAnchor.constraint(equalTo: view.topAnchor),
                contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

                loadingScreenLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                loadingScreenLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),

                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicator.bottomAnchor.constraint(equalTo: loadingScreenLabel.topAnchor, constant: -24)
            ]
        )
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }
}
